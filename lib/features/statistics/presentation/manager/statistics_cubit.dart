import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repository/statistics_repository.dart';
import 'statistics_state.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  final StatisticsRepository repository;

  StatisticsCubit(this.repository) : super(StatisticsInitial());

  Future<void> loadStatistics() async {
    emit(StatisticsLoading());

    try {
      final overallStats = await repository.getOverallStats();
      final testHistory = await repository.getTestHistory();
      final allWordStats = await repository.getAllWordStats();

      final learnedWords = allWordStats.where((w) => w.isLearned).toList();
      final inProgressWords = allWordStats.where((w) => !w.isLearned).toList();

      emit(
        StatisticsLoaded(
          overallStats: overallStats,
          testHistory: testHistory,
          learnedWords: learnedWords,
          inProgressWords: inProgressWords,
        ),
      );
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }
}
