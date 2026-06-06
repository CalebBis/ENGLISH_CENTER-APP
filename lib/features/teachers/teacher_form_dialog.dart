import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'teacher_providers.dart';
import '../../core/models/teacher_model.dart';

/// Widget de formulaire pour l'ajout ou la modification d'un enseignant.
///
/// C'est un [ConsumerStatefulWidget] car :
/// - Il a un état interne (valeurs des champs du formulaire).
/// - Il doit accéder aux providers Riverpod pour enregistrer les données.
///
/// Si [teacher] est fourni, le formulaire est pré-rempli pour la modification.
/// Si [teacher] est null, le formulaire est vide pour un nouvel ajout.
class TeacherFormDialog extends ConsumerStatefulWidget {
  /// L'enseignant à modifier. Si null, on est en mode "Ajout".
  final TeacherModel? teacher;

  const TeacherFormDialog({super.key, this.teacher});

  /// Crée l'état interne associé à ce widget.
  @override
  ConsumerState<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

/// L'état interne de [TeacherFormDialog].
///
/// Gère les contrôleurs de texte, les valeurs des menus déroulants
/// et la logique de validation/soumission du formulaire.
class _TeacherFormDialogState extends ConsumerState<TeacherFormDialog> {
  /// Clé unique du formulaire, utilisée pour déclencher la validation globale.
  final _formKey = GlobalKey<FormState>();

  // ---- Contrôleurs de champs texte ----
  // Chaque contrôleur gère la saisie d'un champ spécifique du formulaire.
  late TextEditingController _lastNameCtrl;     // Champ : Nom de famille
  late TextEditingController _postnameCtrl;     // Champ : Postnom
  late TextEditingController _firstnameCtrl;    // Champ : Prénom
  late TextEditingController _pobCtrl;          // Champ : Lieu de naissance (Place Of Birth)
  late TextEditingController _dobCtrl;          // Champ : Date de naissance (Date Of Birth)
  late TextEditingController _phoneCtrl;        // Champ : Numéro de téléphone
  late TextEditingController _addressCtrl;      // Champ : Adresse physique
  late TextEditingController _emailCtrl;        // Champ : Adresse email
  late TextEditingController _nationalityCtrl;  // Champ : Nationalité
  late TextEditingController _specialtyCtrl;    // Champ : Spécialité (ex: IELTS, Grammaire)
  late TextEditingController _teachingLevelCtrl; // Champ : Niveau enseigné (ex: Intermediate)

  // ---- Variables d'état pour les menus déroulants ----
  String _gender = 'M';             // Sexe : 'M' (Masculin) ou 'F' (Féminin)
  String _status = 'Actif';         // Statut : 'Actif' ou 'Inactif'
  DateTime _hireDate = DateTime.now(); // Date d'embauche (initialisée à aujourd'hui)

  /// Initialise les contrôleurs et les valeurs d'état.
  ///
  /// Si un [widget.teacher] existe (mode modification), les contrôleurs sont
  /// pré-remplis avec ses données. Sinon, les champs sont vides.
  @override
  void initState() {
    super.initState();
    final t = widget.teacher; // Raccourci pour accéder à l'enseignant passé en paramètre

    // Initialise chaque contrôleur avec la valeur existante ou une chaîne vide.
    _lastNameCtrl = TextEditingController(text: t?.lastName ?? '');
    _postnameCtrl = TextEditingController(text: t?.postname ?? '');
    _firstnameCtrl = TextEditingController(text: t?.firstname ?? '');
    _pobCtrl = TextEditingController(text: t?.pob ?? '');
    _dobCtrl = TextEditingController(text: t?.dob ?? '');
    _phoneCtrl = TextEditingController(text: t?.phone ?? '');
    _addressCtrl = TextEditingController(text: t?.address ?? '');
    _emailCtrl = TextEditingController(text: t?.email ?? '');
    _nationalityCtrl = TextEditingController(text: t?.nationality ?? '');
    _specialtyCtrl = TextEditingController(text: t?.specialty ?? '');
    _teachingLevelCtrl = TextEditingController(text: t?.teachingLevel ?? '');

    // Si on est en mode modification, on pré-sélectionne le sexe, le statut et la date.
    if (t != null) {
      _gender = t.gender;
      _status = t.status;
      // Tente de parser la date ISO 8601 ; utilise aujourd'hui en cas d'échec.
      _hireDate = DateTime.tryParse(t.hireDate) ?? DateTime.now();
    }
  }

  /// Libère la mémoire occupée par tous les contrôleurs de texte.
  ///
  /// IMPORTANT : Toujours appeler [dispose()] sur les [TextEditingController]
  /// pour éviter les fuites mémoire lorsque le widget est retiré de l'arbre.
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
    _specialtyCtrl.dispose();
    _teachingLevelCtrl.dispose();
    super.dispose();
  }

  /// Valide le formulaire et enregistre les données dans la base via Riverpod.
  ///
  /// - Si la validation réussit : crée un [TeacherModel], appelle le provider
  ///   pour l'insertion (ajout) ou la mise à jour (modification), puis ferme la boîte de dialogue.
  /// - Si la validation échoue : les messages d'erreur sont affichés sous les champs invalides.
  void _submit() {
    // Déclenche la validation sur tous les champs du formulaire.
    if (_formKey.currentState!.validate()) {
      // Construit un objet TeacherModel avec les données saisies.
      final newTeacher = TeacherModel(
        id: widget.teacher?.id, // null pour un ajout, ID existant pour une modification
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
        specialty: _specialtyCtrl.text,
        teachingLevel: _teachingLevelCtrl.text,
        status: _status,
        hireDate: _hireDate.toIso8601String(), // Stocké au format ISO 8601 dans la BDD
      );

      // Mode Ajout : appelle addTeacher si aucun enseignant n'était fourni.
      if (widget.teacher == null) {
        ref.read(teachersProvider.notifier).addTeacher(newTeacher);
      } else {
        // Mode Modification : appelle updateTeacher avec les nouvelles données.
        ref.read(teachersProvider.notifier).updateTeacher(newTeacher);
      }

      // Ferme la boîte de dialogue après l'enregistrement.
      Navigator.of(context).pop();
    }
  }

  /// Construit la boîte de dialogue contenant le formulaire.
  ///
  /// La boîte de dialogue contient :
  /// - Un titre dynamique ("Ajouter" ou "Modifier").
  /// - Un formulaire avec tous les champs de l'enseignant.
  /// - Des boutons "Annuler" et "Enregistrer".
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      /// Titre dynamique : "Ajouter un enseignant" ou "Modifier l'enseignant".
      title: Text(widget.teacher == null ? 'Ajouter un enseignant' : 'Modifier l\'enseignant'),

      content: SizedBox(
        width: 600, // Largeur fixe pour un rendu propre sur Desktop
        child: Form(
          key: _formKey, // Lie le formulaire à sa clé globale pour la validation
          child: SingleChildScrollView(
            /// Permet le défilement vertical si le contenu dépasse la hauteur visible.
            child: Wrap(
              spacing: 16,    // Espace horizontal entre les champs
              runSpacing: 16, // Espace vertical entre les lignes
              children: [
                // ---- Champs obligatoires (required: true) ----
                _buildTextField(_lastNameCtrl, 'Nom', required: true),
                _buildTextField(_postnameCtrl, 'Postnom', required: true),
                _buildTextField(_firstnameCtrl, 'Prénom', required: true),

                /// Menu déroulant pour le sexe de l'enseignant.
                /// Met à jour [_gender] via setState quand l'utilisateur change la sélection.
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Sexe *'),
                  items: ['M', 'F'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _gender = v!),
                ),

                _buildTextField(_pobCtrl, 'Lieu de naissance', required: true),
                _buildTextField(_dobCtrl, 'Date de naissance (JJ/MM/AAAA)', required: true),
                _buildTextField(_phoneCtrl, 'Téléphone', required: true),
                _buildTextField(_emailCtrl, 'Email', required: true),

                // ---- Champs optionnels (required: false par défaut) ----
                _buildTextField(_nationalityCtrl, 'Nationalité'),
                _buildTextField(_addressCtrl, 'Adresse'),
                _buildTextField(_specialtyCtrl, 'Spécialité', required: true),
                _buildTextField(_teachingLevelCtrl, 'Niveau d\'enseignement'),

                /// Menu déroulant pour le statut de l'enseignant (Actif/Inactif).
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

      /// Boutons d'action en bas de la boîte de dialogue.
      actions: [
        /// Bouton "Annuler" : ferme le dialogue sans enregistrer.
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),

        /// Bouton "Enregistrer" : déclenche la validation et l'enregistrement via [_submit].
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  /// Crée un champ de texte standardisé pour le formulaire.
  ///
  /// [ctrl] : le contrôleur qui gère la valeur du champ.
  /// [label] : le libellé affiché dans le champ.
  /// [required] : si true, le champ est obligatoire et affiche un astérisque (*).
  ///   Un validateur est ajouté automatiquement pour refuser les valeurs vides.
  Widget _buildTextField(TextEditingController ctrl, String label, {bool required = false}) {
    return SizedBox(
      width: 280, // Largeur fixe pour aligner les champs en grille avec Wrap
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          // Ajoute " *" au label pour signaler visuellement que le champ est requis.
          labelText: required ? '$label *' : label,
        ),
        // Validateur : retourne un message d'erreur si le champ requis est vide.
        validator: required ? (v) => v!.isEmpty ? 'Ce champ est requis' : null : null,
      ),
    );
  }
}
