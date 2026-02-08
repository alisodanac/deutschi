import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Start your test here!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Future implementation: Start a test
              },
              child: const Text('Start Test'),
            ),
          ],
        ),
      ),
    );
  }
}
