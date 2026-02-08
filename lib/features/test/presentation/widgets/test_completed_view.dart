import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../manager/test_cubit.dart';
import '../manager/test_state.dart';

class TestCompletedView extends StatelessWidget {
  const TestCompletedView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TestCubit, TestState>(
      builder: (context, state) {
        if (state is! TestCompleted) return const SizedBox.shrink();

        final percentage = (state.correctCount / state.totalWords) * 100;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Test Completed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                  child: Column(
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Text('Score', style: TextStyle(fontSize: 16, color: Colors.blue[800])),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Correct: ${state.correctCount}', style: const TextStyle(fontSize: 18, color: Colors.green)),
                const SizedBox(height: 8),
                Text('Wrong: ${state.wrongCount}', style: const TextStyle(fontSize: 18, color: Colors.red)),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Go back to setup handling is implicitly done by restart calling loadSetup
                        context.read<TestCubit>().restart();
                      },
                      child: const Text('Back to Setup'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        // To restart with same settings we'd need to store them.
                        // For now just back to setup.
                        context.read<TestCubit>().restart();
                      },
                      child: const Text('Play Again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
