import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deutschi Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Deutschi!'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => context.go('/details'), child: const Text('Go to Details')),
          ],
        ),
      ),
    );
  }
}
