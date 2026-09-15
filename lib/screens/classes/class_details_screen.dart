import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/english_class.dart';
import '../../models/student.dart';
import '../../providers/class_provider.dart';
import '../../services/dao/class_dao.dart';
import '../../widgets/custom_widgets.dart';

class ClassDetailsScreen extends StatefulWidget {
  final EnglishClass englishClass;

  const ClassDetailsScreen({Key? key, required this.englishClass}) : super(key: key);

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  final ClassDao _classDao = ClassDao();
  List<Student> _enrolledStudents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _classDao.getStudentsInClass(widget.englishClass.id);
      if (mounted) {
        setState(() {
          _enrolledStudents = students;
        });
      }
    } catch (e) {
      debugPrint('Error loading enrolled students: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddStudentDialog() async {
    if (widget.englishClass.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cette classe a atteint sa capacité maximale de ${widget.englishClass.maxCapacity} étudiants.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    List<Student> availableStudents = [];
    try {
      availableStudents = await _classDao.getOtherStudents(widget.englishClass.id);
    } catch (e) {
      debugPrint('Error loading available students: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (availableStudents.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ajouter un étudiant'),
          content: const Text('Aucun étudiant disponible ou tous les étudiants sont déjà inscrits dans cette classe.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredStudents = availableStudents.where((s) {
              return s.fullName.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Sélectionner un étudiant'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un étudiant...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          query = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredStudents.isEmpty
                          ? const Center(child: Text('Aucun étudiant trouvé'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = filteredStudents[index];
                                final currentClass = student.englishClass;
                                final subtitleText = currentClass != null 
                                    ? 'Classe actuelle : ${currentClass.name}'
                                    : 'Classe actuelle : Aucune';
                                
                                return ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(student.fullName),
                                  subtitle: Text(
                                    subtitleText,
                                    style: TextStyle(
                                      color: currentClass != null ? Colors.orange : Colors.green,
                                      fontWeight: currentClass != null ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                  onTap: () async {
                                    if (currentClass != null) {
                                      final confirm = await showDialog<bool>(
                                        context: ctx,
                                        builder: (confirmCtx) => AlertDialog(
                                          title: const Text('Confirmer le transfert'),
                                          content: Text(
                                            'Cet étudiant est actuellement inscrit dans la classe ${currentClass.name}. '
                                            'Voulez-vous le transférer vers ${widget.englishClass.name} ?'
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(confirmCtx, false),
                                              child: const Text('Annuler'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(confirmCtx, true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.orange),
                                              child: const Text('Transférer'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm != true) return;
                                    }

                                    Navigator.pop(ctx);
                                    await _enrollStudent(student.id);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _enrollStudent(String studentId) async {
    try {
      await context.read<ClassProvider>().enrollStudent(widget.englishClass.id, studentId);
      // Update UI by reloading students
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Étudiant ajouté à la classe avec succès')),
        );
        // Go back to previous screen and return to refresh currentEnrollment in list
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout : $e')),
      );
    }
  }

  Future<void> _unenrollStudent(String studentId, String studentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le retrait'),
        content: Text('Voulez-vous vraiment retirer $studentName de cette classe ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<ClassProvider>().unenrollStudent(widget.englishClass.id, studentId);
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Étudiant retiré avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du retrait : $e')),
      );
    }
  }

  Future<void> _deleteClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la classe'),
        content: Text(
          'Voulez-vous vraiment supprimer la classe "${widget.englishClass.name}" ?\n\n'
          'Toutes les inscriptions à cette classe seront également supprimées.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await context.read<ClassProvider>().deleteClass(widget.englishClass.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Classe supprimée avec succès')),
        );
        Navigator.pop(context); // close details screen
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String capacityText;
    if (widget.englishClass.isUnlimited) {
      capacityText = '${_enrolledStudents.length} étudiants — Illimité';
    } else {
      capacityText = '${_enrolledStudents.length} / ${widget.englishClass.maxCapacity} étudiants';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.englishClass.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteClass,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                          ListTile(
                            leading: const Icon(Icons.person_pin),
                            title: const Text('Enseignant responsable'),
                            subtitle: Text(widget.englishClass.teacher?.fullName ?? 'Aucun'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.leaderboard),
                            title: const Text('Niveau'),
                            subtitle: Text(widget.englishClass.level.isEmpty ? 'Non spécifié' : widget.englishClass.level),
                          ),
                          ListTile(
                            leading: const Icon(Icons.people),
                            title: const Text('Capacité'),
                            subtitle: Text(capacityText),
                            trailing: !widget.englishClass.isUnlimited && widget.englishClass.isFull
                                ? const Chip(
                                    label: Text('Pleine', style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.red,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Étudiants inscrits',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _showAddStudentDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_enrolledStudents.isEmpty)
                    const CustomCard(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Aucun étudiant inscrit dans cette classe.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _enrolledStudents.length,
                      itemBuilder: (context, index) {
                        final student = _enrolledStudents[index];
                        return CustomCard(
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(student.fullName),
                            subtitle: Text(student.currentLevel),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _unenrollStudent(student.id, student.fullName),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

