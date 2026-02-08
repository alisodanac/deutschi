import 'package:flutter/material.dart';
import '../../domain/entities/word_type.dart';
import '../helpers/add_word_form_helper.dart';

class WordTypeSelector extends StatelessWidget {
  final AddWordFormHelper helper;

  const WordTypeSelector({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<WordType>(
      value: helper.selectedType,
      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
      items: WordType.values.map((WordType value) {
        return DropdownMenuItem<WordType>(value: value, child: Text(value.toString()));
      }).toList(),
      onChanged: helper.setType,
      validator: (value) => value == null ? 'Please select a type' : null,
    );
  }
}
