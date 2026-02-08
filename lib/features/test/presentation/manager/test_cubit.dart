import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/test_mode.dart';
import 'test_state.dart';
import '../../../words/domain/entities/word.dart';
import '../../../words/domain/use_cases/get_categories_use_case.dart';
import '../../../words/domain/use_cases/get_words_use_case.dart';
import '../../../words/domain/use_cases/get_words_by_category_use_case.dart';
import '../../../words/domain/entities/word_type.dart';
import '../../../statistics/domain/repository/statistics_repository.dart';
import '../../../statistics/domain/entities/test_result.dart';
import '../../../statistics/domain/entities/word_attempt.dart';

class TestCubit extends Cubit<TestState> {
  final GetCategoriesUseCase getCategoriesUseCase;
  final GetWordsUseCase getWordsUseCase;
  final GetWordsByCategoryUseCase getWordsByCategoryUseCase;
  final StatisticsRepository statisticsRepository;

  // Track word attempts during test
  final List<_WordAttemptRecord> _wordAttempts = [];

  TestCubit(this.getCategoriesUseCase, this.getWordsUseCase, this.getWordsByCategoryUseCase, this.statisticsRepository)
    : super(TestInitial());

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
      if (setup.selectedCategory != null) {
        words = await getWordsByCategoryUseCase(setup.selectedCategory!);
      } else {
        words = await getWordsUseCase();
      }

      // Filter for Fast Mode: Nouns only, with B&W image
      if (setup.selectedMode == TestMode.fast) {
        words = words.where((w) => w.type == WordType.noun && w.bwImagePath != null).toList();
      }

      words.shuffle();

      if (words.isEmpty) {
        emit(const TestFailure('No words found for the selected criteria.'));
        return;
      }

      emit(
        TestRunning(
          words: words,
          currentIndex: 0,
          correctCount: 0,
          wrongCount: 0,
          isAnswerChecked: false,
          isAnswerCorrect: false,
          mode: setup.selectedMode,
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

    bool isCorrect = true;

    if (inputs.containsKey('fast_mode_article')) {
      // FAST MODE
      if (inputs['fast_mode_article'] != word.article) {
        isCorrect = false;
      }
    } else {
      // INTENSIVE MODE
      // Common: Word
      if (inputs['word']?.trim().toLowerCase() != word.word.toLowerCase()) {
        isCorrect = false;
      }

      if (word.type == WordType.noun) {
        if (inputs['article'] != word.article) isCorrect = false;
        if ((inputs['plural']?.trim().toLowerCase() ?? '') != (word.plural?.toLowerCase() ?? '')) isCorrect = false;
      } else if (word.type == WordType.verb) {
        if ((inputs['perfect']?.trim().toLowerCase() ?? '') != (word.perfect?.toLowerCase() ?? '')) isCorrect = false;
        if ((inputs['preterit']?.trim().toLowerCase() ?? '') != (word.preterit?.toLowerCase() ?? '')) isCorrect = false;
      }
      // Adjective only checks word (done above)
    }

    // Record this attempt
    if (word.id != null) {
      _wordAttempts.add(_WordAttemptRecord(wordId: word.id!, isCorrect: isCorrect));
    }

    emit(currentRunning.copyWith(isAnswerChecked: true, isAnswerCorrect: isCorrect, userInputs: inputs));
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
      emit(
        TestRunning(
          words: currentRunning.words,
          currentIndex: currentRunning.currentIndex + 1,
          correctCount: newCorrectCount,
          wrongCount: newWrongCount,
          isAnswerChecked: false,
          isAnswerCorrect: false,
          userInputs: const {},
          mode: currentRunning.mode,
        ),
      );
    }
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
