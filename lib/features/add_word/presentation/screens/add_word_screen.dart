import 'package:flutter/material.dart';

class AddWordScreen extends StatelessWidget {
  const AddWordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Word')),
      body: const Center(child: Text('Form to add a new word will be here.')),
    );
  }
}
