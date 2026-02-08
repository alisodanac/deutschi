import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../manager/add_word_cubit.dart';
import '../manager/add_word_state.dart';
import '../helpers/add_word_form_helper.dart';
import '../widgets/word_type_selector.dart';
import '../widgets/word_dynamic_fields.dart';
import '../widgets/category_autocomplete.dart';
import '../widgets/image_picker_section.dart';
import '../widgets/sentence_list.dart';
import '../../../../features/ai_chat/presentation/manager/ai_chat_cubit.dart';
import '../../../../features/ai_chat/presentation/screens/ai_chat_screen.dart';
import '../../domain/entities/word.dart';

class AddWordScreen extends StatelessWidget {
  final Word? initialWord;
  final List<String>? initialSentences;

  const AddWordScreen({super.key, this.initialWord, this.initialSentences});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AddWordCubit>()..loadCategories(),
      child: AddWordView(initialWord: initialWord, initialSentences: initialSentences),
    );
  }
}

class AddWordView extends StatefulWidget {
  final Word? initialWord;
  final List<String>? initialSentences;

  const AddWordView({super.key, this.initialWord, this.initialSentences});

  @override
  State<AddWordView> createState() => _AddWordViewState();
}

class _AddWordViewState extends State<AddWordView> {
  late final AddWordFormHelper _helper;

  @override
  void initState() {
    super.initState();
    _helper = AddWordFormHelper();
    if (widget.initialWord != null) {
      _helper.initialize(widget.initialWord!, widget.initialSentences ?? []);
    }
  }

  @override
  void dispose() {
    _helper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialWord != null ? 'Edit Word' : 'Add New Word')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => AIChatCubit(),
                child: AIChatScreen(initialPrompt: _helper.wordController.text),
              ),
            ),
          );
        },
        child: const Icon(Icons.smart_toy_outlined),
        tooltip: 'AI Assistant',
      ),

      body: BlocListener<AddWordCubit, AddWordState>(
        listener: (context, state) {
          if (state is AddWordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.initialWord != null ? 'Word updated successfully!' : 'Word added successfully!'),
              ),
            );
            if (widget.initialWord != null) {
              Navigator.pop(context, true); // Return true to indicate update
            } else {
              _helper.reset();
              context.read<AddWordCubit>().loadCategories();
            }
          } else if (state is AddWordFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ListenableBuilder(
            listenable: _helper,
            builder: (context, _) {
              return Form(
                key: _helper.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WordTypeSelector(helper: _helper),
                    const SizedBox(height: 16),
                    WordDynamicFields(helper: _helper),
                    CategoryAutocomplete(helper: _helper),
                    const SizedBox(height: 24),
                    ImagePickerSection(helper: _helper),
                    const SizedBox(height: 24),
                    SentenceList(helper: _helper),
                    const SizedBox(height: 32),
                    BlocBuilder<AddWordCubit, AddWordState>(
                      builder: (context, state) {
                        if (state is AddWordLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return ElevatedButton(
                          onPressed: () => _helper.submit(context),
                          child: Text(widget.initialWord != null ? 'Update Word' : 'Save Word'),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
