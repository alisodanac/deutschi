import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('This is the Details Screen'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => context.go('/'), child: const Text('Back to Home')),
          ],
        ),
      ),
    );
  }
}
