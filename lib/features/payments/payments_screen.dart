import 'package:flutter/material.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

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
                'Paiements',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Enregistrer un paiement'),
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
                      DataColumn(label: Text('Étudiant')),
                      DataColumn(label: Text('Montant')),
                      DataColumn(label: Text('Mois')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Reçu')),
                    ],
                    rows: const [
                      DataRow(cells: [
                        DataCell(Text('Jean Dupont')),
                        DataCell(Text('\$150')),
                        DataCell(Text('Juin')),
                        DataCell(Text('01-06-2023')),
                        DataCell(Icon(Icons.picture_as_pdf, color: Colors.red)),
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
