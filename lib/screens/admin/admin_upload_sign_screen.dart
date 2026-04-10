import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/video_processing_service.dart';

class AdminUploadSignScreen extends StatefulWidget {
  const AdminUploadSignScreen({super.key});

  @override
  State<AdminUploadSignScreen> createState() => _AdminUploadSignScreenState();
}

class _AdminUploadSignScreenState extends State<AdminUploadSignScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  // ── Shared ──────────────────────────────────────────────────────────────
  String? _selectedCategory;

  // ── JSON tab ─────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _selectedFiles = [];
  bool _isUploading = false;
  int _uploadProgress = 0;
  int _uploadTotal = 0;

  // ── Video tab ─────────────────────────────────────────────────────────────
  Uint8List? _pickedVideoBytes;
  String _videoFileName = '';
  final TextEditingController _signNameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  ProcessingStatus? _processingStatus;
  String _processingMessage = '';
  List<Map<String, dynamic>> _processedFrames = [];
  bool _isSavingVideo = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signNameController.dispose();
    _urlController.dispose();
    for (var file in _selectedFiles) {
      file['controller'].dispose();
    }
    super.dispose();
  }

  // ── Category helpers ──────────────────────────────────────────────────────

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Sports, Colors, Animals',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final nav = Navigator.of(ctx);
                await _firestoreService.addSignLibraryCategory(controller.text.trim());
                setState(() => _selectedCategory = controller.text.trim());
                nav.pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getSignLibraryCategoriesStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!.docs;
              final items = docs
                  .map((doc) => DropdownMenuItem(value: doc['name'] as String, child: Text(doc['name'] as String)))
                  .toList();
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
                    hint: const Text('Choose a category...'),
                    isExpanded: true,
                    items: items,
                    onChanged: (_isUploading || _isSavingVideo)
                        ? null
                        : (v) => setState(() => _selectedCategory = v),
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
            onPressed: (_isUploading || _isSavingVideo) ? null : _showAddCategoryDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create new category',
          ),
        ),
      ],
    );
  }

  // ── JSON tab ──────────────────────────────────────────────────────────────

  Future<void> _pickJsonFiles() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: true,
    );
    if (result == null) return;
    final newFiles = <Map<String, dynamic>>[];

    for (var pickedFile in result.files) {
      try {
        String content;
        if (kIsWeb) {
          content = utf8.decode(pickedFile.bytes!);
        } else {
          content = await File(pickedFile.path!).readAsString();
        }

        final data = json.decode(content);
        final initialWord = data['word'] ?? pickedFile.name.split('.').first;
        final compressionResult = _compressJsonWithInfo(content);

        newFiles.add({
          'fileName': pickedFile.name,
          'data': json.decode(compressionResult['compressed'] as String),
          'controller': TextEditingController(text: initialWord),
          'originalSize': content.length,
          'compressedSize': compressionResult['compressedSize'],
          'savings': ((content.length - (compressionResult['compressedSize'] as int)) / content.length * 100)
              .toStringAsFixed(1),
          'compressionLevel': compressionResult['level'],
          'isLarge': compressionResult['isLarge'],
        });
      } catch (e) {
        messenger.showSnackBar(SnackBar(
          content: Text('Error reading ${pickedFile.name}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }

    setState(() => _selectedFiles.addAll(newFiles));

    if (newFiles.isNotEmpty) {
      final totalSaved = newFiles.fold<int>(
          0, (s, f) => s + (f['originalSize'] as int) - (f['compressedSize'] as int));
      messenger.showSnackBar(SnackBar(
        content: Text(
            'Added ${newFiles.length} files (${(totalSaved / 1024).toStringAsFixed(1)} KB saved)'),
        backgroundColor: Colors.green,
      ));
    }
  }

  Map<String, dynamic> _compressJsonWithInfo(String jsonStr) {
    final originalSize = jsonStr.length;
    var compressed = jsonStr.replaceAllMapped(
      RegExp(r'(\d+\.\d{3})\d+'), (m) => m.group(1)!);
    int level = 1;

    if (compressed.length > 800000) {
      compressed = jsonStr.replaceAllMapped(
          RegExp(r'(\d+\.\d{2})\d+'), (m) => m.group(1)!);
      level = 2;
    }
    if (compressed.length > 900000) {
      compressed = jsonStr.replaceAllMapped(
          RegExp(r'(\d+\.\d{1})\d+'), (m) => m.group(1)!);
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

  void _removeFile(int index) {
    setState(() {
      _selectedFiles[index]['controller'].dispose();
      _selectedFiles.removeAt(index);
    });
  }

  void _clearAllFiles() {
    setState(() {
      for (var f in _selectedFiles) { f['controller'].dispose(); }
      _selectedFiles.clear();
    });
  }

  Future<void> _uploadAllJson() async {
    if (_selectedFiles.isEmpty || _selectedCategory == null) return;

    setState(() { _isUploading = true; _uploadProgress = 0; _uploadTotal = _selectedFiles.length; });

    final messenger = ScaffoldMessenger.of(context);
    final signsToUpload = <Map<String, dynamic>>[];
    final skipped = <String>[];

    for (var file in _selectedFiles) {
      final word = (file['controller'] as TextEditingController).text.trim();
      if (word.isEmpty) { skipped.add(file['fileName']); continue; }
      signsToUpload.add({'word': word, 'data': file['data']});
    }

    if (signsToUpload.isEmpty) {
      setState(() => _isUploading = false);
      messenger.showSnackBar(const SnackBar(
        content: Text('No valid files to upload'), backgroundColor: Colors.orange));
      return;
    }

    try {
      final result = await _firestoreService.uploadSignsBulk(
        signsToUpload, _selectedCategory!,
        onProgress: (current, total) {
          if (mounted) setState(() { _uploadProgress = current; _uploadTotal = total; });
        },
      );

      if (mounted) {
        setState(() => _isUploading = false);
        final successCount = result['success'] as int;
        final failedCount = result['failed'] as int;
        if (failedCount == 0 && skipped.isEmpty) {
          messenger.showSnackBar(SnackBar(
            content: Text('✅ Uploaded $successCount signs to \'$_selectedCategory\''),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context);
        } else {
          messenger.showSnackBar(SnackBar(
            content: Text('Uploaded $successCount. Failed: $failedCount. Skipped: ${skipped.length}'),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        messenger.showSnackBar(SnackBar(
          content: Text('Upload error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  // ── Video tab ──────────────────────────────────────────────────────────────

  Future<void> _pickVideo() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: true, // always load bytes — works on web and native
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.bytes == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not read video data on this platform.')));
      return;
    }
    setState(() {
      _pickedVideoBytes = picked.bytes;
      _videoFileName = picked.name;
      _processingStatus = null;
      _processingMessage = '';
      _processedFrames = [];
      if (_signNameController.text.isEmpty) {
        _signNameController.text = picked.name.split('.').first.replaceAll('_', ' ');
      }
    });
  }

  Future<void> _processUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _processingStatus = ProcessingStatus.uploading;
      _processingMessage = 'Downloading video...';
      _processedFrames = [];
      _pickedVideoBytes = null;
      _videoFileName = '';
    });

    final result = await VideoProcessingService.processVideoUrl(
      url: url,
      onStatus: (status, message) {
        if (mounted) setState(() { _processingStatus = status; _processingMessage = message; });
      },
    );

    if (mounted) {
      setState(() {
        _processingStatus = result.success ? ProcessingStatus.done : ProcessingStatus.failed;
        _processingMessage = result.success
            ? '${result.frames.length} frames extracted'
            : result.errorMessage ?? 'Processing failed';
        _processedFrames = result.frames;
      });
    }
  }

  Future<void> _processVideo() async {
    if (_pickedVideoBytes == null) return;

    setState(() {
      _processingStatus = ProcessingStatus.uploading;
      _processingMessage = 'Connecting to processor...';
      _processedFrames = [];
    });

    final result = await VideoProcessingService.processVideo(
      videoBytes: _pickedVideoBytes!,
      filename: _videoFileName,
      onStatus: (status, message) {
        if (mounted) setState(() { _processingStatus = status; _processingMessage = message; });
      },
    );

    if (mounted) {
      setState(() {
        _processingStatus = result.success ? ProcessingStatus.done : ProcessingStatus.failed;
        _processingMessage = result.success
            ? '${result.frames.length} frames extracted'
            : result.errorMessage ?? 'Processing failed';
        _processedFrames = result.frames;
      });
    }
  }

  Future<void> _saveProcessedSign() async {
    final signName = _signNameController.text.trim();
    if (signName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a sign name first.')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category first.')));
      return;
    }
    if (_processedFrames.isEmpty) return;

    setState(() => _isSavingVideo = true);

    try {
      // Compress frames to fit Firestore's 1MB document limit:
      // 1. Drop face landmarks (468 pts/frame → saves ~75% of data)
      // 2. Reduce float precision to 2 decimal places
      // 3. Cap at 100 frames
      final compressed = _compressFrames(_processedFrames);

      await _firestoreService.uploadSignsBulk(
        [{'word': signName, 'data': {'data': compressed}}],
        _selectedCategory!,
      );

      if (mounted) {
        setState(() => _isSavingVideo = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ "$signName" saved to \'$_selectedCategory\''),
          backgroundColor: Colors.green,
        ));
        // Reset video tab state
        setState(() {
          _pickedVideoBytes = null;
          _videoFileName = '';
          _signNameController.clear();
          _urlController.clear();
          _processingStatus = null;
          _processedFrames = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingVideo = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Reduces frame data to fit Firestore's 1MB document limit.
  /// Drops face landmarks and caps precision + frame count.
  List<Map<String, dynamic>> _compressFrames(List<Map<String, dynamic>> frames) {
    // Cap at 100 frames (drop evenly if more)
    List<Map<String, dynamic>> sampled = frames;
    if (frames.length > 100) {
      final step = frames.length / 100;
      sampled = List.generate(100, (i) => frames[(i * step).round().clamp(0, frames.length - 1)]);
    }

    return sampled.map((frame) {
      return {
        'pose':       _roundLandmarks(frame['pose']),
        'left_hand':  _roundLandmarks(frame['left_hand']),
        'right_hand': _roundLandmarks(frame['right_hand']),
        // Face omitted — SkeletonPainter falls back to a simple head circle
      };
    }).toList();
  }

  List<Map<String, dynamic>> _roundLandmarks(dynamic landmarks) {
    if (landmarks == null || landmarks is! List) return [];
    return landmarks.map((lm) {
      if (lm is! Map) return <String, dynamic>{};
      return {
        'x': double.parse((lm['x'] as num).toStringAsFixed(2)),
        'y': double.parse((lm['y'] as num).toStringAsFixed(2)),
        'z': double.parse((lm['z'] as num).toStringAsFixed(2)),
      };
    }).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Signs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'JSON Files'),
            Tab(icon: Icon(Icons.videocam), text: 'Video → Auto'),
          ],
        ),
        actions: [
          if (_tabController.index == 0 && _selectedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: _clearAllFiles,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shared category selector
            const Text('Select Category:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildCategoryRow(),
            const SizedBox(height: 20),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildJsonTab(), _buildVideoTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── JSON tab widget ────────────────────────────────────────────────────────

  Widget _buildJsonTab() {
    int totalOriginal = 0, totalCompressed = 0, largeCount = 0;
    for (var f in _selectedFiles) {
      totalOriginal += f['originalSize'] as int;
      totalCompressed += f['compressedSize'] as int;
      if (f['isLarge'] == true) largeCount++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickJsonFiles,
              icon: const Icon(Icons.file_present),
              label: const Text('Select JSON Files'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
          ),
        ]),

        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (largeCount > 0 ? Colors.orange : Colors.green).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: (largeCount > 0 ? Colors.orange : Colors.green).withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(largeCount > 0 ? Icons.warning : Icons.compress,
                    color: largeCount > 0 ? Colors.orange : Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_selectedFiles.length} files ready',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Original: ${_formatBytes(totalOriginal)} → '
                      'Compressed: ${_formatBytes(totalCompressed)} '
                      '(${((totalOriginal - totalCompressed) / totalOriginal * 100).toStringAsFixed(0)}% smaller)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ]),
                ),
              ]),
              if (largeCount > 0) ...[
                const SizedBox(height: 8),
                Text('⚠️ $largeCount file(s) still > 900KB after compression.',
                    style: const TextStyle(fontSize: 11, color: Colors.orange)),
              ],
            ]),
          ),
        ],

        const SizedBox(height: 20),

        if (_selectedFiles.isNotEmpty)
          Row(children: [
            Text('Files to Upload (${_selectedFiles.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            TextButton.icon(
              onPressed: _isUploading ? null : _clearAllFiles,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear All'),
            ),
          ]),

        Expanded(
          child: _selectedFiles.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.upload_file, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No files selected',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Select pre-processed JSON skeleton files',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ]),
                )
              : ListView.separated(
                  itemCount: _selectedFiles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    final ctrl = file['controller'] as TextEditingController;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.description, color: Colors.green),
                      ),
                      title: TextField(
                        controller: ctrl,
                        enabled: !_isUploading,
                        decoration: InputDecoration(
                          labelText: 'Word', hintText: 'Enter sign name',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                          suffixIcon: Icon(Icons.check_circle,
                              color: ctrl.text.isNotEmpty ? Colors.green : Colors.grey, size: 20),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            '${file['fileName']} • ${_formatBytes(file['compressedSize'])} (${file['savings']}% saved)',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          if ((file['compressionLevel'] as int) > 1)
                            Text(
                              (file['compressionLevel'] as int) == 2
                                  ? '⚡ Medium compression applied'
                                  : '⚡ Heavy compression applied',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: (file['compressionLevel'] as int) == 3
                                      ? Colors.orange
                                      : Colors.blue)),
                          if (file['isLarge'] == true)
                            const Text('⚠️ File still large — may fail to upload',
                                style: TextStyle(fontSize: 10, color: Colors.red)),
                        ]),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        onPressed: _isUploading ? null : () => _removeFile(index),
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 16),

        if (_isUploading) ...[
          LinearProgressIndicator(
              value: _uploadTotal > 0 ? _uploadProgress / _uploadTotal : null),
          const SizedBox(height: 8),
          Text('Uploading $_uploadProgress of $_uploadTotal...',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
        ],

        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: (_isUploading || _selectedFiles.isEmpty || _selectedCategory == null)
                ? null
                : _uploadAllJson,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple, disabledBackgroundColor: Colors.grey[300]),
            child: _isUploading
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text('Uploading $_uploadProgress/$_uploadTotal...',
                        style: const TextStyle(color: Colors.white)),
                  ])
                : Text(
                    _selectedCategory == null
                        ? 'Select Category First'
                        : _selectedFiles.isEmpty
                            ? 'Select Files to Upload'
                            : 'Upload ${_selectedFiles.length} Signs to \'$_selectedCategory\'',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Video tab widget ───────────────────────────────────────────────────────

  Widget _buildVideoTab() {
    final bool canProcess = _pickedVideoBytes != null &&
        _processingStatus != ProcessingStatus.uploading &&
        _processingStatus != ProcessingStatus.processing;

    final bool canSave = _processedFrames.isNotEmpty && !_isSavingVideo;

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Auto Video Processing',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Upload a video file OR paste a TikTok / Instagram / direct MP4 link '
                  'to auto-convert to skeleton JSON. '
                  'YouTube links are blocked by YouTube on server IPs — download and upload the file instead.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                ),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // Sign name field
        TextField(
          controller: _signNameController,
          decoration: const InputDecoration(
            labelText: 'Sign Name',
            hintText: 'e.g., hello, thank you, love',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label_outline),
          ),
        ),

        const SizedBox(height: 20),

        // ── URL input section ────────────────────────────────────────────
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('OR PASTE A LINK',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 1)),
          ),
          const Expanded(child: Divider()),
        ]),

        const SizedBox(height: 14),

        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'TikTok / Instagram / Direct MP4 URL',
            hintText: 'https://tiktok.com/... or https://example.com/sign.mp4',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.link),
            suffixIcon: _urlController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _urlController.clear()),
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _processUrl(),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity, height: 46,
          child: OutlinedButton.icon(
            onPressed: (_urlController.text.trim().isEmpty ||
                    _processingStatus == ProcessingStatus.uploading ||
                    _processingStatus == ProcessingStatus.processing)
                ? null
                : _processUrl,
            icon: (_processingStatus == ProcessingStatus.uploading ||
                    _processingStatus == ProcessingStatus.processing)
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            label: const Text('Download & Process URL'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              side: const BorderSide(color: Colors.deepPurple),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── OR upload file ───────────────────────────────────────────────
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('OR UPLOAD A FILE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 1)),
          ),
          const Expanded(child: Divider()),
        ]),

        const SizedBox(height: 14),

        // Video picker
        GestureDetector(
          onTap: (_processingStatus == ProcessingStatus.uploading ||
                  _processingStatus == ProcessingStatus.processing)
              ? null
              : _pickVideo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: _pickedVideoBytes != null
                  ? Colors.green.withValues(alpha: 0.07)
                  : Colors.grey.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pickedVideoBytes != null
                    ? Colors.green.withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                _pickedVideoBytes != null ? Icons.videocam : Icons.video_file_outlined,
                size: 48,
                color: _pickedVideoBytes != null ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _pickedVideoBytes != null ? _videoFileName : 'Tap to select a video',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _pickedVideoBytes != null ? Colors.green[700] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (_pickedVideoBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatBytes(_pickedVideoBytes!.lengthInBytes),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              if (_pickedVideoBytes == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'MP4, MOV, AVI — keep it under 30s for best results',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // Process button
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: canProcess ? _processVideo : null,
            icon: (_processingStatus == ProcessingStatus.uploading ||
                    _processingStatus == ProcessingStatus.processing)
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(
              _processingStatus == ProcessingStatus.uploading
                  ? 'Uploading...'
                  : _processingStatus == ProcessingStatus.processing
                      ? 'Processing...'
                      : 'Process Video',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              disabledBackgroundColor: Colors.grey[300],
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // Processing status card
        if (_processingStatus != null) ...[
          const SizedBox(height: 16),
          _buildStatusCard(),
        ],

        // Save button (shown only after successful processing)
        if (_processedFrames.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: canSave ? _saveProcessedSign : null,
              icon: _isSavingVideo
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload),
              label: Text(_isSavingVideo
                  ? 'Saving...'
                  : 'Save "${_signNameController.text.isEmpty ? "sign" : _signNameController.text}" to Database'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),

        // HuggingFace setup instructions
        _buildSetupInstructions(),
      ]),
    );
  }

  Widget _buildStatusCard() {
    final isError = _processingStatus == ProcessingStatus.failed;
    final isDone = _processingStatus == ProcessingStatus.done;
    final color = isError ? Colors.red : isDone ? Colors.green : Colors.blue;
    final icon = isError ? Icons.error_outline : isDone ? Icons.check_circle_outline : Icons.hourglass_top;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isDone ? '✅ Processing complete' : isError ? '❌ Processing failed' : '⏳ In progress',
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(_processingMessage,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSetupInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.build_circle_outlined, color: Colors.amber, size: 18),
          SizedBox(width: 8),
          Text('HuggingFace Space Setup',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        _step('1', 'Go to huggingface.co → New Space → SDK: FastAPI'),
        _step('2', 'Upload the Python template from tools/hf_space/app.py in this project'),
        _step('3', 'Space installs mediapipe, processes videos at /process endpoint'),
        _step('4', 'Copy your Space URL into VideoProcessingService.baseUrl'),
        _step('5', 'Space sleeps after 48h inactivity — first request takes ~30s to wake up'),
        const SizedBox(height: 8),
        Text(
          'Current endpoint: ${VideoProcessingService.baseUrl}',
          style: const TextStyle(
              fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
        ),
      ]),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
          child: Center(child: Text(number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
      ]),
    );
  }
}
