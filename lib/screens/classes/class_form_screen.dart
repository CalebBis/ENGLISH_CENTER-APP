import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/english_class.dart';
import '../../models/teacher.dart';
import '../../providers/class_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/custom_widgets.dart';

class ClassFormScreen extends StatefulWidget {
  final EnglishClass? englishClass;

  const ClassFormScreen({Key? key, this.englishClass}) : super(key: key);

  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _levelController;
  late TextEditingController _capacityController;
  
  String? _selectedTeacherId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.englishClass?.name ?? '');
    _levelController = TextEditingController(text: widget.englishClass?.level ?? '');
    
    // Capacity logic: 0 = unlimited. If it's a new class, leave empty (unlimited by default)
    if (widget.englishClass != null) {
      _capacityController = TextEditingController(
        text: widget.englishClass!.isUnlimited ? '' : widget.englishClass!.maxCapacity.toString()
      );
      _selectedTeacherId = widget.englishClass!.teacherId;
    } else {
      _capacityController = TextEditingController();
    }

    // Load teachers to populate dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherProvider>().loadTeachers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _saveClass() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un enseignant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int capacity = 0; // 0 = Unlimited
      if (_capacityController.text.isNotEmpty) {
        capacity = int.parse(_capacityController.text);
      }

      if (widget.englishClass != null) {
        // Editing existing class
        if (capacity > 0 && capacity < widget.englishClass!.currentEnrollment) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attention : cette capacité est inférieure au nombre d\'étudiants actuel (${widget.englishClass!.currentEnrollment}).'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          // Wait briefly so user can see the warning, then proceed
          await Future.delayed(const Duration(seconds: 2));
        }

        final updated = widget.englishClass!.copyWith(
          name: _nameController.text.trim(),
          level: _levelController.text.trim(),
          maxCapacity: capacity,
          teacherId: _selectedTeacherId,
          updatedAt: DateTime.now(),
        );
        await context.read<ClassProvider>().updateClass(updated);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Classe modifiée avec succès')),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new class
        final newClass = EnglishClass(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          level: _levelController.text.trim(),
          teacherId: _selectedTeacherId!,
          maxCapacity: capacity,
          currentEnrollment: 0,
          schedule: 'À définir', // simplified for this form
          location: 'À définir',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await context.read<ClassProvider>().addClass(newClass);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Classe créée avec succès')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.englishClass != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la classe' : 'Ajouter une classe'),
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
                    CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations générales',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _nameController,
                              label: 'Nom de la classe *',
                              prefixIcon: Icons.class_,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Ce champ est obligatoire';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _levelController,
                              label: 'Niveau (ex: Beginner A1)',
                              prefixIcon: Icons.leaderboard,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _capacityController,
                              label: 'Capacité maximale (vide = illimité)',
                              prefixIcon: Icons.people,
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  final num = int.tryParse(val);
                                  if (num == null || num <= 0) {
                                    return 'Veuillez entrer un nombre valide > 0';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enseignant associé *',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Consumer<TeacherProvider>(
                              builder: (context, provider, child) {
                                if (provider.isLoading) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                if (provider.teachers.isEmpty) {
                                  return const Text(
                                    'Aucun enseignant disponible. Veuillez en créer un.',
                                    style: TextStyle(color: Colors.red),
                                  );
                                }
                                
                                return DropdownButtonFormField<String>(
                                  value: _selectedTeacherId,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.person_pin),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  hint: const Text('Sélectionner un enseignant'),
                                  items: provider.teachers.map((teacher) {
                                    return DropdownMenuItem(
                                      value: teacher.id,
                                      child: Text(teacher.fullName),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedTeacherId = val;
                                    });
                                  },
                                  validator: (val) => val == null ? 'Veuillez sélectionner un enseignant' : null,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      label: 'Enregistrer',
                      onPressed: _isLoading ? null : _saveClass,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

