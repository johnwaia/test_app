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
Voici une version nettement améliorée de ta section **"📸 Aperçu de l’application"**, avec :

---

## 📸 Aperçu de l’application

<div align="center">

<img src="assets/screenshots/logo_application_smartphone.jpg" alt="Logo de l'application" width="200" style="margin: 10px;" />
<img src="assets/screenshots/page_acceuil.jpg" alt="Page d'accueil" width="200" style="margin: 10px;" />
<img src="assets/screenshots/affichage_cours.jpg" alt="Affichage des cours" width="200" style="margin: 10px;" />
<img src="assets/screenshots/détails_cours.jpg" alt="Détails d’un cours" width="200" style="margin: 10px;" />
<img src="assets/screenshots/menu.jpg" alt="Menu latéral" width="200" style="margin: 10px;" />
<img src="assets/screenshots/organiser_des_réunions.jpg" alt="Organiser une réunion" width="200" style="margin: 10px;" />
<img src="assets/screenshots/groupe_étudiant.jpg" alt="Groupe étudiant" width="200" style="margin: 10px;" />
<img src="assets/screenshots/Affichage_des_créneaux.jpg" alt="Créneaux communs" width="200" style="margin: 10px;" />
<img src="assets/screenshots/Affichage_creation_personnal_events.jpg" alt="Création événement personnel" width="200" style="margin: 10px;" />
<img src="assets/screenshots/test_creation_personnal event.jpg" alt="Test création événement personnel" width="200" style="margin: 10px;" />
<img src="assets/screenshots/Affichage_personnal_event.jpg" alt="Affichage événement personnel" width="200" style="margin: 10px;" />
<img src="assets/screenshots/Affichage_details_personnal_event.jpg" alt="Détails événement personnel" width="200" style="margin: 10px;" />

</div>

---

📥 **Télécharger l’application (Android uniquement)**
👉 [Cliquez ici pour récupérer l’APK](https://drive.google.com/file/d/1pu8xpEkScE7waXez33QuJm3siK-jk1dH/view?usp=sharing)

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
