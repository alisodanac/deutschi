import 'package:equatable/equatable.dart';
import '../../domain/entities/test_mode.dart';
import '../../../words/domain/entities/word.dart';

abstract class TestState extends Equatable {
  const TestState();

  @override
  List<Object?> get props => [];
}

class TestInitial extends TestState {}

class TestSetup extends TestState {
  final TestMode selectedMode;
  final String? selectedCategory;
  final List<String> availableCategories;

  const TestSetup({this.selectedMode = TestMode.intensive, this.selectedCategory, this.availableCategories = const []});

  TestSetup copyWith({TestMode? selectedMode, String? selectedCategory, List<String>? availableCategories}) {
    return TestSetup(
      selectedMode: selectedMode ?? this.selectedMode,
      selectedCategory: selectedCategory, // Allow null to reset
      availableCategories: availableCategories ?? this.availableCategories,
    );
  }

  @override
  List<Object?> get props => [selectedMode, selectedCategory, availableCategories];
}

class TestLoading extends TestState {}

class TestRunning extends TestState {
  final List<Word> words;
  final int currentIndex;
  final int correctCount;
  final int wrongCount;
  final bool isAnswerChecked;
  final bool isAnswerCorrect;
  final Map<String, String> userInputs; // Key: field name, Value: input
  final TestMode mode;
  final List<String> currentOptions; // For Reverse Mode
  final String? sentenceContext; // For Sentence Mode (with blank)

  Word get currentWord => words[currentIndex];
  bool get isLastWord => currentIndex == words.length - 1;

  const TestRunning({
    required this.words,
    this.currentIndex = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.isAnswerChecked = false,
    this.isAnswerCorrect = false,
    this.userInputs = const {},
    required this.mode,
    this.currentOptions = const [],
    this.sentenceContext,
  });

  TestRunning copyWith({
    List<Word>? words,
    int? currentIndex,
    int? correctCount,
    int? wrongCount,
    bool? isAnswerChecked,
    bool? isAnswerCorrect,
    Map<String, String>? userInputs,
    TestMode? mode,
    List<String>? currentOptions,
    String? sentenceContext,
  }) {
    return TestRunning(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      isAnswerChecked: isAnswerChecked ?? this.isAnswerChecked,
      isAnswerCorrect: isAnswerCorrect ?? this.isAnswerCorrect,
      userInputs: userInputs ?? this.userInputs,
      mode: mode ?? this.mode,
      currentOptions: currentOptions ?? this.currentOptions,
      sentenceContext: sentenceContext ?? this.sentenceContext,
    );
  }

  @override
  List<Object?> get props => [
    words,
    currentIndex,
    correctCount,
    wrongCount,
    isAnswerChecked,
    isAnswerCorrect,
    userInputs,
    mode,
    currentOptions,
    sentenceContext,
  ];
}

class TestCompleted extends TestState {
  final int totalWords;
  final int correctCount;
  final int wrongCount;

  const TestCompleted({required this.totalWords, required this.correctCount, required this.wrongCount});

  @override
  List<Object?> get props => [totalWords, correctCount, wrongCount];
}

class TestFailure extends TestState {
  final String message;

  const TestFailure(this.message);

  @override
  List<Object?> get props => [message];
}
