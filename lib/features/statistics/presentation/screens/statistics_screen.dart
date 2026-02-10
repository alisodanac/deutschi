import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../manager/statistics_cubit.dart';
import '../manager/statistics_state.dart';
import '../../domain/entities/word_stats.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<StatisticsCubit>()..loadStatistics(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: BlocBuilder<StatisticsCubit, StatisticsState>(
          builder: (context, state) {
            if (state is StatisticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is StatisticsError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is StatisticsLoaded) {
              return _buildContent(context, state);
            }

            return const Center(child: Text('No statistics available'));
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StatisticsLoaded state) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => context.read<StatisticsCubit>().loadStatistics(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall Stats Card
          _buildOverallStatsCard(context, state),

          const SizedBox(height: 24),

          // Words Progress Section
          Text('Word Mastery', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildProgressBar(context, state),

          const SizedBox(height: 24),

          // Weak Words Section
          if (state.weakWords.isNotEmpty) ...[
            Text('Needs Practice', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
            ...state.weakWords.map((w) => _buildWordStatTile(context, w, isLearned: false)),
            const SizedBox(height: 24),
          ],

          // Learned Words
          if (state.learnedWords.isNotEmpty) ...[
            Text('Learned Words (${state.learnedWords.length})', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.learnedWords.map((w) => _buildWordStatTile(context, w, isLearned: true)),
            const SizedBox(height: 16),
          ],

          // In Progress Words
          if (state.inProgressWords.isNotEmpty) ...[
            Text('In Progress (${state.inProgressWords.length})', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.inProgressWords.map((w) => _buildWordStatTile(context, w, isLearned: false)),
            const SizedBox(height: 16),
          ],

          // Test History
          if (state.testHistory.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text('Recent Tests', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...state.testHistory.take(10).map((t) => _buildTestHistoryTile(context, t)),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallStatsCard(BuildContext context, StatisticsLoaded state) {
    final stats = state.overallStats;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Overall Progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (state.currentStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, size: 16, color: Colors.deepOrange),
                        const SizedBox(width: 4),
                        Text(
                          '${state.currentStreak} Day Streak',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, '${stats.totalTests}', 'Tests'),
                _buildStatItem(context, '${stats.totalAttempts}', 'Attempts'),
                _buildStatItem(context, '${(stats.overallAccuracy * 100).toStringAsFixed(0)}%', 'Accuracy'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, StatisticsLoaded state) {
    final learned = state.learnedWords.length;
    final inProgress = state.inProgressWords.length;
    final total = learned + inProgress;

    if (total == 0) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16), child: Text('Complete tests to see word progress')),
      );
    }

    final learnedPercent = learned / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$learned of $total words learned'),
                Text('${(learnedPercent * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: learnedPercent,
                minHeight: 12,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordStatTile(BuildContext context, WordStats stat, {required bool isLearned}) {
    final theme = Theme.of(context);
    final percentCorrect = (stat.successRate * 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLearned ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(isLearned ? Icons.check : Icons.pending, color: isLearned ? Colors.green : Colors.orange),
        ),
        title: Text(stat.word.word),
        subtitle: Text('${stat.correctAttempts}/${stat.totalAttempts} correct'),
        trailing: Text(
          '$percentCorrect%',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isLearned ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTestHistoryTile(BuildContext context, testResult) {
    final theme = Theme.of(context);
    final accuracy = (testResult.accuracy * 100).toStringAsFixed(0);
    final date = testResult.timestamp;
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.quiz, color: theme.colorScheme.primary),
        ),
        title: Text('${testResult.correctCount}/${testResult.totalWords} correct'),
        subtitle: Text('$formattedDate • ${testResult.mode ?? 'Test'}'),
        trailing: Text('$accuracy%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
