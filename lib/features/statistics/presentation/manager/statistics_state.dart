import 'package:equatable/equatable.dart';
import '../../domain/entities/test_result.dart';
import '../../domain/entities/word_stats.dart';
import '../../domain/repository/statistics_repository.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final OverallStats overallStats;
  final List<TestResult> testHistory;
  final List<WordStats> learnedWords;
  final List<WordStats> inProgressWords;

  const StatisticsLoaded({
    required this.overallStats,
    required this.testHistory,
    required this.learnedWords,
    required this.inProgressWords,
  });

  @override
  List<Object?> get props => [overallStats, testHistory, learnedWords, inProgressWords];
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object?> get props => [message];
}
