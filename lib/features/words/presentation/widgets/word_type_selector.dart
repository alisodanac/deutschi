import 'package:flutter/material.dart';
import '../helpers/add_word_form_helper.dart';

class WordTypeSelector extends StatelessWidget {
  final AddWordFormHelper helper;

  const WordTypeSelector({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: helper.selectedType,
      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
      items: ['Noun', 'Verb', 'Adjective', 'Adverb'].map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: helper.setType,
      validator: (value) => value == null ? 'Please select a type' : null,
    );
  }
}
