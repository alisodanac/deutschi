import 'package:flutter/material.dart';
import '../helpers/add_word_form_helper.dart';

class SentenceList extends StatelessWidget {
  final AddWordFormHelper helper;

  const SentenceList({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Sentences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle), onPressed: helper.addSentence),
          ],
        ),
        ...helper.sentenceControllers.asMap().entries.map((entry) {
          int idx = entry.key;
          TextEditingController controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(labelText: 'Sentence ${idx + 1}', border: const OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => helper.removeSentence(idx),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
