import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Présences',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle),
                label: const Text('Marquer les présences'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: ListView(
                children: [
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Classe')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Présents')),
                      DataColumn(label: Text('Absents')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: const [
                      DataRow(cells: [
                        DataCell(Text('INT-101')),
                        DataCell(Text('05-06-2023')),
                        DataCell(Text('12')),
                        DataCell(Text('2')),
                        DataCell(Icon(Icons.visibility, color: Colors.blue)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
