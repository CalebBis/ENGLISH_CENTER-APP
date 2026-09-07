import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../providers/class_provider.dart';
import '../../widgets/custom_widgets.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student;

  const StudentFormScreen({Key? key, this.student}) : super(key: key);

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Personal Info
  late TextEditingController _lastNameController;
  late TextEditingController _postNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _placeOfBirthController;
  DateTime? _dateOfBirth;

  // Contact Info
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  // Guardian Info
  late TextEditingController _guardianLastNameController;
  late TextEditingController _guardianFirstNameController;
  late TextEditingController _guardianPhoneController;

  String? _selectedClassId;
  String? _photoPath;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    
    _lastNameController = TextEditingController(text: widget.student?.lastName ?? '');
    _postNameController = TextEditingController(text: widget.student?.postName ?? '');
    _firstNameController = TextEditingController(text: widget.student?.firstName ?? '');
    _placeOfBirthController = TextEditingController(text: widget.student?.placeOfBirth ?? '');
    _dateOfBirth = widget.student?.dateOfBirth;
    
    _addressController = TextEditingController(text: widget.student?.address ?? '');
    _phoneController = TextEditingController(text: widget.student?.phone ?? '');
    
    _guardianLastNameController = TextEditingController(text: widget.student?.guardianLastName ?? '');
    _guardianFirstNameController = TextEditingController(text: widget.student?.guardianFirstName ?? '');
    _guardianPhoneController = TextEditingController(text: widget.student?.guardianPhone ?? '');
    
    _photoPath = widget.student?.photoUrl;
    
    if (widget.student?.englishClass != null) {
      _selectedClassId = widget.student!.englishClass!.id;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadClasses();
    });
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _postNameController.dispose();
    _firstNameController.dispose();
    _placeOfBirthController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _guardianLastNameController.dispose();
    _guardianFirstNameController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _photoPath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de naissance')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check class capacity if a class is selected
      if (_selectedClassId != null) {
        final classProvider = context.read<ClassProvider>();
        final selectedClass = classProvider.classes.firstWhere(
          (c) => c.id == _selectedClassId,
          orElse: () => throw Exception('Classe introuvable'),
        );

        final isChangingClass = widget.student?.englishClass?.id != _selectedClassId;
        final isNewStudent = widget.student == null;

        if (isChangingClass || isNewStudent) {
          if (!selectedClass.isUnlimited && selectedClass.currentEnrollment >= selectedClass.maxCapacity) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cette classe a atteint sa capacité maximale.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      final student = Student(
        id: widget.student?.id ?? const Uuid().v4(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        postName: _postNameController.text.trim(),
        email: widget.student?.email ?? '',
        phone: _phoneController.text.trim(),
        currentLevel: widget.student?.currentLevel ?? '',
        photoUrl: _photoPath,
        placeOfBirth: _placeOfBirthController.text.trim(),
        dateOfBirth: _dateOfBirth,
        address: _addressController.text.trim(),
        guardianFirstName: _guardianFirstNameController.text.trim(),
        guardianLastName: _guardianLastNameController.text.trim(),
        guardianPhone: _guardianPhoneController.text.trim(),
        enrollmentDate: widget.student?.enrollmentDate ?? DateTime.now(),
        createdAt: widget.student?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final studentProvider = context.read<StudentProvider>();

      if (widget.student != null) {
        await studentProvider.updateStudent(student, _selectedClassId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Étudiant modifié avec succès')),
          );
        }
      } else {
        await studentProvider.addStudent(student, _selectedClassId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Étudiant créé avec succès')),
          );
        }
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'étudiant' : 'Ajouter un étudiant'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section Photo
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _photoPath != null && File(_photoPath!).existsSync()
                                ? FileImage(File(_photoPath!))
                                : null,
                            child: _photoPath == null || !File(_photoPath!).existsSync()
                                ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: Text(_photoPath == null ? 'Ajouter photo' : 'Changer'),
                              ),
                              if (_photoPath != null)
                                TextButton.icon(
                                  onPressed: () => setState(() => _photoPath = null),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informations personnelles
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informations personnelles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _lastNameController,
                            label: 'Nom *',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ce champ est obligatoire' : null,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _postNameController,
                            label: 'Post-nom *',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ce champ est obligatoire' : null,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _firstNameController,
                            label: 'Prénom *',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ce champ est obligatoire' : null,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _placeOfBirthController,
                            label: 'Lieu de naissance *',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ce champ est obligatoire' : null,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectDateOfBirth,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date de naissance *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _dateOfBirth == null ? 'Sélectionner une date' : _dateFormat.format(_dateOfBirth!),
                                style: TextStyle(color: _dateOfBirth == null ? Colors.grey[700] : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Coordonnées
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Coordonnées', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _addressController,
                            label: 'Adresse *',
                            prefixIcon: Icons.location_on,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ce champ est obligatoire' : null,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Téléphone *',
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ce champ est obligatoire' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scolarité
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Scolarité (Facultatif)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Consumer<ClassProvider>(
                            builder: (context, provider, child) {
                              if (provider.isLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              return DropdownButtonFormField<String>(
                                value: _selectedClassId,
                                decoration: const InputDecoration(
                                  labelText: 'Classe',
                                  prefixIcon: Icon(Icons.school),
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Non assigné')),
                                  ...provider.classes.map((c) {
                                    final capacityText = c.isUnlimited 
                                      ? 'Illimité' 
                                      : '${c.currentEnrollment}/${c.maxCapacity}';
                                    return DropdownMenuItem(
                                      value: c.id,
                                      child: Text('${c.name} ($capacityText)'),
                                    );
                                  }),
                                ],
                                onChanged: (val) => setState(() => _selectedClassId = val),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tuteur
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tuteur (Facultatif)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _guardianLastNameController,
                            label: 'Nom du tuteur',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _guardianFirstNameController,
                            label: 'Prénom du tuteur',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _guardianPhoneController,
                            label: 'Téléphone du tuteur',
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      label: 'Enregistrer',
                      onPressed: _saveStudent,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
