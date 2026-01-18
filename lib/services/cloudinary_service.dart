import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dkrcpn0sp';
  static const String apiKey = '726159996836755';
  static const String apiSecret = 'hsGvsv-pOqtHoZG30ZiDJpwOp4I';
  static const String uploadPreset = 'Gestura';

  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName';

  /// Upload image to Cloudinary from XFile (works on web and mobile)
  static Future<CloudinaryUploadResult?> uploadImage(XFile file, {String? folder}) async {
    return _upload(file, 'image', folder: folder);
  }

  /// Upload video to Cloudinary from XFile (works on web and mobile)
  static Future<CloudinaryUploadResult?> uploadVideo(XFile file, {String? folder}) async {
    return _upload(file, 'video', folder: folder);
  }

  /// Upload from bytes (useful for web)
  static Future<CloudinaryUploadResult?> uploadImageFromBytes(
    Uint8List bytes,
    String filename, {
    String? folder,
  }) async {
    return _uploadFromBytes(bytes, filename, 'image', folder: folder);
  }

  /// Upload video from bytes
  static Future<CloudinaryUploadResult?> uploadVideoFromBytes(
    Uint8List bytes,
    String filename, {
    String? folder,
  }) async {
    return _uploadFromBytes(bytes, filename, 'video', folder: folder);
  }

  /// Generic upload method using XFile
  static Future<CloudinaryUploadResult?> _upload(
    XFile file,
    String resourceType, {
    String? folder,
  }) async {
    try {
      final uri = Uri.parse('$_uploadUrl/$resourceType/upload');

      final request = http.MultipartRequest('POST', uri);

      // Read file bytes (works on both web and mobile)
      final bytes = await file.readAsBytes();
      final filename = file.name;

      // Add file as bytes
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));

      // Add upload preset (unsigned upload)
      request.fields['upload_preset'] = uploadPreset;

      // Add folder if specified
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Add timestamp
      request.fields['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('📤 Uploading $resourceType to Cloudinary...');
      debugPrint('   File: $filename');
      debugPrint('   Size: ${bytes.length} bytes');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Upload successful!');
        debugPrint('   URL: ${data['secure_url']}');

        return CloudinaryUploadResult(
          publicId: data['public_id'],
          secureUrl: data['secure_url'],
          url: data['url'],
          resourceType: data['resource_type'],
          format: data['format'],
          width: data['width'],
          height: data['height'],
          duration: data['duration']?.toDouble(),
          bytes: data['bytes'],
        );
      } else {
        debugPrint('❌ Upload failed: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return null;
    }
  }

  /// Generic upload method using bytes directly
  static Future<CloudinaryUploadResult?> _uploadFromBytes(
    Uint8List bytes,
    String filename,
    String resourceType, {
    String? folder,
  }) async {
    try {
      final uri = Uri.parse('$_uploadUrl/$resourceType/upload');

      final request = http.MultipartRequest('POST', uri);

      // Add file as bytes
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));

      // Add upload preset (unsigned upload)
      request.fields['upload_preset'] = uploadPreset;

      // Add folder if specified
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Add timestamp
      request.fields['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('📤 Uploading $resourceType to Cloudinary...');
      debugPrint('   File: $filename');
      debugPrint('   Size: ${bytes.length} bytes');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Upload successful!');
        debugPrint('   URL: ${data['secure_url']}');

        return CloudinaryUploadResult(
          publicId: data['public_id'],
          secureUrl: data['secure_url'],
          url: data['url'],
          resourceType: data['resource_type'],
          format: data['format'],
          width: data['width'],
          height: data['height'],
          duration: data['duration']?.toDouble(),
          bytes: data['bytes'],
        );
      } else {
        debugPrint('❌ Upload failed: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return null;
    }
  }

  /// Delete a resource from Cloudinary
  static Future<bool> deleteResource(String publicId, String resourceType) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(publicId, timestamp);

      final uri = Uri.parse('$_uploadUrl/$resourceType/destroy');

      final response = await http.post(uri, body: {
        'public_id': publicId,
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
      });

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      return false;
    }
  }

  /// Generate signature for authenticated requests
  static String _generateSignature(String publicId, String timestamp) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Get video thumbnail URL
  static String getVideoThumbnail(String videoUrl, {int width = 400, int height = 300}) {
    final parts = videoUrl.split('/upload/');
    if (parts.length == 2) {
      return '${parts[0]}/upload/w_$width,h_$height,c_fill/${parts[1].replaceAll('.mp4', '.jpg').replaceAll('.mov', '.jpg')}';
    }
    return videoUrl;
  }

  /// Get optimized image URL
  static String getOptimizedImage(String imageUrl, {int? width, int? height, String quality = 'auto'}) {
    final parts = imageUrl.split('/upload/');
    if (parts.length == 2) {
      String transformation = 'q_$quality,f_auto';
      if (width != null) transformation += ',w_$width';
      if (height != null) transformation += ',h_$height';
      transformation += ',c_fill';
      return '${parts[0]}/upload/$transformation/${parts[1]}';
    }
    return imageUrl;
  }
}

class CloudinaryUploadResult {
  final String publicId;
  final String secureUrl;
  final String url;
  final String resourceType;
  final String format;
  final int? width;
  final int? height;
  final double? duration;
  final int? bytes;

  CloudinaryUploadResult({
    required this.publicId,
    required this.secureUrl,
    required this.url,
    required this.resourceType,
    required this.format,
    this.width,
    this.height,
    this.duration,
    this.bytes,
  });

  bool get isVideo => resourceType == 'video';
  bool get isImage => resourceType == 'image';

  String get fileSizeFormatted {
    if (bytes == null) return '';
    if (bytes! < 1024) return '$bytes B';
    if (bytes! < 1024 * 1024) return '${(bytes! / 1024).toStringAsFixed(1)} KB';
    return '${(bytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get durationFormatted {
    if (duration == null) return '';
    final minutes = (duration! / 60).floor();
    final seconds = (duration! % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Simple SHA1 implementation for signature
class sha1 {
  static Digest convert(List<int> bytes) {
    return Digest(_sha1(bytes));
  }

  static List<int> _sha1(List<int> message) {
    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;

    final ml = message.length * 8;
    message = List.from(message);
    message.add(0x80);
    while ((message.length % 64) != 56) {
      message.add(0x00);
    }
    
    for (var i = 7; i >= 0; i--) {
      message.add((ml >> (i * 8)) & 0xFF);
    }

    for (var i = 0; i < message.length; i += 64) {
      final w = List<int>.filled(80, 0);
      
      for (var j = 0; j < 16; j++) {
        w[j] = (message[i + j * 4] << 24) |
               (message[i + j * 4 + 1] << 16) |
               (message[i + j * 4 + 2] << 8) |
               message[i + j * 4 + 3];
      }
      
      for (var j = 16; j < 80; j++) {
        w[j] = _rotateLeft32(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1);
      }

      var a = h0, b = h1, c = h2, d = h3, e = h4;

      for (var j = 0; j < 80; j++) {
        int f, k;
        if (j < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (j < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (j < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp = (_rotateLeft32(a, 5) + f + e + k + w[j]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _rotateLeft32(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    return [
      (h0 >> 24) & 0xFF, (h0 >> 16) & 0xFF, (h0 >> 8) & 0xFF, h0 & 0xFF,
      (h1 >> 24) & 0xFF, (h1 >> 16) & 0xFF, (h1 >> 8) & 0xFF, h1 & 0xFF,
      (h2 >> 24) & 0xFF, (h2 >> 16) & 0xFF, (h2 >> 8) & 0xFF, h2 & 0xFF,
      (h3 >> 24) & 0xFF, (h3 >> 16) & 0xFF, (h3 >> 8) & 0xFF, h3 & 0xFF,
      (h4 >> 24) & 0xFF, (h4 >> 16) & 0xFF, (h4 >> 8) & 0xFF, h4 & 0xFF,
    ];
  }

  static int _rotateLeft32(int n, int count) {
    return ((n << count) | (n >> (32 - count))) & 0xFFFFFFFF;
  }
}

class Digest {
  final List<int> bytes;
  Digest(this.bytes);

  @override
  String toString() {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}