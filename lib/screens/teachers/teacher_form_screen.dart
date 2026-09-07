import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../config/app_theme.dart';
import '../../models/teacher.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/custom_widgets.dart';

class TeacherFormScreen extends StatefulWidget {
  final Teacher? teacher;
  const TeacherFormScreen({Key? key, this.teacher}) : super(key: key);

  @override
  State<TeacherFormScreen> createState() => _TeacherFormScreenState();
}

class _TeacherFormScreenState extends State<TeacherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _postNameCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _placeOfBirthCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _specializationsCtrl;

  DateTime? _dateOfBirth;
  String? _photoPath;

  bool get _isEditing => widget.teacher != null;

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    _lastNameCtrl = TextEditingController(text: t?.lastName ?? '');
    _postNameCtrl = TextEditingController(text: t?.postName ?? '');
    _firstNameCtrl = TextEditingController(text: t?.firstName ?? '');
    _placeOfBirthCtrl = TextEditingController(text: t?.placeOfBirth ?? '');
    _addressCtrl = TextEditingController(text: t?.address ?? '');
    _phoneCtrl = TextEditingController(text: t?.phone ?? '');
    _emailCtrl = TextEditingController(text: t?.email ?? '');
    _specializationsCtrl = TextEditingController(
        text: t?.specializations.join(', ') ?? '');
    _dateOfBirth = t?.dateOfBirth;
    _photoPath = t?.photoUrl;
  }

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _postNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _placeOfBirthCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _specializationsCtrl.dispose();
    super.dispose();
  }

  // ── Photo picker ────────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'teacher_photos'));
    await photosDir.create(recursive: true);

    final ext = p.extension(picked.path);
    final filename = '${const Uuid().v4()}$ext';
    final dest = p.join(photosDir.path, filename);
    await File(picked.path).copy(dest);

    setState(() => _photoPath = dest);
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Date picker ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1980),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final specs = _specializationsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final teacher = Teacher(
      id: widget.teacher?.id ?? const Uuid().v4(),
      lastName: _lastNameCtrl.text.trim(),
      postName: _postNameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      specializations: specs.isEmpty ? ['Général'] : specs,
      dateOfBirth: _dateOfBirth,
      placeOfBirth: _placeOfBirthCtrl.text.trim().isEmpty
          ? null
          : _placeOfBirthCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      photoUrl: _photoPath,
      biography: widget.teacher?.biography,
      isActive: true,
      createdAt: widget.teacher?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final provider = context.read<TeacherProvider>();
      if (_isEditing) {
        await provider.updateTeacher(teacher);
      } else {
        await provider.addTeacher(teacher);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'enseignant' : 'Nouvel enseignant'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo avatar ──────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.12),
                        backgroundImage: _photoPath != null &&
                                File(_photoPath!).existsSync()
                            ? FileImage(File(_photoPath!))
                            : null,
                        child: (_photoPath == null ||
                                !File(_photoPath!).existsSync())
                            ? const Icon(Icons.person,
                                size: 52, color: AppTheme.primaryColor)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showPhotoOptions,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.accentColor,
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Informations personnelles ────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informations personnelles',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Nom
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nom *',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 16),

                      // Postnom
                      TextFormField(
                        controller: _postNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Postnom',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Prénom
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Prénom *',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 16),

                      // Date de naissance
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date de naissance',
                            prefixIcon: const Icon(Icons.cake),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _dateOfBirth != null
                                ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
                                    '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
                                    '${_dateOfBirth!.year}'
                                : 'Sélectionner une date',
                            style: _dateOfBirth != null
                                ? null
                                : TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lieu de naissance
                      TextFormField(
                        controller: _placeOfBirthCtrl,
                        decoration: InputDecoration(
                          labelText: 'Lieu de naissance',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Adresse
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: InputDecoration(
                          labelText: 'Adresse',
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Contact ──────────────────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Téléphone
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Téléphone *',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Spécialisations ─────────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spécialisations',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'Séparer les spécialisations par des virgules',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _specializationsCtrl,
                        decoration: InputDecoration(
                          labelText: 'Spécialisations',
                          hintText: 'ex: Grammaire, Conversation, Business English',
                          prefixIcon: const Icon(Icons.school),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Bouton Enregistrer ──────────────────────────────────────
              CustomButton(
                label: _isEditing ? 'Enregistrer les modifications' : 'Enregistrer',
                onPressed: _save,
                isLoading: _isSaving,
                backgroundColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

