import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/class_provider.dart';
import '../../widgets/custom_widgets.dart';
import 'class_form_screen.dart';
import 'class_details_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({Key? key}) : super(key: key);

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Classes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: searchController,
              label: 'Rechercher une classe ou enseignant',
              prefixIcon: Icons.search,
              onChanged: (val) {
                context.read<ClassProvider>().search(val);
              },
            ),
          ),
          Expanded(
            child: Consumer<ClassProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.classes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune classe n\'a encore été créée.\nCréez votre première classe pour commencer à organiser les étudiants.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.classes.length,
                  itemBuilder: (context, index) {
                    final englishClass = provider.classes[index];
                    
                    String capacityText;
                    if (englishClass.isUnlimited) {
                      capacityText = '${englishClass.currentEnrollment} étudiants — Illimité';
                    } else {
                      capacityText = '${englishClass.currentEnrollment} / ${englishClass.maxCapacity} étudiants';
                    }

                    return CustomCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(Icons.school, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(
                          englishClass.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('👨‍🏫 ${englishClass.teacher?.fullName ?? 'Aucun enseignant'}'),
                            const SizedBox(height: 2),
                            Text('👥 $capacityText', 
                                style: TextStyle(
                                  color: englishClass.isFull ? Colors.red : null,
                                  fontWeight: englishClass.isFull ? FontWeight.bold : null,
                                )),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClassFormScreen(englishClass: englishClass),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 16),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClassDetailsScreen(englishClass: englishClass),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassDetailsScreen(englishClass: englishClass),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClassFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

