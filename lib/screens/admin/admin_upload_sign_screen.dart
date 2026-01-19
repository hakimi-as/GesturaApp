import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // To handle Web vs Mobile file reading
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class AdminUploadSignScreen extends StatefulWidget {
  const AdminUploadSignScreen({super.key});

  @override
  State<AdminUploadSignScreen> createState() => _AdminUploadSignScreenState();
}

class _AdminUploadSignScreenState extends State<AdminUploadSignScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _wordController = TextEditingController();
  
  String? _fileName;
  Map<String, dynamic>? _loadedJsonData;
  bool _isUploading = false;

  Future<void> _pickJsonFile() async {
    // Pick JSON file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      try {
        String content;
        
        // Handle Web vs Mobile differences
        if (kIsWeb) {
          final bytes = result.files.first.bytes;
          content = utf8.decode(bytes!);
        } else {
          final file = File(result.files.single.path!);
          content = await file.readAsString();
        }

        final data = json.decode(content);
        
        setState(() {
          _fileName = result.files.single.name;
          _loadedJsonData = data;
          
          // Auto-fill word from JSON if available, or filename
          if (data['word'] != null) {
            _wordController.text = data['word'];
          } else {
            _wordController.text = _fileName!.split('.').first;
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid JSON file: $e")));
      }
    }
  }

  Future<void> _upload() async {
    if (_wordController.text.isEmpty || _loadedJsonData == null) return;

    setState(() => _isUploading = true);

    try {
      await _firestoreService.uploadSign(_wordController.text, _loadedJsonData!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Sign uploaded.")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload New Sign")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. Word Input
            TextField(
              controller: _wordController,
              decoration: const InputDecoration(
                labelText: "Word (e.g. 'hello')",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 2. File Picker
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.file_present, size: 40, color: _fileName == null ? Colors.grey : Colors.green),
                  const SizedBox(height: 10),
                  Text(_fileName ?? "No JSON file selected"),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickJsonFile,
                    child: const Text("Select JSON File"),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // 3. Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isUploading || _loadedJsonData == null) ? null : _upload,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save to Cloud", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}