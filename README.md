# English Center Management App

Application de gestion complète pour un centre d'anglais, développée avec Flutter et SQLite.

## Fonctionnalités

- 👥 Gestion des étudiants
- 📚 Gestion des classes et niveaux
- 💰 Gestion des paiements
- 📊 Suivi de la présence
- 📈 Progression pédagogique
- 👨‍🏫 Gestion des enseignants
- 📋 Rapports et statistiques
- 🔐 Authentification avec rôles

## Architecture

- **Frontend** : Flutter Desktop
- **Base de données** : SQLite (local)
- **Gestion d'état** : Provider
- **Architecture** : MVVM modulé par feature

## Structure du projet

```
lib/
├── main.dart
├── config/
│   ├── app_theme.dart
│   └── constants.dart
├── screens/
│   ├── auth/
│   ├── dashboard/
│   ├── students/
│   ├── classes/
│   ├── payments/
│   ├── attendance/
│   ├── exams/
│   ├── reports/
│   └── teachers/
├── models/
├── services/
├── widgets/
└── providers/
```

## Installation

1. Cloner le projet
2. `flutter pub get`
3. `flutter run -d windows` (ou macos/linux)

## Dépendances principales

- **provider** : Gestion d'état
- **sqlite3/sqflite** : Base de données
- **intl** : Localisation
- **fl_chart** : Graphiques
- **pdf** : Génération de PDF
- **excel** : Export Excel

## Phases de développement

- Phase 1 ✅ : Setup du projet
- Phase 2 : Schéma SQLite et modèles
- Phase 3 : Authentification
- Phase 4 : Dashboard
- Phase 5 : Gestion des étudiants
- ... (voir plan.md pour le détail)

## License

MIT
