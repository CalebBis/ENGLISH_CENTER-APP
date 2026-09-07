// Documentation complète de la structure de la base de données

# Schéma de la Base de Données SQLite
## English Center Management System

### 1. TABLE: users
Gère les comptes utilisateur et l'authentification

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Identifiant unique (UUID) |
| username | TEXT | UNIQUE NOT NULL | Nom d'utilisateur unique |
| email | TEXT | UNIQUE NOT NULL | Email unique |
| password | TEXT | NOT NULL | Mot de passe (hashé) |
| fullName | TEXT | NOT NULL | Nom complet |
| role | TEXT | NOT NULL | admin, secretary, teacher, student |
| isActive | INTEGER | DEFAULT 1 | 1=actif, 0=inactif |
| createdAt | TEXT | NOT NULL | Date de création (ISO 8601) |
| updatedAt | TEXT | NOT NULL | Date de modification (ISO 8601) |

### 2. TABLE: students
Informations des étudiants inscrits

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Identifiant unique (UUID) |
| firstName | TEXT | NOT NULL | Prénom |
| lastName | TEXT | NOT NULL | Nom |
| email | TEXT | NOT NULL | Email |
| phone | TEXT | NOT NULL | Téléphone |
| currentLevel | TEXT | NOT NULL | Niveau actuel (Beginner, Elementary, etc.) |
| photoUrl | TEXT | | URL de la photo |
| enrollmentDate | TEXT | NOT NULL | Date d'inscription |
| dateOfBirth | TEXT | | Date de naissance |
| address | TEXT | | Adresse |
| parentName | TEXT | | Nom du parent |
| parentPhone | TEXT | | Téléphone du parent |
| isActive | INTEGER | DEFAULT 1 | 1=actif, 0=inactif |
| createdAt | TEXT | NOT NULL | Date de création |
| updatedAt | TEXT | NOT NULL | Date de modification |

### 3. TABLE: teachers
Informations des enseignants

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Identifiant unique (UUID) |
| firstName | TEXT | NOT NULL | Prénom |
| lastName | TEXT | NOT NULL | Nom |
| email | TEXT | NOT NULL | Email |
| phone | TEXT | NOT NULL | Téléphone |
| specializations | TEXT | NOT NULL | Spécialisations (séparées par des virgules) |
| biography | TEXT | | Biographie |
| photoUrl | TEXT | | URL de la photo |
| isActive | INTEGER | DEFAULT 1 | 1=actif, 0=inactif |
| createdAt | TEXT | NOT NULL | Date de création |
| updatedAt | TEXT | NOT NULL | Date de modification |

### 4. TABLE: classes
Gestion des classes et cours

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Identifiant unique (UUID) |
| name | TEXT | NOT NULL | Nom de la classe |
| level | TEXT | NOT NULL | Niveau (Beginner, Intermediate, etc.) |
| teacherId | TEXT | FOREIGN KEY | Référence à l'enseignant |
| description | TEXT | | Description |
| maxCapacity | INTEGER | NOT NULL | Nombre maximum d'étudiants |
| currentEnrollment | INTEGER | DEFAULT 0 | Nombre d'inscrits actuels |
| schedule | TEXT | NOT NULL | Horaire (ex: Lun/Mer 18h-20h) |
| location | TEXT | NOT NULL | Lieu (salle) |
| isActive | INTEGER | DEFAULT 1 | 1=actif, 0=inactif |
| createdAt | TEXT | NOT NULL | Date de création |
| updatedAt | TEXT | NOT NULL | Date de modification |

### 5. TABLE: enrollments
Inscriptions des étudiants aux classes

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Identifiant unique (UUID) |
| studentId | TEXT | FOREIGN KEY | Référence à l'étudiant |
| classId | TEXT | FOREIGN KEY | Référence à la classe |
| enrollmentDate | TEXT | NOT NULL | Date d'inscription |
| completionDate | TEXT | | Date d'achèvement |
| status | TEXT | NOT NULL | active, completed, dropped |
| createdAt | TEXT | NOT NULL | Date de création |
| updatedAt | TEXT | NOT NULL | Date de modification |

### 6. TABLE: payments
Historique des paiements

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Identifiant unique (UUID) |
| studentId | TEXT | FOREIGN KEY | Référence à l'étudiant |
| amount | REAL | NOT NULL | Montant |
| status | TEXT | NOT NULL | paid, pending, overdue |
| paymentDate | TEXT | NOT NULL | Date du paiement |
| paymentMethod | TEXT | | Méthode (cash, card, transfer) |
| notes | TEXT | | Notes additionnelles |
| createdAt | TEXT | NOT NULL | Date de création |
| updatedAt | TEXT | NOT NULL | Date de modification |

### 7. TABLE: attendance
Suivi de la présence

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Identifiant unique (UUID) |
| studentId | TEXT | FOREIGN KEY | Référence à l'étudiant |
| classId | TEXT | FOREIGN KEY | Référence à la classe |
| attendanceDate | TEXT | NOT NULL | Date de la séance |
| status | TEXT | NOT NULL | present, absent, justified |
| notes | TEXT | | Notes |
| createdAt | TEXT | NOT NULL | Date de création |
| updatedAt | TEXT | NOT NULL | Date de modification |

### 8. TABLE: exams
Gestion des examens

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Identifiant unique (UUID) |
| classId | TEXT | FOREIGN KEY | Référence à la classe |
| title | TEXT | NOT NULL | Titre de l'examen |
| description | TEXT | | Description |
| examDate | TEXT | NOT NULL | Date de l'examen |
| status | TEXT | NOT NULL | pending, completed, graded |
| createdAt | TEXT | NOT NULL | Date de création |
| updatedAt | TEXT | NOT NULL | Date de modification |

### 9. TABLE: results
Résultats des examens

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | TEXT | PRIMARY KEY | Identifiant unique (UUID) |
| studentId | TEXT | FOREIGN KEY | Référence à l'étudiant |
| examId | TEXT | FOREIGN KEY | Référence à l'examen |
| score | REAL | NOT NULL | Note (0-100) |
| grade | TEXT | | Lettre de note (A, B, C, etc.) |
| resultDate | TEXT | NOT NULL | Date du résultat |
| notes | TEXT | | Notes additionnelles |
| createdAt | TEXT | NOT NULL | Date de création |
| updatedAt | TEXT | NOT NULL | Date de modification |

## Relations (Diagramme ERD)

```
users (1) ──────── (many) enrollments
               
teachers (1) ──────── (many) classes
                           │
                           │ (many)
                           ├─────── (many) enrollments
                           │
                           ├─────── (many) attendance
                           │
                           └─────── (many) exams

students (1) ──────── (many) enrollments
         │
         │ (many)
         ├─────── (many) payments
         │
         ├─────── (many) attendance
         │
         └─────── (many) results

exams (1) ──────── (many) results
```

## Indexes créés pour optimiser les requêtes

- idx_enrollments_studentId : Recherche rapide par étudiant
- idx_enrollments_classId : Recherche rapide par classe
- idx_payments_studentId : Recherche rapide des paiements
- idx_attendance_studentId : Recherche rapide de la présence
- idx_attendance_classId : Recherche rapide par classe
- idx_results_studentId : Recherche rapide des résultats
- idx_results_examId : Recherche rapide par examen
- idx_classes_teacherId : Recherche rapide par enseignant
- idx_students_email : Recherche rapide par email
- idx_users_username : Recherche rapide par username

## Contraintes intégrité

- Clés primaires : Assurent l'unicité de chaque enregistrement
- Clés étrangères : Maintiennent la cohérence des relations
- UNIQUE : Empêchent les doublons (username, email)
- NOT NULL : Champs obligatoires
- DEFAULT : Valeurs par défaut (isActive=1, dates)
