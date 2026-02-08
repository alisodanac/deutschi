import 'package:equatable/equatable.dart';
import '../../../words/domain/entities/word.dart';

class WordStats extends Equatable {
  final Word word;
  final int totalAttempts;
  final int correctAttempts;

  const WordStats({required this.word, required this.totalAttempts, required this.correctAttempts});

  double get successRate => totalAttempts > 0 ? correctAttempts / totalAttempts : 0;

  /// A word is considered "learned" when:
  /// - At least 3 attempts have been made
  /// - Success rate is >= 80%
  bool get isLearned => totalAttempts >= 3 && successRate >= 0.8;

  @override
  List<Object?> get props => [word, totalAttempts, correctAttempts];
}
