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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Creative Header
              const Text('Let\'s Practice!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text('Select a mode to start your training.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 24),

              // Mode Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildModeCard(context, state, TestMode.intensive, 'Intensive', Icons.school, Colors.blue),
                  _buildModeCard(
                    context,
                    state,
                    TestMode.fast,
                    'Fast',
                    Icons.bolt_rounded, // Creative choice
                    Colors.orange,
                  ),
                  _buildModeCard(context, state, TestMode.spacedRepetition, 'SRS', Icons.event_repeat, Colors.purple),
                  _buildModeCard(context, state, TestMode.reverse, 'Reverse', Icons.swap_horiz, Colors.green),
                  _buildModeCard(context, state, TestMode.sentence, 'Sentence', Icons.edit_note, Colors.teal),
                ],
              ),

              const SizedBox(height: 32),

              // Category Filter
              const Text('Filter by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip(context, state, null, 'All'),
                    ...state.availableCategories.map((c) => _buildCategoryChip(context, state, c, c)),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Prominent Start Button
              ElevatedButton(
                onPressed: () {
                  context.read<TestCubit>().startTest(mode: state.selectedMode);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 4,
                ),
                child: const Text('Start Test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    TestSetup state,
    TestMode mode,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = state.selectedMode == mode;
    return Card(
      elevation: isSelected ? 4 : 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? color : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
      ),
      color: isSelected ? color.withOpacity(0.05) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<TestCubit>().updateSelection(mode: mode);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, TestSetup state, String? categoryValue, String label) {
    final isSelected = state.selectedCategory == categoryValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            context.read<TestCubit>().updateSelection(category: categoryValue);
          } else if (categoryValue != null && isSelected) {
            // If unselecting a specific category, revert to 'All' (null)
            context.read<TestCubit>().updateSelection(category: null);
          }
        },
        selectedColor: Colors.black,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        showCheckmark: false,
      ),
    );
  }
}
