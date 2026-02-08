import 'package:equatable/equatable.dart';

class TestResult extends Equatable {
  final int? id;
  final DateTime timestamp;
  final String? mode;
  final String? category;
  final int totalWords;
  final int correctCount;
  final int wrongCount;

  const TestResult({
    this.id,
    required this.timestamp,
    this.mode,
    this.category,
    required this.totalWords,
    required this.correctCount,
    required this.wrongCount,
  });

  double get accuracy => totalWords > 0 ? correctCount / totalWords : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'mode': mode,
      'category': category,
      'total_words': totalWords,
      'correct_count': correctCount,
      'wrong_count': wrongCount,
    };
  }

  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      mode: map['mode'] as String?,
      category: map['category'] as String?,
      totalWords: map['total_words'] as int,
      correctCount: map['correct_count'] as int,
      wrongCount: map['wrong_count'] as int,
    );
  }

  @override
  List<Object?> get props => [id, timestamp, mode, category, totalWords, correctCount, wrongCount];
}
