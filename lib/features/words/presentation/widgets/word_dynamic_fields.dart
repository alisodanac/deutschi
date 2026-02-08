import 'package:flutter/material.dart';
import '../../domain/entities/word_type.dart';
import '../helpers/add_word_form_helper.dart';

class WordDynamicFields extends StatelessWidget {
  final AddWordFormHelper helper;

  const WordDynamicFields({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    if (helper.selectedType == WordType.noun) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: helper.selectedArticle,
                  decoration: const InputDecoration(labelText: 'Article', border: OutlineInputBorder()),
                  items: ['Der', 'Die', 'Das'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: helper.setArticle,
                  validator: (value) => value == null ? 'Please select an article' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: helper.wordController,
                  decoration: const InputDecoration(labelText: 'Word', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a word' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: helper.pluralController,
            decoration: const InputDecoration(labelText: 'Plural', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
        ],
      );
    } else {
      return Column(
        children: [
          TextFormField(
            controller: helper.wordController,
            decoration: const InputDecoration(labelText: 'Word', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Please enter a word' : null,
          ),
          const SizedBox(height: 16),
          if (helper.selectedType == WordType.verb) ...[
            TextFormField(
              controller: helper.perfectController,
              decoration: const InputDecoration(labelText: 'Perfect Form', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: helper.preteritController,
              decoration: const InputDecoration(labelText: 'Preterit Form', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
          ],
        ],
      );
    }
  }
}
