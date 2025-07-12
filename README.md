# 📅 Emploi du Temps UNC

**Application mobile Flutter** pour les étudiants de l’Université de la Nouvelle-Calédonie (UNC) :  
Consultez votre emploi du temps personnalisé, organisez des réunions entre étudiants et accédez à toutes les informations de vos cours, où que vous soyez.

---

## 🚀 Fonctionnalités principales

- 🧑‍🎓 **Connexion rapide** : Saisie de l'identifiant étudiant à l'ouverture.
- 🗓️ **Emploi du temps personnalisé** : Affichage clair par semaine, navigation entre semaines, tri automatique par jour.
- 🏫 **Détails complets** : Intitulé, salle, enseignant, horaires, type de cours.
- 🤝 **Organisation de réunions** : Trouvez facilement les créneaux communs libres entre plusieurs étudiants.
- 🇫🇷 **Interface 100% française** : Dates et heures au format local, gestion du fuseau horaire (Nouméa).
- 📱 **Design moderne** : Navigation fluide, cartes colorées, expérience utilisateur optimisée mobile.

---

## 📸 Aperçu de l’application

<p align="center">
  <img src="assets/screenshots/logo_application_smartphone[1].jpg" alt="page acceuil" width="200" hspace="10"/>
  <img src="assets/screenshots/page_acceuil.jpg" alt="page acceuil" width="200" hspace="10"/>
  <img src="assets/screenshots/affichage_cours.jpg" alt="cours" width="200" hspace="10"/>
  <img src="assets/screenshots/détails_cours.jpg" alt="détails des cours" width="200" hspace="10"/>
  <img src="assets/screenshots/menu.jpg" alt="Détail événement" width="200" hspace="10"/>
  <img src="assets/screenshots/organiser_des_réunions.jpg" alt="Organiser réunion" width="200" hspace="10"/>
  <img src="assets/screenshots/groupe_étudiant.jpg" alt="nombre membre du groupe" width="200" hspace="10"/>
  <img src="assets/screenshots/Affichage_des_créneaux.jpg" alt="Créneaux communs" width="200" hspace="10"/>
  <img src="assets/screenshots/Affichage_creation_personnal_events.jpg" alt="nombre membre du groupe" width="200" hspace="10"/>
  <img src="assets/screenshots/test_creation_personnal event.jpg" alt="nombre membre du groupe" width="200" hspace="10"/>
  <img src="assets/screenshots/Affichage_personnal_event.jpg" alt="nombre membre du groupe" width="200" hspace="10"/>
  <img src="assets/screenshots/Affichage_details_personnal_event.jpg" alt="nombre membre du groupe" width="200"/>
</p>

> **Astuce :** Ajoutez vos propres captures d’écran dans `assets/screenshots/` pour illustrer les dernières fonctionnalités.

---

## 📦 Prérequis

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- IDE recommandé :
  - [Android Studio](https://developer.android.com/studio) (avec un émulateur Android/iOS)
  - ou [Visual Studio Code](https://code.visualstudio.com/) (avec un appareil physique en mode développeur)
- Connexion Internet active (pour récupérer les emplois du temps)

---

## 🛠️ Dépendances principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.5
  intl: ^0.18.1
  timezone: ^0.9.1
  collection: ^1.17.1
```

---

## 📁 Structure du projet

- `main.dart` – Point d’entrée de l’application.
- `app.dart` – Initialisation générale et navigation.
- `views/user_id_input_view.dart` – Vue de connexion (identifiant étudiant).
- `views/home_page.dart` – Vue principale (emploi du temps).
- `views/MeetingOrganizerView.dart` – Organisation de réunions et recherche de créneaux communs.
- `models/ics_event.dart` – Modèle de représentation des événements.
- `services/schedule_service.dart` – Récupération et parsing des données `.ics`.
- `widgets/drawer_menu.dart` – Menu latéral de navigation.
- `constants/strings.dart` – Constantes et textes de l’interface.

---

## ⚙️ Lancer le projet

1. **Cloner le dépôt** :
   ```bash
   git clone https://github.com/johnwaia/test_app.git
   ```
2. **Se rendre dans le répertoire** :
   ```bash
   cd test_app
   ```
3. **Installer les dépendances** :
   ```bash
   flutter pub get
   ```
4. **Vérifier la configuration de l’environnement** :
   ```bash
   flutter doctor
   ```
5. **Exécuter l’application** :
   ```bash
   flutter run
   ```

---

## 💡 Notes techniques

- Les événements sont extraits dynamiquement depuis un fichier `.ics` associé à l’identifiant étudiant.
- Le fuseau horaire utilisé est `Pacific/Noumea` pour correspondre à l’heure locale.
- L’application nécessite une connexion Internet active pour fonctionner.
- Le logo UNC s’affiche en grand lors du lancement de l’application (SplashScreen).

---

## 📄 Licence

Projet développé dans un cadre pédagogique à l’UNC.  
Licence à définir selon l’usage (ex. : MIT, GPL, etc.).

---
