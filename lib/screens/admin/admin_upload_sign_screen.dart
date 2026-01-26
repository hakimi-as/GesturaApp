import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  int _uploadProgress = 0;
  int _uploadTotal = 0;

  String? _selectedCategory; 

  @override
  void dispose() {
    for (var file in _selectedFiles) {
      file['controller'].dispose();
    }
    super.dispose();
  }

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
                final newCategoryName = controller.text.trim();
                await _firestoreService.addSignLibraryCategory(newCategoryName);
                
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
      int skippedCount = 0;

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

          // Calculate size info with compression levels
          final originalSize = content.length;
          final compressionResult = _compressJsonWithInfo(content);
          final compressedContent = compressionResult['compressed'] as String;
          final compressedSize = compressionResult['compressedSize'] as int;
          final compressionLevel = compressionResult['level'] as int;
          final isLarge = compressionResult['isLarge'] as bool;
          final savings = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);

          newFiles.add({
            'fileName': pickedFile.name,
            'data': json.decode(compressedContent), // Use compressed data
            'controller': TextEditingController(text: initialWord),
            'originalSize': originalSize,
            'compressedSize': compressedSize,
            'savings': savings,
            'compressionLevel': compressionLevel,
            'isLarge': isLarge,
          });

        } catch (e) {
          skippedCount++;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error reading ${pickedFile.name}: $e"),
                backgroundColor: Colors.red,
              )
            );
          }
        }
      }

      setState(() {
        _selectedFiles.addAll(newFiles);
      });

      if (mounted && newFiles.isNotEmpty) {
        final totalSaved = newFiles.fold<int>(
          0, 
          (sum, f) => sum + (f['originalSize'] as int) - (f['compressedSize'] as int)
        );
        final savedKB = (totalSaved / 1024).toStringAsFixed(1);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Added ${newFiles.length} files (${savedKB}KB saved via compression)"),
            backgroundColor: Colors.green,
          )
        );
      }
    }
  }

  /// Compress JSON by reducing decimal precision
  /// Returns compressed string and compression level used
  Map<String, dynamic> _compressJsonWithInfo(String jsonStr) {
    final originalSize = jsonStr.length;
    String compressed = jsonStr;
    int level = 1;
    
    // Level 1: 3 decimals (default)
    compressed = jsonStr.replaceAllMapped(
      RegExp(r'(\d+\.\d{3})\d+'),
      (match) => match.group(1)!,
    );
    
    // Level 2: 2 decimals if still > 800KB
    if (compressed.length > 800000) {
      compressed = jsonStr.replaceAllMapped(
        RegExp(r'(\d+\.\d{2})\d+'),
        (match) => match.group(1)!,
      );
      level = 2;
    }
    
    // Level 3: 1 decimal if still > 900KB
    if (compressed.length > 900000) {
      compressed = jsonStr.replaceAllMapped(
        RegExp(r'(\d+\.\d{1})\d+'),
        (match) => match.group(1)!,
      );
      level = 3;
    }
    
    return {
      'compressed': compressed,
      'originalSize': originalSize,
      'compressedSize': compressed.length,
      'level': level,
      'isLarge': compressed.length > 900000,
    };
  }

  /// Compress JSON (simple version for backward compatibility)
  String _compressJson(String jsonStr) {
    return _compressJsonWithInfo(jsonStr)['compressed'] as String;
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles[index]['controller'].dispose();
      _selectedFiles.removeAt(index);
    });
  }

  void _clearAllFiles() {
    setState(() {
      for (var file in _selectedFiles) {
        file['controller'].dispose();
      }
      _selectedFiles.clear();
    });
  }

  Future<void> _uploadAll() async {
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

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadTotal = _selectedFiles.length;
    });

    // Prepare all signs for bulk upload
    List<Map<String, dynamic>> signsToUpload = [];
    List<String> skippedFiles = [];

    for (var file in _selectedFiles) {
      String word = file['controller'].text.trim();
      Map<String, dynamic> data = file['data'];

      if (word.isEmpty) {
        skippedFiles.add("${file['fileName']} (empty word)");
        continue;
      }

      signsToUpload.add({
        'word': word,
        'data': data,
      });
    }

    if (signsToUpload.isEmpty) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No valid files to upload"),
            backgroundColor: Colors.orange,
          )
        );
      }
      return;
    }

    try {
      // Use bulk upload (much faster!)
      final result = await _firestoreService.uploadSignsBulk(
        signsToUpload,
        _selectedCategory!,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = current;
              _uploadTotal = total;
            });
          }
        },
      );

      if (mounted) {
        setState(() => _isUploading = false);
        
        final successCount = result['success'] as int;
        final failedCount = result['failed'] as int;
        
        if (failedCount == 0 && skippedFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Uploaded $successCount signs to '$_selectedCategory'"),
              backgroundColor: Colors.green,
            )
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Uploaded $successCount. Failed: $failedCount. Skipped: ${skippedFiles.length}"),
              backgroundColor: Colors.orange,
            )
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload error: $e"),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total size info
    int totalOriginal = 0;
    int totalCompressed = 0;
    int largeFileCount = 0;
    for (var file in _selectedFiles) {
      totalOriginal += file['originalSize'] as int;
      totalCompressed += file['compressedSize'] as int;
      if (file['isLarge'] == true) largeFileCount++;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Signs"),
        actions: [
          if (_selectedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Clear all",
              onPressed: _clearAllFiles,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selector
            const Text(
              "Select Category:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
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
                      
                      List<DropdownMenuItem<String>> items = docs.map((doc) {
                        String name = doc['name'];
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }).toList();

                      if (_selectedCategory != null && !items.any((i) => i.value == _selectedCategory)) {
                        _selectedCategory = null;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            hint: const Text("Choose a category..."),
                            isExpanded: true,
                            items: items,
                            onChanged: _isUploading ? null : (newValue) {
                              setState(() => _selectedCategory = newValue);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: IconButton.filled(
                    onPressed: _isUploading ? null : _showAddCategoryDialog,
                    icon: const Icon(Icons.add),
                    tooltip: "Create new category",
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // File Picker Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickJsonFiles,
                    icon: const Icon(Icons.file_present),
                    label: const Text("Select JSON Files"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            
            // Size Info
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: largeFileCount > 0 
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: largeFileCount > 0 
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          largeFileCount > 0 ? Icons.warning : Icons.compress,
                          color: largeFileCount > 0 ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_selectedFiles.length} files ready",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Original: ${_formatBytes(totalOriginal)} → Compressed: ${_formatBytes(totalCompressed)} "
                                "(${((totalOriginal - totalCompressed) / totalOriginal * 100).toStringAsFixed(0)}% smaller)",
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (largeFileCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        "⚠️ $largeFileCount file(s) still > 900KB after compression.\n"
                        "Tip: Try removing face tracking or reduce frame rate in MediaPipe.",
                        style: const TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // File List Header
            if (_selectedFiles.isNotEmpty)
              Row(
                children: [
                  Text(
                    "Files to Upload (${_selectedFiles.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _isUploading ? null : _clearAllFiles,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text("Clear All"),
                  ),
                ],
              ),

            // File List
            Expanded(
              child: _selectedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            "No files selected",
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Select JSON files from your device",
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description, color: Colors.green),
                          ),
                          title: TextField(
                            controller: file['controller'],
                            enabled: !_isUploading,
                            decoration: InputDecoration(
                              labelText: "Word",
                              hintText: "Enter sign name",
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                              suffixIcon: Icon(
                                Icons.check_circle,
                                color: (file['controller'] as TextEditingController).text.isNotEmpty 
                                    ? Colors.green 
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${file['fileName']} • ${_formatBytes(file['compressedSize'])} (${file['savings']}% saved)",
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                                if (file['compressionLevel'] != null && file['compressionLevel'] > 1)
                                  Text(
                                    file['compressionLevel'] == 2 
                                        ? "⚡ Medium compression applied"
                                        : "⚡ Heavy compression applied",
                                    style: TextStyle(
                                      fontSize: 10, 
                                      color: file['compressionLevel'] == 3 ? Colors.orange : Colors.blue,
                                    ),
                                  ),
                                if (file['isLarge'] == true)
                                  const Text(
                                    "⚠️ File still large - may fail to upload",
                                    style: TextStyle(fontSize: 10, color: Colors.red),
                                  ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: _isUploading ? null : () => _removeFile(index),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            // Upload Progress
            if (_isUploading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadTotal > 0 ? _uploadProgress / _uploadTotal : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Uploading $_uploadProgress of $_uploadTotal...",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isUploading || _selectedFiles.isEmpty || _selectedCategory == null) 
                    ? null 
                    : _uploadAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isUploading 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Uploading $_uploadProgress/$_uploadTotal...",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        _selectedCategory == null 
                            ? "Select Category First" 
                            : _selectedFiles.isEmpty
                                ? "Select Files to Upload"
                                : "Upload ${_selectedFiles.length} Signs to '$_selectedCategory'", 
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}