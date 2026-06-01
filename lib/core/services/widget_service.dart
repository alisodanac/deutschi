import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:home_widget/home_widget.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants.dart';
import '../../features/words/domain/entities/word_type.dart';
import '../../features/words/domain/use_cases/get_words_use_case.dart';

/// Fully-qualified name of the Android home-screen widget provider.
const String _androidWidgetName = 'com.alisodan.deutschi.GermanQuizWidget';

/// Builds the data for the interactive der/die/das home-screen widget.
///
/// Only nouns that have an article and an image are eligible (the quiz is about
/// articles). For each, a grayscale "prompt" image and a colored "reveal" image
/// are generated to files the native widget can read. The whole deck is stored
/// in widget preferences so the background tap callback can run without the DB.
class WidgetService {
  final GetWordsUseCase getWordsUseCase;

  WidgetService(this.getWordsUseCase);

  static const _maxDeck = 20;
  static const _articles = {'Der', 'Die', 'Das'};

  bool _refreshing = false;

  Future<void> init() async {
    await HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }

  Future<void> refresh() async {
    if (_refreshing) return; // avoid overlapping startup + add-word refreshes
    _refreshing = true;
    try {
      final words = await getWordsUseCase();
      final candidates = words
          .where(
            (w) =>
                w.type == WordType.noun &&
                w.article != null &&
                _articles.contains(w.article) &&
                (w.bwImagePath ?? w.colorImagePath) != null,
          )
          .toList()
        ..shuffle();

      final cacheDir = await _cacheDir();
      // Build the serializable job list on the main isolate (DB access only),
      // then do the heavy image work off the main isolate so the UI never janks.
      final jobs = candidates.take(_maxDeck).map((w) {
        return <String, dynamic>{
          'id': w.id,
          'word': w.word,
          'article': w.article,
          'source': w.bwImagePath ?? w.colorImagePath,
          'existingColor': w.colorImagePath,
          'colorArgb': AppColors.getArticleColor(w.article).toARGB32(),
          'cacheDir': cacheDir.path,
        };
      }).toList();

      final deck = jobs.isEmpty ? <Map<String, String>>[] : await Isolate.run(() => _buildDeckInIsolate(jobs));

      await HomeWidget.saveWidgetData<String>('deck', jsonEncode(deck));
      if (deck.isEmpty) {
        await _writeEmpty();
      } else {
        await _writeWord(0, deck, revealed: false);
      }
      await _update();
    } catch (_) {
      // Widget refresh is best-effort; never break app startup.
    } finally {
      _refreshing = false;
    }
  }

  Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'widget_cache'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _update() => HomeWidget.updateWidget(qualifiedAndroidName: _androidWidgetName);

  Future<void> _writeEmpty() async {
    await HomeWidget.saveWidgetData<String>('empty', 'true');
    await HomeWidget.saveWidgetData<String>('image', '');
    await HomeWidget.saveWidgetData<String>('word', '');
    await HomeWidget.saveWidgetData<String>('feedback', 'Add nouns with images in the app to start the quiz.');
    await HomeWidget.saveWidgetData<String>('feedback_color', '#9E9E9E');
    await HomeWidget.saveWidgetData<String>('revealed', 'false');
  }

  Future<void> _writeWord(int index, List<dynamic> deck, {required bool revealed}) async {
    final e = (deck[index] as Map).cast<String, dynamic>();
    await HomeWidget.saveWidgetData<String>('empty', 'false');
    await HomeWidget.saveWidgetData<String>('index', '$index');
    await HomeWidget.saveWidgetData<String>('revealed', revealed ? 'true' : 'false');
    await HomeWidget.saveWidgetData<String>('image', (revealed ? e['color'] : e['gray']) as String);
    await HomeWidget.saveWidgetData<String>('word', revealed ? e['word'] as String : '');
    await HomeWidget.saveWidgetData<String>('feedback', '');
    await HomeWidget.saveWidgetData<String>('feedback_color', '#FFFFFF');
  }
}

/// Runs in a background isolate: turns each word job into a grayscale prompt
/// file and a colored reveal file, reusing cached files when they are newer than
/// the source image. Returns the deck (word, article, gray path, color path).
List<Map<String, String>> _buildDeckInIsolate(List<Map<String, dynamic>> jobs) {
  final deck = <Map<String, String>>[];
  for (final job in jobs) {
    try {
      final sourcePath = job['source'] as String?;
      if (sourcePath == null) continue;
      final source = File(sourcePath);
      if (!source.existsSync()) continue;

      final id = job['id'];
      final cacheDir = job['cacheDir'] as String;
      final srcModified = source.statSync().modified;

      final grayPath = p.join(cacheDir, 'gray_$id.png');
      final grayFile = File(grayPath);
      final grayFresh = grayFile.existsSync() && grayFile.statSync().modified.isAfter(srcModified);

      // Prefer a real colored image (AI-generated / hand-made); else tint the
      // grayscale by the article color to match the in-app look.
      final existingColor = job['existingColor'] as String?;
      final useExistingColor = existingColor != null && File(existingColor).existsSync();
      final colorPath = useExistingColor ? existingColor : p.join(cacheDir, 'color_$id.png');
      final colorFile = File(colorPath);
      final colorFresh =
          useExistingColor || (colorFile.existsSync() && colorFile.statSync().modified.isAfter(srcModified));

      if (!grayFresh || !colorFresh) {
        final decoded = img.decodeImage(source.readAsBytesSync());
        if (decoded == null) continue;
        final gray = img.grayscale(img.copyResize(decoded, width: 360));
        if (!grayFresh) grayFile.writeAsBytesSync(img.encodePng(gray));
        if (!colorFresh) {
          colorFile.writeAsBytesSync(img.encodePng(_tintImage(gray, job['colorArgb'] as int)));
        }
      }

      deck.add({
        'word': job['word'] as String,
        'article': job['article'] as String,
        'gray': grayPath,
        'color': colorPath,
      });
    } catch (_) {
      // Skip any word that fails to process.
    }
  }
  return deck;
}

img.Image _tintImage(img.Image gray, int argb) {
  final cr = (argb >> 16) & 0xFF;
  final cg = (argb >> 8) & 0xFF;
  final cb = argb & 0xFF;
  final out = img.Image.from(gray);
  for (final px in out) {
    final l = px.r; // grayscale: r == g == b == luminance
    px.r = l * cr / 255;
    px.g = l * cg / 255;
    px.b = l * cb / 255;
  }
  return out;
}

String articleColorName(String article) {
  switch (article) {
    case 'Der':
      return 'blue';
    case 'Das':
      return 'yellow';
    case 'Die':
      return 'pink';
    default:
      return '';
  }
}

/// Background isolate callback for widget button taps. Uses only widget
/// preferences (no database), since the full deck was stored up front.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;
  final deckStr = await HomeWidget.getWidgetData<String>('deck');
  if (deckStr == null || deckStr.isEmpty) return;
  final deck = (jsonDecode(deckStr) as List);
  if (deck.isEmpty) return;

  var index = int.tryParse(await HomeWidget.getWidgetData<String>('index') ?? '0') ?? 0;
  if (index < 0 || index >= deck.length) index = 0;

  if (uri.host == 'answer') {
    final choice = uri.queryParameters['choice'];
    final entry = (deck[index] as Map).cast<String, dynamic>();
    final correct = entry['article'] as String;
    final isRight = choice == correct;
    final colorName = articleColorName(correct);

    await HomeWidget.saveWidgetData<String>('revealed', 'true');
    await HomeWidget.saveWidgetData<String>('image', entry['color'] as String);
    await HomeWidget.saveWidgetData<String>('word', entry['word'] as String);
    await HomeWidget.saveWidgetData<String>(
      'feedback',
      isRight ? 'Correct!  $correct ($colorName)' : "Wrong — it's $correct ($colorName)",
    );
    await HomeWidget.saveWidgetData<String>('feedback_color', isRight ? '#2E7D32' : '#C62828');
  } else if (uri.host == 'next') {
    int next = index;
    if (deck.length > 1) {
      final rand = Random();
      do {
        next = rand.nextInt(deck.length);
      } while (next == index);
    }
    final entry = (deck[next] as Map).cast<String, dynamic>();
    await HomeWidget.saveWidgetData<String>('index', '$next');
    await HomeWidget.saveWidgetData<String>('revealed', 'false');
    await HomeWidget.saveWidgetData<String>('image', entry['gray'] as String);
    await HomeWidget.saveWidgetData<String>('word', '');
    await HomeWidget.saveWidgetData<String>('feedback', '');
    await HomeWidget.saveWidgetData<String>('feedback_color', '#FFFFFF');
  }

  await HomeWidget.updateWidget(qualifiedAndroidName: _androidWidgetName);
}
