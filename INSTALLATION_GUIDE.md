# INSTALLATION ET CONFIGURATION

## Prérequis

1. **Flutter SDK**
   - Télécharger: https://flutter.dev/docs/get-started/install
   - Version recommandée: 3.0.0 ou supérieur

2. **Git**
   - Télécharger: https://git-scm.com/download

3. **Éditeur**
   - VS Code + Extension Flutter
   - OU Android Studio
   - OU IntelliJ IDEA

4. **Systèmes d'exploitation supportés**
   - Windows 10/11
   - macOS 10.15+
   - Linux (Ubuntu 18.04+)

## Installation du Projet

### Étape 1 : Cloner le projet
```bash
cd "EXERCICE WEB/ENGLISH CENTER"
```

### Étape 2 : Installer les dépendances
```bash
flutter pub get
```

### Étape 3 : Vérifier la configuration
```bash
flutter doctor
```

### Étape 4 : Générer les fichiers de configuration
```bash
flutter pub get
```

## Configuration de la Base de Données

La base de données SQLite est **créée automatiquement** au premier lancement.

### Fichier de schéma
- Consulter: `database_schema.dart`
- Documentation: `DATABASE_SCHEMA.md`

### Tables créées automatiquement
1. users
2. students
3. teachers
4. classes
5. enrollments
6. payments
7. attendance
8. exams
9. results

## Structure du Projet

```
lib/
├── main.dart                          # Point d'entrée
├── config/
│   ├── app_theme.dart               # Thème Material3
│   └── constants.dart               # Constantes globales
├── models/
│   ├── user.dart
│   ├── student.dart
│   ├── teacher.dart
│   ├── english_class.dart
│   ├── enrollment.dart
│   └── payment.dart
├── services/
│   ├── auth_service.dart            # Authentification
│   ├── database_service.dart        # Gestion BDD
│   ├── user_dao.dart                # Data Access Object - Users
│   ├── student_dao.dart             # Data Access Object - Students
│   ├── teacher_dao.dart             # Data Access Object - Teachers
│   ├── class_dao.dart               # Data Access Object - Classes
│   ├── enrollment_dao.dart          # Data Access Object - Enrollments
│   └── payment_dao.dart             # Data Access Object - Payments
├── providers/
│   ├── auth_provider.dart
│   ├── student_provider.dart
│   ├── class_provider.dart
│   ├── payment_provider.dart
│   └── dashboard_provider.dart
├── screens/
│   ├── auth/
│   │   └── login_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── students/
│   │   ├── student_list_screen.dart
│   │   └── add_student_screen.dart
│   ├── classes/
│   │   └── class_list_screen.dart
│   ├── payments/
│   │   └── payment_screen.dart
│   ├── attendance/
│   │   └── attendance_screen.dart
│   ├── exams/
│   │   └── exams_screen.dart
│   └── reports/
│       └── reports_screen.dart
└── widgets/
    └── custom_widgets.dart          # Widgets réutilisables
```

## Démarrage de l'Application

### Pour Windows
```bash
flutter run -d windows
```

### Pour macOS
```bash
flutter run -d macos
```

### Pour Linux
```bash
flutter run -d linux
```

### Mode debug avec reload
```bash
flutter run
```

### Mode release (optimisé)
```bash
flutter run --release
```

## Identifiants de Test

**Utilisateur Admin (Test)**
- Username: `admin`
- Password: `admin`
- Rôle: Admin

*Note: À remplacer par une authentification réelle en production*

## Dépendances Principales

| Package | Version | Utilité |
|---------|---------|---------|
| provider | 6.0.0+ | Gestion d'état |
| sqflite | 2.3.0+ | Accès SQLite |
| sqlite3 | 1.14.0+ | Moteur SQLite |
| intl | 0.19.0+ | Localisation/Dates |
| fl_chart | 0.63.0+ | Graphiques |
| pdf | 3.10.0+ | Génération PDF |
| excel | 2.1.0+ | Export Excel |
| qr_flutter | 4.1.0+ | Génération QR Code |

## Configuration de l'Éditeur (VS Code)

### Extensions recommandées
1. Flutter (Dart Code)
2. Dart (Dart Code)
3. SQLite (Alex Ross)
4. REST Client (Huachao Mao)

### Paramètres (settings.json)
```json
{
  "dart.enableSdkFormatter": true,
  "dart.lineLength": 100,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll": true
    }
  }
}
```

## Linting et Analyse

### Vérifier le code
```bash
dart analyze
```

### Formater le code
```bash
dart format lib/
```

### Linting strict
```bash
dart analyze --fatal-infos
```

## Build pour Distribution

### Windows (.msix)
```bash
flutter build windows --release
# Fichier généré: build/windows/x64/runner/Release/
```

### macOS (.dmg)
```bash
flutter build macos --release
# Fichier généré: build/macos/Build/Products/Release/
```

### Linux (.deb)
```bash
flutter build linux --release
# Fichier généré: build/linux/x64/release/
```

## Problèmes Courants et Solutions

### 1. Erreur: "Could not find an option named null-safety"
**Solution:** Mettre à jour Flutter
```bash
flutter upgrade
```

### 2. Base de données verrouillée
**Solution:** Supprimer et recréer
```dart
// Ajouter dans main.dart avant l'app
await DatabaseService().deleteDatabase();
```

### 3. Erreur de permissions
**Solution:** Accorder les permissions sur Windows/Linux
```bash
sudo chown -R $USER ~/.config/flutter
```

### 4. Impossible de se connecter au téléphone
**Solution:** Vérifier le debugging USB
```bash
flutter devices
```

## Support et Documentation

- **Documentation Flutter**: https://flutter.dev/docs
- **Dart Documentation**: https://dart.dev/guides
- **SQLite Documentation**: https://www.sqlite.org/docs.html
- **Provider Package**: https://pub.dev/packages/provider

## Aide et Support

Pour des questions ou problèmes:
1. Consulter `README.md`
2. Vérifier `DEPLOYMENT_GUIDE.md`
3. Examiner `DATABASE_SCHEMA.md`
4. Consulter la documentation officielle Flutter

## Licence

MIT License - Libre d'utilisation
