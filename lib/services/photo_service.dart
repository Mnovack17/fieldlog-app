import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Uploads Field Log photos to Cloudinary (free tier, no backend needed)
/// using an unsigned upload preset. Unlike the Web3Forms email notification,
/// photos are a required part of every entry, so a failed upload here
/// should stop the submission rather than being silently swallowed —
/// the caller is expected to catch and surface the error.
class PhotoService {
  // Cloudinary account for Direct Services Group's Field Log app.
  // The cloud name and unsigned upload preset are safe to ship in the
  // app — an unsigned preset can only accept uploads into this account
  // under the rules configured for it, it can't read or delete anything.
  static const String _cloudName = 'mk3dfpsh';
  static const String _uploadPreset = 'fieldlog_photos';

  /// Uploads each file and returns the resulting Cloudinary URLs, in the
  /// same order as [files]. Throws on the first failure.
  static Future<List<String>> uploadAll(List<File> files) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await _uploadOne(file));
    }
    return urls;
  }

  static Future<String> _uploadOne(File file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Photo upload failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Photo upload did not return a URL');
    }
    return url;
  }
}
