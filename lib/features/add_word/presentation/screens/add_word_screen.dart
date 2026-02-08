import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/word.dart';
import '../manager/add_word_cubit.dart';
import '../manager/add_word_state.dart';

class AddWordScreen extends StatelessWidget {
  const AddWordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (context) => sl<AddWordCubit>(), child: const AddWordView());
  }
}

class AddWordView extends StatefulWidget {
  const AddWordView({super.key});

  @override
  State<AddWordView> createState() => _AddWordViewState();
}

class _AddWordViewState extends State<AddWordView> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _categoryController = TextEditingController(); // Or dropdown later
  final List<TextEditingController> _sentenceControllers = [];

  String? _selectedArticle;
  String? _selectedType;
  File? _bwImage;
  File? _colorImage;

  final ImagePicker _picker = ImagePicker();

  void _addSentence() {
    setState(() {
      _sentenceControllers.add(TextEditingController());
    });
  }

  void _removeSentence(int index) {
    setState(() {
      _sentenceControllers[index].dispose();
      _sentenceControllers.removeAt(index);
    });
  }

  Future<void> _pickImage(bool isColor) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isColor) {
          _colorImage = File(image.path);
        } else {
          _bwImage = File(image.path);
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final word = Word(
        word: _wordController.text,
        article: _selectedArticle,
        type: _selectedType,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
        bwImagePath: _bwImage?.path,
        colorImagePath: _colorImage?.path,
      );

      final sentences = _sentenceControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList();

      context.read<AddWordCubit>().addWord(word, sentences);
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _categoryController.dispose();
    for (var c in _sentenceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Word')),
      body: BlocListener<AddWordCubit, AddWordState>(
        listener: (context, state) {
          if (state is AddWordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Word added successfully!')));
            // Reset form or navigate back?
            // For now, let's clear the form
            _wordController.clear();
            _categoryController.clear();
            setState(() {
              _selectedArticle = null;
              _selectedType = null;
              _bwImage = null;
              _colorImage = null;
              for (var c in _sentenceControllers) {
                c.clear();
              }
              // Keep sentences fields or remove them? Let's keep one empty one or reset list
              // Let's reset the list for a clean state
              for (var c in _sentenceControllers) {
                c.dispose();
              }
              _sentenceControllers.clear();
            });
          } else if (state is AddWordFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Word Input
                TextFormField(
                  controller: _wordController,
                  decoration: const InputDecoration(labelText: 'Word', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a word' : null,
                ),
                const SizedBox(height: 16),

                // Article Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedArticle,
                  decoration: const InputDecoration(labelText: 'Article', border: OutlineInputBorder()),
                  items: ['Der', 'Die', 'Das'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedArticle = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: ['Noun', 'Verb', 'Adjective', 'Adverb'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Category Input
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),

                // Images
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('BW Image'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickImage(false),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _bwImage != null
                                  ? Image.file(_bwImage!, fit: BoxFit.cover)
                                  : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Color Image'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickImage(true),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _colorImage != null
                                  ? Image.file(_colorImage!, fit: BoxFit.cover)
                                  : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sentences
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sentences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add_circle), onPressed: _addSentence),
                  ],
                ),
                ..._sentenceControllers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  TextEditingController controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Sentence ${idx + 1}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeSentence(idx),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 32),

                // Submit Button
                BlocBuilder<AddWordCubit, AddWordState>(
                  builder: (context, state) {
                    if (state is AddWordLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton(onPressed: _submit, child: const Text('Save Word'));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
