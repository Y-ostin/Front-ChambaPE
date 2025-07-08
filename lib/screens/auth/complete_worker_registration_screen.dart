import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/nestjs_provider.dart';
import '../../models/service_category.dart';

class CompleteWorkerRegistrationScreen extends StatefulWidget {
  const CompleteWorkerRegistrationScreen({super.key});

  @override
  State<CompleteWorkerRegistrationScreen> createState() =>
      _CompleteWorkerRegistrationScreenState();
}

class _CompleteWorkerRegistrationScreenState
    extends State<CompleteWorkerRegistrationScreen> {
  List<ServiceCategory> _serviceCategories = [];
  final List<int> _selectedServiceIds = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServiceCategories();
  }

  Future<void> _loadServiceCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final nestJSProvider = context.read<NestJSProvider>();
      final categoriesData = await nestJSProvider.getServiceCategories();

      setState(() {
        _serviceCategories = categoriesData
            .where((category) => category.isActive)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar categorías: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveServices() async {
    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un servicio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      final nestJSProvider = context.read<NestJSProvider>();
      await nestJSProvider.addWorkerServices(_selectedServiceIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Servicios configurados exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar al dashboard del trabajador
        context.go('/worker/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar servicios: $e';
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleServiceSelection(int serviceId) {
    setState(() {
      if (_selectedServiceIds.contains(serviceId)) {
        _selectedServiceIds.remove(serviceId);
      } else {
        _selectedServiceIds.add(serviceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Registro'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando categorías de servicio...'),
                  ],
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadServiceCategories,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Header con información
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.verified_user,
                          size: 48,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '¡Bienvenido a ChambaPE!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tu cuenta ha sido verificada. Ahora selecciona los servicios que ofreces:',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Lista de categorías de servicio
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _serviceCategories.length,
                      itemBuilder: (context, index) {
                        final category = _serviceCategories[index];
                        final isSelected = _selectedServiceIds.contains(
                          category.id,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isSelected ? 4 : 2,
                          color: isSelected ? Colors.blue.shade50 : null,
                          child: InkWell(
                            onTap: () => _toggleServiceSelection(category.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        )
                                        : null,
                              ),
                              child: Row(
                                children: [
                                  // Icono o placeholder
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.blue
                                              : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getServiceIcon(category.name),
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Información del servicio
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isSelected
                                                    ? Colors.blue
                                                    : Colors.black87,
                                          ),
                                        ),
                                        if (category.description != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            category.description!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        if (category.workerCount != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${category.workerCount} trabajadores',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Checkbox
                                  Checkbox(
                                    value: isSelected,
                                    onChanged:
                                        (value) => _toggleServiceSelection(
                                          category.id,
                                        ),
                                    activeColor: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Botón de guardar
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_selectedServiceIds.isNotEmpty) ...[
                          Text(
                            '${_selectedServiceIds.length} servicio${_selectedServiceIds.length == 1 ? '' : 's'} seleccionado${_selectedServiceIds.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveServices,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Guardando...'),
                                    ],
                                  )
                                : const Text(
                                    'Completar Registro',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();

    if (name.contains('plom')) return Icons.plumbing;
    if (name.contains('electric')) return Icons.electrical_services;
    if (name.contains('limpi')) return Icons.cleaning_services;
    if (name.contains('jardin')) return Icons.yard;
    if (name.contains('pint')) return Icons.format_paint;
    if (name.contains('carpinter')) return Icons.handyman;
    if (name.contains('albañil')) return Icons.construction;
    if (name.contains('mecánic')) return Icons.build;
    if (name.contains('cocin')) return Icons.restaurant;
    if (name.contains('segur')) return Icons.security;
    if (name.contains('transporte')) return Icons.local_shipping;
    if (name.contains('tecnolog')) return Icons.computer;
    if (name.contains('salud')) return Icons.medical_services;
    if (name.contains('belleza')) return Icons.face;
    if (name.contains('eventos')) return Icons.event;

    return Icons.work;
  }
}
