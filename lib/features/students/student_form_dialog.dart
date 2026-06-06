import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/student_model.dart';
import 'student_providers.dart';

class StudentFormDialog extends ConsumerStatefulWidget {
  final StudentModel? student;

  const StudentFormDialog({super.key, this.student});

  @override
  ConsumerState<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends ConsumerState<StudentFormDialog> {
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
  late TextEditingController _contactPersonCtrl;
  late TextEditingController _emergencyPhoneCtrl;

  String _gender = 'M';
  String _status = 'Actif';
  DateTime _enrollDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final s = widget.student;
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

    if (s != null) {
      _gender = s.gender;
      _status = s.status;
      _enrollDate = DateTime.tryParse(s.enrollDate) ?? DateTime.now();
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
    _contactPersonCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newStudent = StudentModel(
        id: widget.student?.id,
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
        enrollDate: _enrollDate.toIso8601String(),
      );

      if (widget.student == null) {
        ref.read(studentsProvider.notifier).addStudent(newStudent);
      } else {
        ref.read(studentsProvider.notifier).updateStudent(newStudent);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student == null ? 'Ajouter un étudiant' : 'Modifier l\'étudiant'),
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
                _buildTextField(_phoneCtrl, 'Téléphone'),
                _buildTextField(_emailCtrl, 'Email'),
                _buildTextField(_nationalityCtrl, 'Nationalité'),
                _buildTextField(_addressCtrl, 'Adresse'),
                _buildTextField(_contactPersonCtrl, 'Personne d\'urgence'),
                _buildTextField(_emergencyPhoneCtrl, 'Tél. urgence'),
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
