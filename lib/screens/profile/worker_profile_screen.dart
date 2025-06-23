import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  String name = 'Luis Rodríguez';
  String email = 'luis.rod@example.com';
  String specialty = 'Electricista';
  double rating = 4.7;
  int jobsDone = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del trabajador'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/user_placeholder.png'),
            ),
            const SizedBox(height: 16),
            Text(name, style: Theme.of(context).textTheme.headlineSmall),
            Text(email, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 16),
            Chip(
              label: Text('Especialidad: $specialty'),
              backgroundColor: Colors.blue.shade100,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard(Icons.star, '$rating', 'Rating'),
                _statCard(Icons.check_circle, '$jobsDone', 'Trabajos'),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => _buildEditSheet(),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar perfil'),

            ),ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/workerHistory');
              },
              icon: const Icon(Icons.history),
              label: const Text('Ver historial de trabajos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label),
      ],
    );
  }

  Widget _buildEditSheet() {
    final nameController = TextEditingController(text: name);
    final specialtyController = TextEditingController(text: specialty);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Editar perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(controller: specialtyController, decoration: const InputDecoration(labelText: 'Especialidad')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                name = nameController.text;
                specialty = specialtyController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),ElevatedButton.icon(
            onPressed: () {
              context.go('/workerHistory');
            },
            icon: const Icon(Icons.history),
            label: const Text('Ver historial de trabajos'),
          ),

        ],
      ),
    );
  }
}
