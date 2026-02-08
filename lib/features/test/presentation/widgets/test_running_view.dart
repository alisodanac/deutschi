import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/test_mode.dart';
import '../manager/test_cubit.dart';
import '../manager/test_state.dart';
import '../../../words/domain/entities/word_type.dart';

class TestRunningView extends StatefulWidget {
  const TestRunningView({super.key});

  @override
  State<TestRunningView> createState() => _TestRunningViewState();
}

class _TestRunningViewState extends State<TestRunningView> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _articleController = TextEditingController();
  final TextEditingController _pluralController = TextEditingController();
  final TextEditingController _perfectController = TextEditingController();
  final TextEditingController _preteritController = TextEditingController();
  final TextEditingController _sentencesController = TextEditingController();

  String? _fastModeArticle;

  @override
  void dispose() {
    _wordController.dispose();
    _articleController.dispose();
    _pluralController.dispose();
    _perfectController.dispose();
    _preteritController.dispose();
    _sentencesController.dispose();
    super.dispose();
  }

  void _clearInputs() {
    _wordController.clear();
    _articleController.clear();
    _pluralController.clear();
    _perfectController.clear();
    _preteritController.clear();
    _sentencesController.clear();
    setState(() {
      _fastModeArticle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TestCubit, TestState>(
      listener: (context, state) {
        if (state is TestRunning && !state.isAnswerChecked && state.userInputs.isEmpty) {
          _clearInputs();
        }
      },
      builder: (context, state) {
        if (state is! TestRunning) return const SizedBox.shrink();

        final word = state.currentWord;
        final mode = state.mode;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress
              LinearProgressIndicator(value: (state.currentIndex) / state.words.length),
              const SizedBox(height: 8),
              Text('Word ${state.currentIndex + 1} / ${state.words.length}', textAlign: TextAlign.center),
              const SizedBox(height: 16),

              // Display: Image or Word
              if (state.isAnswerChecked && state.isAnswerCorrect && word.colorImagePath != null)
                _buildImage(word.colorImagePath!, isColor: true)
              else if (word.bwImagePath != null)
                _buildImage(word.bwImagePath!, isColor: false)
              else
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  color: Colors.grey[200],
                  child: Text(
                    mode == TestMode.intensive ? 'No Image Available' : 'Word: ???',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),

              const SizedBox(height: 24),

              // Mode Specific Inputs
              if (mode == TestMode.fast) ...[
                if (state.isAnswerChecked) _buildFeedback(context, state) else _buildFastModeInputs(context),
              ] else ...[
                if (word.bwImagePath == null)
                  Text(
                    'Translate: ${word.word}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 16),
                _buildIntensiveInputs(context, word),

                const SizedBox(height: 16),
                if (state.isAnswerChecked) _buildFeedback(context, state),
              ],

              const SizedBox(height: 24),

              // Action Button
              if (!state.isAnswerChecked)
                ElevatedButton(onPressed: () => _submitAnswer(context, mode), child: const Text('Check Answer'))
              else
                ElevatedButton(
                  onPressed: () => context.read<TestCubit>().nextWord(),
                  child: Text(state.isLastWord ? 'Finish Test' : 'Next Word'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String path, {required bool isColor}) {
    return SizedBox(
      height: 200,
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(child: Text('Image not found')),
      ),
    );
  }

  Widget _buildFastModeInputs(BuildContext context) {
    return Column(
      children: [
        const Text('Choose the Article:', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['Der', 'Die', 'Das'].map((article) {
            return Row(
              children: [
                Radio<String>(
                  value: article,
                  groupValue: _fastModeArticle,
                  onChanged: (value) {
                    setState(() {
                      _fastModeArticle = value;
                    });
                  },
                ),
                Text(article),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIntensiveInputs(BuildContext context, word) {
    // Determine required fields based on WordType
    final type = word.type;

    return Column(
      children: [
        if (type == WordType.noun) ...[
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _articleController,
                  decoration: const InputDecoration(labelText: 'Article'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _wordController,
                  decoration: const InputDecoration(labelText: 'Word'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pluralController,
            decoration: const InputDecoration(labelText: 'Plural Form'),
          ),
        ] else if (type == WordType.verb) ...[
          TextFormField(
            controller: _wordController,
            decoration: const InputDecoration(labelText: 'Verb'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _perfectController,
            decoration: const InputDecoration(labelText: 'Perfect Form'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _preteritController,
            decoration: const InputDecoration(labelText: 'Preterit Form'),
          ),
        ] else ...[
          TextFormField(
            controller: _wordController,
            decoration: const InputDecoration(labelText: 'Word'),
          ),
        ],

        const SizedBox(height: 16),
        TextFormField(
          controller: _sentencesController,
          decoration: const InputDecoration(labelText: 'Sentences (Optional Practice)'),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFeedback(BuildContext context, TestRunning state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: state.isAnswerCorrect ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: state.isAnswerCorrect ? Colors.green : Colors.red),
      ),
      child: Column(
        children: [
          Text(
            state.isAnswerCorrect ? 'Correct!' : 'Incorrect',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: state.isAnswerCorrect ? Colors.green[800] : Colors.red[800],
            ),
          ),
          if (!state.isAnswerCorrect) ...[
            const SizedBox(height: 8),
            const Text('Correct Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${state.currentWord.article ?? ""} ${state.currentWord.word}'),
            if (state.currentWord.plural != null) Text('Plural: ${state.currentWord.plural}'),
            if (state.currentWord.perfect != null) Text('Perfect: ${state.currentWord.perfect}'),
            if (state.currentWord.preterit != null) Text('Preterit: ${state.currentWord.preterit}'),
          ],
        ],
      ),
    );
  }

  void _submitAnswer(BuildContext context, TestMode mode) {
    if (mode == TestMode.fast) {
      if (_fastModeArticle == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an article')));
        return;
      }
      context.read<TestCubit>().checkAnswer({'fast_mode_article': _fastModeArticle!});
    } else {
      context.read<TestCubit>().checkAnswer({
        'word': _wordController.text,
        'article': _articleController.text,
        'plural': _pluralController.text,
        'perfect': _perfectController.text,
        'preterit': _preteritController.text,
        'sentences': _sentencesController.text,
      });
    }
  }
}
