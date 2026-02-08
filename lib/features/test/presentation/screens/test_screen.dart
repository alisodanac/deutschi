import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../manager/test_cubit.dart';
import '../manager/test_state.dart';
import '../widgets/test_setup_view.dart';
import '../widgets/test_running_view.dart';
import '../widgets/test_completed_view.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TestCubit>()..loadSetup(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Test Area')),
        body: BlocBuilder<TestCubit, TestState>(
          builder: (context, state) {
            if (state is TestLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TestSetup) {
              return const TestSetupView();
            } else if (state is TestRunning) {
              return const TestRunningView();
            } else if (state is TestCompleted) {
              return const TestCompletedView();
            } else if (state is TestFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => context.read<TestCubit>().loadSetup(), child: const Text('Retry')),
                  ],
                ),
              );
            }
            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }
}
