import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Finds a representative image for a word from free image libraries and saves
/// it to local storage. Uses Pixabay when an API key is set (better relevance
/// and an illustration filter), otherwise falls back to the no-key Openverse API.
class ImageSearchService {
  static const _keyName = 'pixabay_api_key';

  final FlutterSecureStorage _storage;

  ImageSearchService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getPixabayKey() => _storage.read(key: _keyName);

  Future<void> setPixabayKey(String key) => _storage.write(key: _keyName, value: key.trim());

  /// Generates an AI illustration of [query] via Pollinations (free, no key) and
  /// saves it locally. When [colorName] is given, the subject is drawn in that
  /// solid color on a white background — matching the article color-coding.
  /// Returns the local file path, or null on failure. Never throws.
  Future<String?> generateImage(String query, {String? colorName}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    final subject = colorName != null
        ? 'a single $trimmed, the $trimmed colored entirely solid $colorName'
        : 'a single $trimmed';
    final prompt =
        'a simple flat minimalist vector illustration of $subject, '
        'isolated on a plain pure white background, centered, no text, no shadows';

    final uri = Uri.https('image.pollinations.ai', '/prompt/$prompt', {
      'width': '512',
      'height': '512',
      'nologo': 'true',
    });

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 60));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      if (!(res.headers['content-type']?.startsWith('image/') ?? false)) return null;
      return await _saveBytes(res.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  /// Returns the local file path of a downloaded image for [query], or null if
  /// nothing usable was found. Never throws — image fetch is best-effort.
  Future<String?> fetchAndSaveImage(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    try {
      final url = await _findImageUrl(trimmed);
      if (url == null) return null;
      return await _download(url);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _findImageUrl(String query) async {
    final pixabayKey = await getPixabayKey();
    if (pixabayKey != null && pixabayKey.isNotEmpty) {
      final url = await _pixabay(query, pixabayKey, 'illustration') ?? await _pixabay(query, pixabayKey, 'photo');
      if (url != null) return url;
    }
    return _openverse(query);
  }

  Future<String?> _pixabay(String query, String key, String imageType) async {
    final uri = Uri.https('pixabay.com', '/api/', {
      'key': key,
      'q': query,
      'image_type': imageType,
      'per_page': '3',
      'safesearch': 'true',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final hits = data['hits'] as List<dynamic>?;
    if (hits == null || hits.isEmpty) return null;
    return (hits.first['webformatURL'] ?? hits.first['largeImageURL']) as String?;
  }

  Future<String?> _openverse(String query) async {
    final uri = Uri.https('api.openverse.org', '/v1/images/', {'q': query, 'page_size': '3'});
    final res = await http.get(uri, headers: const {'User-Agent': 'DeutschiApp/1.0'});
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;
    return (results.first['url'] ?? results.first['thumbnail']) as String?;
  }

  Future<String?> _download(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    return _saveBytes(res.bodyBytes);
  }

  Future<String?> _saveBytes(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'word_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final file = File(p.join(imagesDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
