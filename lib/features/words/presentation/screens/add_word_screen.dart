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

class AddWordScreen extends StatelessWidget {
  const AddWordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (context) => sl<AddWordCubit>()..loadCategories(), child: const AddWordView());
  }
}

class AddWordView extends StatefulWidget {
  const AddWordView({super.key});

  @override
  State<AddWordView> createState() => _AddWordViewState();
}

class _AddWordViewState extends State<AddWordView> {
  late final AddWordFormHelper _helper;

  @override
  void initState() {
    super.initState();
    _helper = AddWordFormHelper();
  }

  @override
  void dispose() {
    _helper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Word')),
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
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Word added successfully!')));
            _helper.reset();
            context.read<AddWordCubit>().loadCategories();
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
                        return ElevatedButton(onPressed: () => _helper.submit(context), child: const Text('Save Word'));
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
