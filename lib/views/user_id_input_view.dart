import 'package:flutter/material.dart';
import '../constants/strings.dart';

class UserIdInputView extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String title;

  const UserIdInputView({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              userIdPrompt,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: userIdLabel,
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onSubmit,
              child: const Text(submitButtonText),
            ),
          ],
        ),
      ),
    );
  }
}
