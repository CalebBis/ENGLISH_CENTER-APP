import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/teacher_model.dart';
import 'teacher_providers.dart';

class TeacherFormDialog extends ConsumerStatefulWidget {
  final TeacherModel? teacher;

  const TeacherFormDialog({super.key, this.teacher});

  @override
  ConsumerState<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends ConsumerState<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _lastNameCtrl;
  late TextEditingController _postnameCtrl;
  late TextEditingController _firstnameCtrl;
  late TextEditingController _pobCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _nationalityCtrl;
  late TextEditingController _specialtyCtrl;
  late TextEditingController _teachingLevelCtrl;

  String _gender = 'M';
  String _status = 'Actif';
  DateTime _hireDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
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

    if (t != null) {
      _gender = t.gender;
      _status = t.status;
      _hireDate = DateTime.tryParse(t.hireDate) ?? DateTime.now();
    }
  }

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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newTeacher = TeacherModel(
        id: widget.teacher?.id,
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
        hireDate: _hireDate.toIso8601String(),
      );

      if (widget.teacher == null) {
        ref.read(teachersProvider.notifier).addTeacher(newTeacher);
      } else {
        ref.read(teachersProvider.notifier).updateTeacher(newTeacher);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.teacher == null ? 'Ajouter un enseignant' : 'Modifier l\'enseignant'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildTextField(_lastNameCtrl, 'Nom', required: true),
                _buildTextField(_postnameCtrl, 'Postnom', required: true),
                _buildTextField(_firstnameCtrl, 'Prénom', required: true),
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
                _buildTextField(_nationalityCtrl, 'Nationalité'),
                _buildTextField(_addressCtrl, 'Adresse'),
                _buildTextField(_specialtyCtrl, 'Spécialité', required: true),
                _buildTextField(_teachingLevelCtrl, 'Niveau d\'enseignement'),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool required = false}) {
    return SizedBox(
      width: 280,
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: required ? '$label *' : label),
        validator: required ? (v) => v!.isEmpty ? 'Ce champ est requis' : null : null,
      ),
    );
  }
}
