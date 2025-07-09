import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/nestjs_provider.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final provider = context.read<NestJSProvider>();
    try {
      final data = await provider.getWorkerProfile();
      setState(() => _profile = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final provider = context.read<NestJSProvider>();
    await provider.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('No se pudo cargar el perfil'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 60),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildRow('Nombre',
                          '${_profile?['user']?['firstName'] ?? ''} ${_profile?['user']?['lastName'] ?? ''}'),
                      _buildRow('Email', _profile?['user']?['email'] ?? ''),
                      _buildRow('Teléfono', _profile?['user']?['phone'] ?? ''),
                      _buildRow('Descripción', _profile?['description'] ?? ''),
                      _buildRow('Disponible hoy',
                          (_profile?['isActiveToday'] ?? false) ? 'Sí' : 'No'),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text(value.isNotEmpty ? value : '-',
                  style: const TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
} 