# 📅 Emploi du Temps Université de la Nouvelle-Calédonie

**Application mobile Flutter** permettant aux étudiants de l’Université de la Nouvelle-Calédonie (UNC) de consulter facilement leur emploi du temps personnalisé à partir de leur identifiant étudiant.

---

## 🚀 Fonctionnalités

* 🧑‍🎓 Saisie de l'identifiant étudiant.
* 📆 Affichage de l’emploi du temps récupéré en ligne.
* 📍 Détails complets pour chaque événement : intitulé, salle, professeur, heure de début et de fin.
* 🗓️ Tri et regroupement automatique des événements par jour.
* 🇫🇷 Interface en français avec prise en charge des fuseaux horaires (Nouméa) et des formats de date français.

---

## 📦 Prérequis

Avant de pouvoir exécuter le projet, assure-toi d’avoir installé les éléments suivants :

* [Flutter SDK](https://flutter.dev/docs/get-started/install)
* [Dart SDK](https://dart.dev/get-dart) 
* Un éditeur 
    * [Android Studio](https://developer.android.com/studio) peut être utiliser avec Un émulateur Android/iOS
    * [Visual Studio Code](https://code.visualstudio.com/) peut être utiliser avec appareil physique connecté (l'appareil doit être en mode développeur)

* Un accès Internet pour récupérer les données d’emploi du temps

---

## 🛠️ Dépendances principales

Le projet utilise plusieurs packages Flutter essentiels :

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

## 📁 Structure principale du projet

* `main.dart` – Point d’entrée de l’application
* `app.dart` – Initialisation de l’application et gestion des vues principales
* `views/user_id_input_view.dart` – Interface de saisie de l'identifiant étudiant
* `views/home_page.dart` – Affichage des événements (emploi du temps)
* `services/schedule_service.dart` – Appels API pour récupérer les données ICS
* `models/ics_event.dart` – Modèle de données pour représenter un événement
* `constants/strings.dart` – Constantes de texte (multilingue, ergonomie)

---

## ⚙️ Comment exécuter le projet

1. **Clone le dépôt** :

   ```bash
   https://github.com/johnwaia/test_app.git
   cd test_app
   ```

2. **Installe les dépendances** :

   ```bash
   flutter pub get
   ```

3. **Lance l’application** :

   * Sur un simulateur ou appareil physique :

     ```bash
     flutter run
     ```

---


## 📸 Captures d’écran (optionnel)

### Ouverture de l'application 
![Écran ouverture de l'application](assets/screenshots/ouverture_application.jpg)

### Mettre son identifiant UNC
![Écran entrer de l'identifiant](assets/screenshots/mettre_son_identifiant.jpg)

### Affichage des Emploi du temps
![Écran affichage des emploi du temps](assets/screenshots/affichage_emploi_du_temps.jpg)


## 📍 Remarques

* Les événements sont extraits via un service externe à partir d’un fichier `.ics` lié à l’ID étudiant.

* Le fuseau horaire utilisé est `Pacific/Noumea` pour correspondre à l’heure locale.

* L’application fonctionne uniquement avec une connexion Internet active.

---

## 🧑‍💻 Contribuer

Tu veux améliorer l’application ? Tu es le bienvenu ! Ouvre une issue, propose une amélioration ou soumets une pull request !

---

## 📄 Licence

Projet développé dans un cadre pédagogique. Licence à définir selon usage (MIT, GPL, etc.)

