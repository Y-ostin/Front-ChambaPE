import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/nestjs_provider.dart';
import '../../models/service_category.dart';

class ConfigureWorkerServicesScreen extends StatefulWidget {
  const ConfigureWorkerServicesScreen({super.key});

  @override
  State<ConfigureWorkerServicesScreen> createState() => _ConfigureWorkerServicesScreenState();
}

class _ConfigureWorkerServicesScreenState extends State<ConfigureWorkerServicesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isConnected = false;
  List<ServiceCategory> _availableCategories = [];
  List<int> _selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadServiceCategories();
  }

  Future<void> _checkConnection() async {
    final nestJSProvider = context.read<NestJSProvider>();
    final connected = await nestJSProvider.testConnection();
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }
  }

  Future<void> _loadServiceCategories() async {
    try {
      final nestJSProvider = context.read<NestJSProvider>();
      final categories = await nestJSProvider.getServiceCategories();
      if (mounted) {
        setState(() {
          _availableCategories = categories;
        });
      }
    } catch (e) {
      print('❌ Error cargando categorías: $e');
      // Cargar categorías por defecto si falla
      if (mounted) {
        setState(() {
          _availableCategories = [
            ServiceCategory(id: 1, name: 'Plomería', description: 'Servicios de plomería', iconUrl: '🔧'),
            ServiceCategory(id: 2, name: 'Electricidad', description: 'Servicios eléctricos', iconUrl: '⚡'),
            ServiceCategory(id: 3, name: 'Limpieza', description: 'Servicios de limpieza', iconUrl: '🧹'),
            ServiceCategory(id: 4, name: 'Jardinería', description: 'Servicios de jardinería', iconUrl: '🌱'),
            ServiceCategory(id: 5, name: 'Albañilería', description: 'Servicios de construcción', iconUrl: '🏗️'),
          ];
        });
      }
    }
  }

  Future<void> _configureServices() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos una categoría de servicio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nestJSProvider = context.read<NestJSProvider>();

      print('🔧 Configurando servicios del trabajador...');
      
      // Configurar servicios del trabajador
      final serviceData = {
        'serviceCategories': _selectedCategoryIds,
        'description': _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : 'Trabajador registrado en ChambaPE',
      };
      
      print('📤 Enviando configuración de servicios: ${jsonEncode(serviceData)}');
      
      await nestJSProvider.configureWorkerServices(serviceData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Servicios configurados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirigir al dashboard de trabajador
        context.go('/worker/dashboard');
      }

    } catch (e) {
      print('❌ Error al configurar servicios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al configurar servicios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Servicios'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 32),
                    _buildServiceCategories(theme),
                    const SizedBox(height: 32),
                    _buildDescriptionField(theme),
                    const SizedBox(height: 32),
                    _buildSubmitButton(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.work_rounded,
            size: 40,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Configurar Servicios',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona las categorías de servicios que ofreces',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildServiceCategories(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías de Servicios',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _availableCategories.isEmpty
            ? Center(
                child: Text(
                  'No hay categorías disponibles',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _availableCategories.length,
                itemBuilder: (context, index) {
                  final category = _availableCategories[index];
                  final isSelected = _selectedCategoryIds.contains(category.id);
                  return GestureDetector(
                    onTap: () => _toggleCategory(category.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.15)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2.5 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono (emoji o url)
                          category.iconUrl.isNotEmpty && category.iconUrl.length < 5
                              ? Text(
                                  category.iconUrl,
                                  style: const TextStyle(fontSize: 38),
                                )
                              : Icon(Icons.work, size: 38, color: theme.colorScheme.primary),
                          const SizedBox(height: 10),
                          Text(
                            category.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 22),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción de Servicios',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            hintText: 'Cuéntanos sobre tus servicios y experiencia...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _configureServices,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Configurar Servicios',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
} 