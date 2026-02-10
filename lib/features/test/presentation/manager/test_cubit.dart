import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/test_mode.dart';
import 'test_state.dart';
import '../../../words/domain/entities/word.dart';
import '../../../words/domain/use_cases/get_categories_use_case.dart';
import '../../../words/domain/use_cases/get_words_use_case.dart';
import '../../../words/domain/use_cases/get_words_by_category_use_case.dart';
import '../../../words/domain/entities/word_type.dart';
import '../../../words/domain/repository/word_repository.dart';
import '../../../statistics/domain/repository/statistics_repository.dart';
import '../../../statistics/domain/entities/test_result.dart';
import '../../../statistics/domain/entities/word_attempt.dart';
import '../../../../core/utils/srs_algo.dart';

class TestCubit extends Cubit<TestState> {
  final GetCategoriesUseCase getCategoriesUseCase;
  final GetWordsUseCase getWordsUseCase;
  final GetWordsByCategoryUseCase getWordsByCategoryUseCase;
  final StatisticsRepository statisticsRepository;
  final WordRepository wordRepository;

  // Track word attempts during test
  final List<_WordAttemptRecord> _wordAttempts = [];

  TestCubit(
    this.getCategoriesUseCase,
    this.getWordsUseCase,
    this.getWordsByCategoryUseCase,
    this.statisticsRepository,
    this.wordRepository,
  ) : super(TestInitial());

  Future<void> loadSetup() async {
    _wordAttempts.clear();
    try {
      final categories = await getCategoriesUseCase();
      emit(TestSetup(availableCategories: categories));
    } catch (e) {
      emit(TestFailure(e.toString()));
    }
  }

  void updateSelection({TestMode? mode, String? category}) {
    if (state is TestSetup) {
      final currentState = state as TestSetup;
      emit(currentState.copyWith(selectedMode: mode, selectedCategory: category));
    }
  }

  Future<void> startTest({TestMode mode = TestMode.intensive}) async {
    if (state is! TestSetup) return;
    final setup = state as TestSetup;

    _wordAttempts.clear();
    emit(TestLoading());
    try {
      List<Word> words;
      if (setup.selectedMode == TestMode.spacedRepetition) {
        // Load due words for SRS
        // We'll need a new UseCase for this, but for now let's assume we can get them or add it to existing repo
        // For simplicity, let's inject the repo directly or add a method to existing use case?
        // Let's assume we add getDueWords to repository and use it here.
        // Ideally we should have a GetDueWordsUseCase.
        // Since I haven't created that yet, I'll access repo directly if possible or mock it.
        // Wait, I can't access repo directly easily if it's not injected.
        // Let's modify the constructor to take the repo or a new use case.
        // For now, I'll just use getWords() and filter in memory as a fallback if I can't update constructor right now.
        // ACTUALLY, I should update the constructor to inject GetDueWordsUseCase.
        // But to avoid too many file changes, let's use getWords() and filter for now?
        // No, that's inefficient.
        // Let's update the constructor.
        // But wait, I need to update Dependency Injection too.
        // Let's assume for this step I will update DI in next step.
        // Let's add the repo to constructor.
        // Oh wait, StatisticsRepository is there. I need WordRepository.
        // It's not in the constructor currently. UseCases are used.
        // Let's add WordRepository to constructor.
      }

      if (setup.selectedCategory != null) {
        words = await getWordsByCategoryUseCase(setup.selectedCategory!);
      } else {
        words = await getWordsUseCase();
      }

      // Filter for Spaced Repetition
      if (setup.selectedMode == TestMode.spacedRepetition) {
        final now = DateTime.now().millisecondsSinceEpoch;
        // Filter words that are due or new (never reviewed)
        words = words.where((w) => w.nextReview <= now || w.nextReview == 0).toList();
        // Sort by due date (ascending)
        words.sort((a, b) => a.nextReview.compareTo(b.nextReview));
        // Take top 20?
        if (words.length > 20) words = words.sublist(0, 20);
      }

      // Filter for Fast Mode: Nouns only, with B&W image
      if (setup.selectedMode == TestMode.fast) {
        words = words.where((w) => w.type == WordType.noun && w.bwImagePath != null).toList();
      }

      // Filter for Sentence Mode: Must have sentences (loaded separately?)
      // UseCase getWordsUseCase usually returns words.
      // Do words have sentences loaded? Entity has `List<String>? sentences` but it's usually in a separate table/query.
      // WordEntity has `sentences` field? Let's check Word entity.
      // Assuming Word entity has sentences or we need to load them.
      // If sentences are not loaded by getWords, we might have a problem.
      // Let's assume for now they are NOT loaded by default if it's a join.
      // I need to check `WordLocalDataSource`.
      // If they are not loaded, I need to load them for the selected words.
      // Loading sentences for ALL words might be slow.
      // Maybe load sentences for just the 10-20 words we pick?

      // Let's shuffle first.
      words.shuffle();

      // For Sentence Mode, we need words with sentences.
      // If we don't have sentences loaded, we need to load them.
      // Since I can't easily check without looking at data source, let's assume I need to load them.
      // But `Word` entity definition:
      // final List<String>? sentences;
      // If it's null/empty, we can't use it.

      // OPTIMIZATION: Take top 20 words, then load sentences for them?
      // But we need to filter words that HAVE sentences.
      // If data source doesn't load sentences, list is empty?
      // Let's assume we proceed with whatever we have.
      // If Sentence mode selected:
      if (setup.selectedMode == TestMode.sentence) {
        // This is tricky if sentences aren't loaded.
        // Let's assume they are NOT loaded by default to save performance.
        // So I should try to load sentences for a subset of words or look for words that have stored sentences.
        // Given I don't have "getWordsWithSentences", I might need to skip this for now or just try to load for the first X words.

        // Temporary strategy: Take top 50 shuffled words. Load details (sentences) for them. Keep those with sentences.
        final candidates = words.take(50).toList();
        final validWords = <Word>[];

        // Use existing repository method to get sentences if exposed?
        // Repository has `getSentencesForWord(id)`.
        // I need to use it. `wordRepository.getSentencesForWord`.

        for (final w in candidates) {
          if (w.id == null) continue;
          final sentences = await wordRepository.getSentencesForWord(w.id!);
          if (sentences.isNotEmpty) {
            validWords.add(w.copyWith(sentences: sentences));
          }
          if (validWords.length >= 10) break; // Enough for a test
        }
        words = validWords;
      }

      if (words.isEmpty) {
        emit(const TestFailure('No suitable words found for the selected mode.'));
        return;
      }

      // Prepare first word state
      final firstWord = words[0];
      final options = _generateOptions(firstWord, words);
      final sentenceContext = _generateSentenceContext(firstWord, setup.selectedMode);

      emit(
        TestRunning(
          words: words,
          currentIndex: 0,
          correctCount: 0,
          wrongCount: 0,
          isAnswerChecked: false,
          isAnswerCorrect: false,
          mode: setup.selectedMode,
          currentOptions: options,
          sentenceContext: sentenceContext,
        ),
      );
    } catch (e) {
      emit(TestFailure(e.toString()));
    }
  }

  void checkAnswer(Map<String, String> inputs) {
    if (state is! TestRunning) return;
    final currentRunning = state as TestRunning;
    final word = currentRunning.currentWord;
    final mode = currentRunning.mode;

    bool isCorrect = true;

    if (mode == TestMode.fast) {
      if (inputs['fast_mode_article'] != word.article) isCorrect = false;
    } else if (mode == TestMode.reverse) {
      if (inputs['selected_option'] != word.word) isCorrect = false;
    } else if (mode == TestMode.sentence) {
      if (inputs['word']?.trim().toLowerCase() != word.word.toLowerCase()) isCorrect = false;
    } else {
      // Intensive / SRS
      if (inputs['word']?.trim().toLowerCase() != word.word.toLowerCase()) isCorrect = false;
      if (word.type == WordType.noun) {
        if (inputs['article'] != word.article) isCorrect = false;
        if ((inputs['plural']?.trim().toLowerCase() ?? '') != (word.plural?.toLowerCase() ?? '')) isCorrect = false;
      } else if (word.type == WordType.verb) {
        if ((inputs['perfect']?.trim().toLowerCase() ?? '') != (word.perfect?.toLowerCase() ?? '')) isCorrect = false;
        if ((inputs['preterit']?.trim().toLowerCase() ?? '') != (word.preterit?.toLowerCase() ?? '')) isCorrect = false;
      }
    }

    // Record this attempt
    if (word.id != null) {
      _wordAttempts.add(_WordAttemptRecord(wordId: word.id!, isCorrect: isCorrect));
      // Update SRS Stats
      _updateWordStats(word, isCorrect);
    }

    emit(currentRunning.copyWith(isAnswerChecked: true, isAnswerCorrect: isCorrect, userInputs: inputs));
  }

  // Helper to update SRS stats
  Future<void> _updateWordStats(Word word, bool isCorrect) async {
    // 1. Calculate Quality (0-5)
    final quality = isCorrect ? 5 : 0;

    // 2. Run SM-2 Algo
    final result = SRSAlgo.calculateNextReview(
      currentInterval: word.srsInterval,
      currentEaseFactor: word.easeFactor,
      quality: quality,
    );

    // 3. Update Mastery Level
    int newMastery = word.masteryLevel;
    if (isCorrect) {
      if (newMastery < 5) newMastery++;
    } else {
      if (newMastery > 0) newMastery--;
    }

    // 4. Update Streak
    int newStreak = word.streak;
    if (isCorrect)
      newStreak++;
    else
      newStreak = 0;

    // 5. Create updated word
    final updatedWord = word.copyWith(
      srsInterval: result.newInterval,
      easeFactor: result.newEaseFactor,
      nextReview: SRSAlgo.getNextReviewTimestamp(result.newInterval),
      lastReview: DateTime.now().millisecondsSinceEpoch,
      masteryLevel: newMastery,
      streak: newStreak,
    );

    // 6. Save to Repo
    await wordRepository.updateWordStats(updatedWord);
  }

  void nextWord() {
    if (state is! TestRunning) return;
    final currentRunning = state as TestRunning;

    // Update counts based on CURRENT answer status
    final newCorrectCount = currentRunning.correctCount + (currentRunning.isAnswerCorrect ? 1 : 0);
    final newWrongCount = currentRunning.wrongCount + (currentRunning.isAnswerCorrect ? 0 : 1);

    if (currentRunning.isLastWord) {
      _saveTestResults(
        TestCompleted(
          totalWords: currentRunning.words.length,
          correctCount: newCorrectCount,
          wrongCount: newWrongCount,
        ),
        currentRunning.mode,
      );
    } else {
      final nextIndex = currentRunning.currentIndex + 1;
      final nextWord = currentRunning.words[nextIndex];

      final options = _generateOptions(nextWord, currentRunning.words);
      final sentenceContext = _generateSentenceContext(nextWord, currentRunning.mode);

      emit(
        currentRunning.copyWith(
          currentIndex: nextIndex,
          correctCount: newCorrectCount,
          wrongCount: newWrongCount,
          isAnswerChecked: false,
          isAnswerCorrect: false,
          userInputs: const {},
          currentOptions: options,
          sentenceContext: sentenceContext,
        ),
      );
    }
  }

  List<String> _generateOptions(Word correctWord, List<Word> allWords) {
    if (allWords.length < 3) return allWords.map((w) => w.word).toList();

    final options = <String>{correctWord.word};
    // final random = DateTime.now().millisecondsSinceEpoch; // Unused

    // Simple random selection
    List<Word> shuffled = List.from(allWords)..shuffle();
    for (final w in shuffled) {
      if (w.word != correctWord.word) {
        options.add(w.word);
        if (options.length >= 3) break; // 3 Options? Or 4? Let's say 4. No, plan said 3.
      }
    }

    final result = options.toList();
    result.shuffle();
    return result;
  }

  String? _generateSentenceContext(Word word, TestMode mode) {
    if (mode != TestMode.sentence) return null;
    if (word.sentences == null || word.sentences!.isEmpty) return null;

    // Pick first sentence for now, or random
    final sentence = word.sentences!.first;
    // Replace word with blank. Case insensitive replace.
    final pattern = RegExp(RegExp.escape(word.word), caseSensitive: false);
    return sentence.replaceAll(pattern, '_______');
  }

  Future<void> _saveTestResults(TestCompleted completed, TestMode? mode) async {
    emit(completed);

    try {
      final testResult = TestResult(
        timestamp: DateTime.now(),
        mode: mode?.name,
        totalWords: completed.totalWords,
        correctCount: completed.correctCount,
        wrongCount: completed.wrongCount,
      );

      final testResultId = await statisticsRepository.saveTestResult(testResult);

      for (final attempt in _wordAttempts) {
        final wordAttempt = WordAttempt(
          wordId: attempt.wordId,
          testResultId: testResultId,
          isCorrect: attempt.isCorrect,
          timestamp: DateTime.now(),
        );
        await statisticsRepository.saveWordAttempt(wordAttempt);
      }
    } catch (e) {
      // Log error but don't interrupt completion
    }
  }

  void restart() {
    loadSetup();
  }
}

class _WordAttemptRecord {
  final int wordId;
  final bool isCorrect;

  _WordAttemptRecord({required this.wordId, required this.isCorrect});
}
