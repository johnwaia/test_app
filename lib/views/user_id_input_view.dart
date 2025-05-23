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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0077B6), // Bleu foncé
              Color(0xFF90E0EF), // Bleu clair
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo avec arrondi
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/Logo_Université_de_la_Nouvelle-Calédonie.jpg',
                    height: 160,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  "Bienvenue",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: userIdLabel,
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => onSubmit(),
                ),
                const SizedBox(height: 24),

                // Bouton blanc sur bleu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(submitButtonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
