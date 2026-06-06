import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/student_model.dart';
import 'student_providers.dart';

/// Widget de formulaire pour l'ajout ou la modification d'un étudiant.
///
/// C'est un [ConsumerStatefulWidget] (Riverpod + State) car il doit :
/// - Gérer son propre état interne (valeurs des champs).
/// - Accéder aux providers Riverpod pour enregistrer les données dans SQLite.
///
/// [student] : si fourni → mode modification (pré-remplissage des champs).
///             si null  → mode ajout (formulaire vide).
class StudentFormDialog extends ConsumerStatefulWidget {
  /// L'étudiant à modifier. Null = mode "Ajout".
  final StudentModel? student;

  const StudentFormDialog({super.key, this.student});

  /// Crée l'état interne associé à ce widget.
  @override
  ConsumerState<StudentFormDialog> createState() => _StudentFormDialogState();
}

/// L'état interne de [StudentFormDialog].
///
/// Contient tous les contrôleurs de texte et les variables d'état
/// nécessaires à la gestion du formulaire.
class _StudentFormDialogState extends ConsumerState<StudentFormDialog> {
  /// Clé globale du formulaire, permettant de déclencher la validation de tous les champs.
  final _formKey = GlobalKey<FormState>();

  // ---- Contrôleurs de champs texte ----
  // Un contrôleur par champ du formulaire. Ils permettent de lire et écrire
  // la valeur affichée dans chaque [TextFormField].
  late TextEditingController _lastNameCtrl;      // Champ : Nom de famille
  late TextEditingController _postnameCtrl;      // Champ : Postnom
  late TextEditingController _firstnameCtrl;     // Champ : Prénom
  late TextEditingController _pobCtrl;           // Champ : Lieu de naissance
  late TextEditingController _dobCtrl;           // Champ : Date de naissance
  late TextEditingController _phoneCtrl;         // Champ : Numéro de téléphone
  late TextEditingController _addressCtrl;       // Champ : Adresse physique
  late TextEditingController _emailCtrl;         // Champ : Adresse email
  late TextEditingController _nationalityCtrl;   // Champ : Nationalité
  late TextEditingController _contactPersonCtrl; // Champ : Personne de contact d'urgence
  late TextEditingController _emergencyPhoneCtrl; // Champ : Téléphone d'urgence

  // ---- Variables d'état pour les menus déroulants ----
  String _gender = 'M';               // Sexe sélectionné : 'M' ou 'F'
  String _status = 'Actif';           // Statut : 'Actif' ou 'Inactif'
  DateTime _enrollDate = DateTime.now(); // Date d'inscription (aujourd'hui par défaut)

  /// Initialise les contrôleurs avec les données existantes ou des chaînes vides.
  ///
  /// Si [widget.student] est fourni (mode modification), chaque contrôleur
  /// est pré-rempli avec la valeur de l'étudiant correspondant.
  @override
  void initState() {
    super.initState();
    final s = widget.student; // Raccourci vers l'étudiant passé en paramètre

    // Pré-remplit chaque contrôleur. L'opérateur "??" retourne '' si la valeur est null.
    _lastNameCtrl = TextEditingController(text: s?.lastName ?? '');
    _postnameCtrl = TextEditingController(text: s?.postname ?? '');
    _firstnameCtrl = TextEditingController(text: s?.firstname ?? '');
    _pobCtrl = TextEditingController(text: s?.pob ?? '');
    _dobCtrl = TextEditingController(text: s?.dob ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _nationalityCtrl = TextEditingController(text: s?.nationality ?? '');
    _contactPersonCtrl = TextEditingController(text: s?.contactPerson ?? '');
    _emergencyPhoneCtrl = TextEditingController(text: s?.emergencyPhone ?? '');

    // En mode modification, restaure également les sélections des menus déroulants.
    if (s != null) {
      _gender = s.gender;
      _status = s.status;
      // Convertit la chaîne ISO 8601 en DateTime ; utilise DateTime.now() en cas d'erreur.
      _enrollDate = DateTime.tryParse(s.enrollDate) ?? DateTime.now();
    }
  }

  /// Libère tous les contrôleurs de texte pour éviter les fuites mémoire.
  ///
  /// Appelé automatiquement par Flutter quand le widget est retiré de l'arbre.
  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _postnameCtrl.dispose();
    _firstnameCtrl.dispose();
    _pobCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _nationalityCtrl.dispose();
    _contactPersonCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  /// Valide le formulaire et enregistre les données de l'étudiant.
  ///
  /// Étapes :
  /// 1. Valide tous les champs du formulaire via [_formKey].
  /// 2. Construit un [StudentModel] avec les données saisies.
  /// 3. Appelle [addStudent] ou [updateStudent] selon le mode.
  /// 4. Ferme la boîte de dialogue.
  void _submit() {
    // Valide tous les champs. Retourne false si au moins un champ est invalide.
    if (_formKey.currentState!.validate()) {
      // Construction du modèle étudiant avec les données du formulaire.
      final newStudent = StudentModel(
        id: widget.student?.id, // null = nouvel enregistrement, sinon mise à jour existante
        lastName: _lastNameCtrl.text,
        postname: _postnameCtrl.text,
        firstname: _firstnameCtrl.text,
        gender: _gender,
        pob: _pobCtrl.text,
        dob: _dobCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
        email: _emailCtrl.text,
        nationality: _nationalityCtrl.text,
        contactPerson: _contactPersonCtrl.text,
        emergencyPhone: _emergencyPhoneCtrl.text,
        status: _status,
        enrollDate: _enrollDate.toIso8601String(), // Format ISO 8601 pour SQLite
      );

      // Mode Ajout : aucun étudiant existant fourni.
      if (widget.student == null) {
        ref.read(studentsProvider.notifier).addStudent(newStudent);
      } else {
        // Mode Modification : étudiant existant fourni.
        ref.read(studentsProvider.notifier).updateStudent(newStudent);
      }

      // Ferme la boîte de dialogue et retourne à l'écran précédent.
      Navigator.of(context).pop();
    }
  }

  /// Construit la boîte de dialogue contenant le formulaire d'étudiant.
  ///
  /// Structure :
  /// - [AlertDialog] : conteneur principal de la boîte de dialogue.
  ///   - [Form] : enveloppe les champs pour la validation groupée.
  ///     - [Wrap] : dispose les champs en grille flexible sur plusieurs lignes.
  ///   - Actions : boutons "Annuler" et "Enregistrer".
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      /// Titre dynamique selon le mode : ajout ou modification.
      title: Text(widget.student == null ? 'Ajouter un étudiant' : 'Modifier l\'étudiant'),

      content: SizedBox(
        width: 600, // Largeur fixe adaptée à l'affichage Desktop
        child: Form(
          key: _formKey, // Associe ce formulaire à sa clé pour la validation
          child: SingleChildScrollView(
            /// Rend le contenu défilable si la liste de champs dépasse l'espace disponible.
            child: Wrap(
              spacing: 16,    // Espacement horizontal entre les champs
              runSpacing: 16, // Espacement vertical entre les rangées
              children: [
                // ---- Champs d'identité (obligatoires) ----
                _buildTextField(_lastNameCtrl, 'Nom', required: true),
                _buildTextField(_postnameCtrl, 'Postnom', required: true),
                _buildTextField(_firstnameCtrl, 'Prénom', required: true),

                /// Menu déroulant : sélection du sexe (M ou F).
                /// Appelle setState pour reconstruire le widget avec la nouvelle valeur.
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Sexe *'),
                  items: ['M', 'F'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _gender = v!),
                ),

                // ---- Champs de naissance (obligatoires) ----
                _buildTextField(_pobCtrl, 'Lieu de naissance', required: true),
                _buildTextField(_dobCtrl, 'Date de naissance (JJ/MM/AAAA)', required: true),

                // ---- Champs de contact (optionnels) ----
                _buildTextField(_phoneCtrl, 'Téléphone'),
                _buildTextField(_emailCtrl, 'Email'),
                _buildTextField(_nationalityCtrl, 'Nationalité'),
                _buildTextField(_addressCtrl, 'Adresse'),

                // ---- Champs d'urgence (optionnels) ----
                _buildTextField(_contactPersonCtrl, 'Personne d\'urgence'),
                _buildTextField(_emergencyPhoneCtrl, 'Tél. urgence'),

                /// Menu déroulant : statut de l'étudiant (Actif ou Inactif).
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: ['Actif', 'Inactif'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ],
            ),
          ),
        ),
      ),

      /// Boutons d'action de la boîte de dialogue.
      actions: [
        /// Bouton "Annuler" : ferme la boîte de dialogue sans aucune modification.
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),

        /// Bouton "Enregistrer" : lance la validation puis l'enregistrement via [_submit].
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  /// Crée un champ de saisie texte réutilisable et standardisé.
  ///
  /// Paramètres :
  /// - [ctrl]     : le contrôleur qui stocke la valeur du champ.
  /// - [label]    : le texte affiché comme libellé du champ.
  /// - [required] : si true, le champ est marqué (*) et un validateur bloque la soumission si vide.
  ///
  /// Retourne un [SizedBox] contenant un [TextFormField] stylisé.
  Widget _buildTextField(TextEditingController ctrl, String label, {bool required = false}) {
    return SizedBox(
      width: 280, // Largeur standard permettant d'afficher deux champs côte à côte dans le Wrap
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          // Ajoute " *" au label pour indiquer visuellement que le champ est obligatoire.
          labelText: required ? '$label *' : label,
        ),
        // Validateur fonctionnel uniquement si le champ est requis.
        // Retourne un message d'erreur si la valeur est vide, sinon null (= valide).
        validator: required ? (v) => v!.isEmpty ? 'Ce champ est requis' : null : null,
      ),
    );
  }
}
