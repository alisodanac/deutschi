import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../features/words/domain/entities/word_type.dart';

/// Structured result returned by Gemini for a single German word.
class WordSuggestion {
  final WordType? type;
  final String? article; // 'Der' | 'Die' | 'Das'
  final String? plural;
  final String? perfect;
  final String? preterit;
  final String? category;
  final List<String> sentences;
  final String? imageQuery;

  const WordSuggestion({
    this.type,
    this.article,
    this.plural,
    this.perfect,
    this.preterit,
    this.category,
    this.sentences = const [],
    this.imageQuery,
  });
}

class GeminiService {
  static const _keyName = 'gemini_api_key';
  static const _model = 'gemini-2.5-flash';
  static const _endpoint = 'https://generativelanguage.googleapis.com/v1beta/models';

  final FlutterSecureStorage _storage;

  GeminiService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getApiKey() => _storage.read(key: _keyName);

  Future<void> setApiKey(String key) => _storage.write(key: _keyName, value: key.trim());

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Asks Gemini to describe a German word and returns the parsed suggestion.
  /// [existingCategories] are offered to the model so it reuses one when it fits.
  Future<WordSuggestion> generateWord(String word, {List<String> existingCategories = const []}) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No Gemini API key set. Add it in Settings > AI Assistant.');
    }

    final categoryHint = existingCategories.isEmpty
        ? 'Pick a concise German category name.'
        : 'Reuse one of these existing categories if it fits: ${existingCategories.join(', ')}. '
              'Otherwise pick a concise new German category name.';

    final prompt =
        'You are a German dictionary. For the German word "$word" return ONLY a JSON object '
        'with exactly these keys: '
        '"type" (one of "Noun","Verb","Adjective","Adverb"), '
        '"article" ("Der","Die" or "Das"; null if not a noun), '
        '"plural" (plural form without article; null if not a noun), '
        '"perfect" (perfect tense form e.g. "hat gemacht"; null if not a verb), '
        '"preterit" (preterit form; null if not a verb), '
        '"category" (a short German category name). $categoryHint '
        '"sentences" (an array of up to 4 short, simple example sentences in German using the word), '
        '"imageQuery" (a simple English keyword describing a representative, concrete picture of this word '
        'for an image search, e.g. "human head" for "Kopf"). '
        'Use correct German spelling and capitalization.';

    final uri = Uri.parse('$_endpoint/$_model:generateContent?key=$apiKey');
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'responseMimeType': 'application/json'},
    });

    final response = await _postWithRetry(uri, requestBody);

    if (response.statusCode != 200) {
      throw Exception(_friendlyError(response.statusCode, response.body));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no result. Try again.');
    }
    final parts = (candidates.first['content']?['parts']) as List<dynamic>?;
    final text = parts?.map((p) => p['text']).whereType<String>().join() ?? '';
    if (text.isEmpty) {
      throw Exception('Gemini returned an empty response. Try again.');
    }

    return _parse(text);
  }

  // Retries on 503 (model overloaded), which is transient and common on the
  // free tier during demand spikes.
  Future<http.Response> _postWithRetry(Uri uri, String body) async {
    const maxAttempts = 4;
    http.Response response = await _post(uri, body);
    var attempt = 1;
    while (response.statusCode == 503 && attempt < maxAttempts) {
      await Future.delayed(Duration(milliseconds: 600 * (1 << (attempt - 1))));
      response = await _post(uri, body);
      attempt++;
    }
    return response;
  }

  Future<http.Response> _post(Uri uri, String body) {
    return http.post(uri, headers: const {'Content-Type': 'application/json'}, body: body);
  }

  WordSuggestion _parse(String jsonText) {
    final data = jsonDecode(jsonText) as Map<String, dynamic>;

    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty || s.toLowerCase() == 'null' ? null : s;
    }

    final sentences = <String>[];
    final rawSentences = data['sentences'];
    if (rawSentences is List) {
      for (final s in rawSentences) {
        final value = str(s);
        if (value != null) sentences.add(value);
      }
    }

    return WordSuggestion(
      type: WordType.fromString(str(data['type'])),
      article: _normalizeArticle(str(data['article'])),
      plural: str(data['plural']),
      perfect: str(data['perfect']),
      preterit: str(data['preterit']),
      category: str(data['category']),
      sentences: sentences.take(4).toList(),
      imageQuery: str(data['imageQuery']),
    );
  }

  String? _normalizeArticle(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase()) {
      case 'der':
        return 'Der';
      case 'die':
        return 'Die';
      case 'das':
        return 'Das';
      default:
        return null;
    }
  }

  String _friendlyError(int status, String body) {
    if (status == 503) {
      return 'Gemini is busy right now (high demand). Please try again in a moment.';
    }
    if (status == 429) {
      return 'Gemini quota exceeded for the free tier. Try again in a moment.';
    }
    if (status == 400 || status == 403) {
      return 'Gemini rejected the request — check that your API key is valid.';
    }
    return 'Gemini request failed ($status).';
  }
}
