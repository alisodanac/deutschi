import 'package:equatable/equatable.dart';

class WordAttempt extends Equatable {
  final int? id;
  final int wordId;
  final int testResultId;
  final bool isCorrect;
  final DateTime timestamp;

  const WordAttempt({
    this.id,
    required this.wordId,
    required this.testResultId,
    required this.isCorrect,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word_id': wordId,
      'test_result_id': testResultId,
      'is_correct': isCorrect ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory WordAttempt.fromMap(Map<String, dynamic> map) {
    return WordAttempt(
      id: map['id'] as int?,
      wordId: map['word_id'] as int,
      testResultId: map['test_result_id'] as int,
      isCorrect: (map['is_correct'] as int) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  @override
  List<Object?> get props => [id, wordId, testResultId, isCorrect, timestamp];
}
