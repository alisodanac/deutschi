import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/test_mode.dart';
import '../manager/test_cubit.dart';
import '../manager/test_state.dart';

class TestSetupView extends StatelessWidget {
  const TestSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TestCubit, TestState>(
      builder: (context, state) {
        if (state is! TestSetup) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Choose Test Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Mode Selection
              SegmentedButton<TestMode>(
                segments: const [
                  ButtonSegment<TestMode>(
                    value: TestMode.intensive,
                    label: Text('Intensive'),
                    icon: Icon(Icons.school),
                  ),
                  ButtonSegment<TestMode>(value: TestMode.fast, label: Text('Fast'), icon: Icon(Icons.speed)),
                ],
                selected: {state.selectedMode},
                onSelectionChanged: (Set<TestMode> newSelection) {
                  context.read<TestCubit>().updateSelection(mode: newSelection.first);
                },
              ),
              const SizedBox(height: 24),

              const Text('Choose Category (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: state.selectedCategory,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'All Categories'),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('All Categories')),
                  ...state.availableCategories.map((category) {
                    return DropdownMenuItem<String>(value: category, child: Text(category));
                  }),
                ],
                onChanged: (value) {
                  context.read<TestCubit>().updateSelection(category: value);
                },
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  context.read<TestCubit>().startTest();
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Start Test', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }
}
