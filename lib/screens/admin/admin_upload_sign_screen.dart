import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for QuerySnapshot
import '../../services/firestore_service.dart';

class AdminUploadSignScreen extends StatefulWidget {
  const AdminUploadSignScreen({super.key});

  @override
  State<AdminUploadSignScreen> createState() => _AdminUploadSignScreenState();
}

class _AdminUploadSignScreenState extends State<AdminUploadSignScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  final List<Map<String, dynamic>> _selectedFiles = [];
  bool _isUploading = false;

  // CHANGED: No hardcoded list. Just a variable to hold the selected ID.
  String? _selectedCategory; 

  @override
  void dispose() {
    for (var file in _selectedFiles) {
      file['controller'].dispose();
    }
    super.dispose();
  }

  // --- 1. NEW: Logic to Add a Category on the fly ---
  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create New Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "e.g., Sports, Colors, Animals",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                // 1. Add to Firestore
                final newCategoryName = controller.text.trim();
                await _firestoreService.addSignLibraryCategory(newCategoryName);
                
                // 2. Auto-select it in the dropdown
                setState(() {
                  _selectedCategory = newCategoryName;
                });
                
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickJsonFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: true,
    );

    if (result != null) {
      List<Map<String, dynamic>> newFiles = [];

      for (var pickedFile in result.files) {
        try {
          String content;
          if (kIsWeb) {
            final bytes = pickedFile.bytes;
            content = utf8.decode(bytes!);
          } else {
            final file = File(pickedFile.path!);
            content = await file.readAsString();
          }

          final data = json.decode(content);
          String initialWord = data['word'] ?? pickedFile.name.split('.').first;

          newFiles.add({
            'fileName': pickedFile.name,
            'data': data,
            'controller': TextEditingController(text: initialWord),
          });

        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error reading ${pickedFile.name}: $e"))
            );
          }
        }
      }

      setState(() {
        _selectedFiles.addAll(newFiles);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles[index]['controller'].dispose();
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _uploadAll() async {
    // Validation: Must select files AND a category
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select JSON files first."))
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Category."))
      );
      return;
    }

    setState(() => _isUploading = true);

    int successCount = 0;
    List<String> failedFiles = [];

    for (var file in _selectedFiles) {
      String word = file['controller'].text.trim();
      Map<String, dynamic> data = file['data'];

      if (word.isEmpty) {
        failedFiles.add("${file['fileName']} (empty word)");
        continue;
      }

      try {
        await _firestoreService.uploadSign(
          word, 
          _selectedCategory!, // Use the dynamically selected category
          data
        );
        successCount++;
      } catch (e) {
        failedFiles.add(file['fileName']);
        debugPrint("Upload failed for $word: $e");
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
      
      if (failedFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Success! Uploaded $successCount signs to '$_selectedCategory'."))
        );
        Navigator.pop(context); // Go back to Library
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Uploaded $successCount. Failed: ${failedFiles.join(', ')}"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Multiple Signs")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 2. NEW: DYNAMIC CATEGORY SELECTOR ---
            const Text("Select Category:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getSignLibraryCategoriesStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }

                      final docs = snapshot.data!.docs;
                      
                      // Map Firestore docs to DropdownItems
                      List<DropdownMenuItem<String>> items = docs.map((doc) {
                        String name = doc['name'];
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }).toList();

                      // Handle case where previously selected category was deleted
                      if (_selectedCategory != null && !items.any((i) => i.value == _selectedCategory)) {
                        _selectedCategory = null;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            hint: const Text("Choose a category..."),
                            isExpanded: true,
                            items: items,
                            onChanged: (newValue) {
                              setState(() => _selectedCategory = newValue);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Add Category Button
                SizedBox(
                  height: 48,
                  width: 48,
                  child: IconButton.filled(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add),
                    tooltip: "Create new category",
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // File Picker Button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickJsonFiles,
              icon: const Icon(Icons.file_present),
              label: const Text("Select JSON Files"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
            const SizedBox(height: 20),

            // List of Selected Files
            Expanded(
              child: _selectedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.upload_file, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No files selected yet", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (ctx, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return ListTile(
                          leading: const Icon(Icons.description, color: Colors.green),
                          title: TextField(
                            controller: file['controller'],
                            decoration: InputDecoration(
                              labelText: "Word for ${file['fileName']}",
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeFile(index),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isUploading || _selectedFiles.isEmpty || _selectedCategory == null) 
                    ? null 
                    : _uploadAll,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: _isUploading 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 15),
                        Text("Uploading...", style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : Text(
                      _selectedCategory == null 
                          ? "Select Category to Upload" 
                          : "Upload ${_selectedFiles.length} Signs to '$_selectedCategory'", 
                      style: const TextStyle(color: Colors.white, fontSize: 16)
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}