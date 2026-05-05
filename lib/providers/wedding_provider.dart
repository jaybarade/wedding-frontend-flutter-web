
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/wedding.dart';
import '../models/photo.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'dart:convert';



class WeddingProvider with ChangeNotifier {
  final String? token;
  List<Wedding> _myWeddings = [];
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _error;

  WeddingProvider({this.token});

  List<Wedding> get myWeddings => _myWeddings;

  bool get isLoading => _isLoading;

  double get uploadProgress => _uploadProgress;

  String? get error => _error;

  ApiService get _api => ApiService(token: token);

  Future<void> fetchMyWeddings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get(ApiConfig.myWeddingsUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _myWeddings = data.map((json) => Wedding.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch weddings';
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Wedding?> createWedding(String title, PlatformFile coverFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = await _api.createMultipartRequest(
          'POST', ApiConfig.createWeddingUrl);
      request.fields['title'] = title;

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'coverImage',
          coverFile.bytes!,
          filename: coverFile.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'coverImage',
          coverFile.path!,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 🔥 DEBUG (IMPORTANT)
      print("STATUS: ${response.statusCode}");
      print("RAW BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          // ✅ SAFE JSON PARSE
          final data = jsonDecode(response.body);

          final newWedding = Wedding.fromJson(data);
          _myWeddings.insert(0, newWedding);

          _isLoading = false;
          notifyListeners();
          return newWedding;
        } catch (jsonError) {
          // ❌ JSON ERROR HANDLE
          print("JSON PARSE ERROR: $jsonError");

          _error = "Server returned invalid JSON";
        }
      } else {
        _error = "Failed: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      _error = "Error: $e";
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> uploadPhotos(int weddingId, List<PlatformFile> files) async {
    _isLoading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      final request = await _api.createMultipartRequest(
          'POST', ApiConfig.uploadPhotosUrl);
      request.fields['weddingId'] = weddingId.toString();

      for (var file in files) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'files',
              file.bytes!,
              filename: file.name,
              contentType: http.MediaType('image', 'jpeg'), // 🔥 ADD THIS
            ),
          );
        } else {
          request.files.add(await
          http.MultipartFile.fromPath(
            'files',
            file.path!,
          ));
        }
      }

      final streamedResponse = await request.send();
      final totalBytes = streamedResponse.contentLength ?? 0;
      int uploadedBytes = 0;

      // Note: This simple stream listen doesn't give precise progress for the upload itself,
      // but for the response stream. To get precise upload progress, a custom http client is usually needed.
      // However, we follow the user's suggestion of using the stream.

      await for (var chunk in streamedResponse.stream) {
        uploadedBytes += chunk.length;
        if (totalBytes > 0) {
          _uploadProgress = uploadedBytes / totalBytes;
          notifyListeners();
        }
      }

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        _isLoading = false;
        _uploadProgress = 1.0;
        notifyListeners();
        return true;
      } else {
        _error = 'Upload failed: ${streamedResponse.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }



  Future<Map<String, dynamic>?> fetchPublicGallery(String slug) async {
    final url =
        '${ApiConfig.baseUrl}${ApiConfig.publicGalleryUrl}/$slug';

    try {
      print("🌐 PUBLIC API CALL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'Accept': 'application/json',
        },
      );

      print("📡 STATUS: ${response.statusCode}");
      print("📦 BODY: ${response.body}");

      // ❌ Server error
      if (response.statusCode != 200) {
        return {
          "_error": "Server error ${response.statusCode}",
          "_raw": response.body,
        };
      }

      // ❌ Empty response
      if (response.body.isEmpty) {
        return {
          "_error": "Empty response from server",
        };
      }

      // ❌ HTML आया (Render error / crash)
      if (response.body.startsWith("<")) {
        return {
          "_error": "Invalid response (HTML मिला, JSON नहीं)",
          "_raw": response.body,
        };
      }

      // ✅ Safe JSON parse
      try {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {
            "_error": "Invalid JSON structure",
          };
        }
      } catch (e) {
        return {
          "_error": "JSON parse error: $e",
          "_raw": response.body,
        };
      }
    } catch (e) {
      debugPrint('❌ Network error: $e');

      return {
        "_error": "Network error: $e",
      };
    }
  }
}