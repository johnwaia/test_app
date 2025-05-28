import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/app.dart'; // Adapte le chemin si nécessaire

void main() {
  testWidgets('UI initiale et comportement de base', (
    WidgetTester tester,
  ) async {
    // Lance l'application
    await tester.pumpWidget(const MyApp());

    // 1. Vérifie que la bulle d'intro est visible
    expect(
      find.text(
        "Cette application vous permet de consulter votre emploi du temps universitaire.",
      ),
      findsOneWidget,
    );

    // 2. Appuie sur la bulle d'intro pour la fermer
    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();

    // Vérifie que la bulle a disparu
    expect(
      find.text(
        "Cette application vous permet de consulter votre emploi du temps universitaire.",
      ),
      findsNothing,
    );

    // 3. Vérifie que le champ de texte est présent
    expect(find.byType(TextField), findsOneWidget);

    // 4. Tente de soumettre sans rien écrire
    await tester.tap(find.byType(TextField)); // Tap dans le champ
    await tester.testTextInput.receiveAction(
      TextInputAction.done,
    ); // Simule l'envoi
    await tester.pumpAndSettle();

    // Vérifie que le message d'erreur est affiché
    expect(
      find.text("Veuillez saisir un identifiant."),
      findsOneWidget,
    ); // Remplace si ton `emptyIdErrorText` est différent
  });
}
