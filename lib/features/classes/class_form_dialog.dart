import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/class_model.dart';
import '../teachers/teacher_providers.dart';
import 'class_providers.dart';

class ClassFormDialog extends ConsumerStatefulWidget {
  final ClassModel? classModel;

  const ClassFormDialog({super.key, this.classModel});

  @override
  ConsumerState<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends ConsumerState<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _scheduleCtrl;
  late TextEditingController _roomCtrl;
  late TextEditingController _capacityCtrl;

  int? _levelId;
  int? _teacherId;

  @override
  void initState() {
    super.initState();
    final c = widget.classModel;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _scheduleCtrl = TextEditingController(text: c?.schedule ?? '');
    _roomCtrl = TextEditingController(text: c?.room ?? '');
    _capacityCtrl = TextEditingController(text: c?.maxCapacity.toString() ?? '30');

    if (c != null) {
      _levelId = c.levelId;
      _teacherId = c.teacherId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _scheduleCtrl.dispose();
    _roomCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _levelId != null && _teacherId != null) {
      final newClass = ClassModel(
        id: widget.classModel?.id,
        name: _nameCtrl.text,
        levelId: _levelId!,
        teacherId: _teacherId!,
        schedule: _scheduleCtrl.text,
        room: _roomCtrl.text,
        maxCapacity: int.tryParse(_capacityCtrl.text) ?? 30,
      );

      if (widget.classModel == null) {
        ref.read(classesProvider.notifier).addClass(newClass);
      } else {
        ref.read(classesProvider.notifier).updateClass(newClass);
      }

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(levelsProvider);
    final teachersAsync = ref.watch(teachersProvider);

    return AlertDialog(
      title: Text(widget.classModel == null ? 'Créer une classe' : 'Modifier la classe'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildTextField(_nameCtrl, 'Nom de classe', required: true),
                _buildTextField(_scheduleCtrl, 'Horaire', required: true),
                _buildTextField(_roomCtrl, 'Salle', required: true),
                _buildTextField(_capacityCtrl, 'Capacité maximale', required: true),
                
                // Niveaux Dropdown
                levelsAsync.when(
                  data: (levels) => DropdownButtonFormField<int>(
                    value: _levelId,
                    decoration: const InputDecoration(labelText: 'Niveau *'),
                    items: levels.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                    onChanged: (v) => setState(() => _levelId = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Erreur: $e'),
                ),

                // Enseignants Dropdown
                teachersAsync.when(
                  data: (teachers) => DropdownButtonFormField<int>(
                    value: _teacherId,
                    decoration: const InputDecoration(labelText: 'Enseignant *'),
                    items: teachers.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.lastName} ${t.firstname}'))).toList(),
                    onChanged: (v) => setState(() => _teacherId = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Erreur: $e'),
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
      width: double.infinity,
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: required ? '$label *' : label),
        validator: required ? (v) => v!.isEmpty ? 'Ce champ est requis' : null : null,
      ),
    );
  }
}
