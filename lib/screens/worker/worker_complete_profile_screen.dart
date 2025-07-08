import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/nestjs_provider.dart';
import '../../services/validate_service.dart';
import 'dart:io';
import 'dart:convert';

class WorkerCompleteProfileScreen extends StatefulWidget {
  const WorkerCompleteProfileScreen({super.key});

  @override
  State<WorkerCompleteProfileScreen> createState() => _WorkerCompleteProfileScreenState();
}

class _WorkerCompleteProfileScreenState extends State<WorkerCompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isConnected = false;
  int _currentStep = 0;
  
  // Documentos para trabajadores
  File? _dniFrontal;
  File? _dniPosterior;
  File? _certificatePdf;
  
  // Documentos existentes del trabajador
  Map<String, dynamic>? _existingDocuments;
  bool _hasExistingDocuments = false;

  // Servicios seleccionados
  final List<int> _selectedServices = [];
  
  // Servicios disponibles (mock data - después se cargará del backend)
  final List<Map<String, dynamic>> _availableServices = [
    {'id': 1, 'name': 'Plomería', 'icon': Icons.plumbing, 'color': Colors.blue},
    {'id': 2, 'name': 'Electricidad', 'icon': Icons.electrical_services, 'color': Colors.orange},
    {'id': 3, 'name': 'Carpintería', 'icon': Icons.handyman, 'color': Colors.brown},
    {'id': 4, 'name': 'Pintura', 'icon': Icons.format_paint, 'color': Colors.purple},
    {'id': 5, 'name': 'Limpieza', 'icon': Icons.cleaning_services, 'color': Colors.green},
    {'id': 6, 'name': 'Jardinería', 'icon': Icons.eco, 'color': Colors.lightGreen},
  ];

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadExistingProfile();
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

  Future<void> _loadExistingProfile() async {
    try {
      final nestJSProvider = context.read<NestJSProvider>();
      final profile = await nestJSProvider.getWorkerProfile();
      
      if (mounted && profile != null) {
        setState(() {
          _existingDocuments = profile;
          
          // Verificar si tiene documentos existentes
          final hasDniFrontal = profile['dniFrontalUrl'] != null && profile['dniFrontalUrl'].toString().isNotEmpty;
          final hasDniPosterior = profile['dniPosteriorUrl'] != null && profile['dniPosteriorUrl'].toString().isNotEmpty;
          final hasCertificatePdf = profile['certificatePdfUrl'] != null && profile['certificatePdfUrl'].toString().isNotEmpty;
          
          _hasExistingDocuments = hasDniFrontal && hasDniPosterior && hasCertificatePdf;
          
          // Si tiene documentos existentes, llenar los campos
          if (_hasExistingDocuments) {
            _dniController.text = profile['dniNumber'] ?? '';
            _descriptionController.text = profile['description'] ?? '';
          }
        });
        
        print('🔍 Perfil cargado: $_existingDocuments');
        print('🔍 Tiene documentos existentes: $_hasExistingDocuments');
      }
    } catch (e) {
      print('❌ Error cargando perfil existente: $e');
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _skipToServices() {
    setState(() {
      _currentStep = 1; // Saltar al paso de servicios
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un servicio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nestJSProvider = context.read<NestJSProvider>();

      // Si ya tiene documentos existentes, solo actualizar servicios
      if (_hasExistingDocuments) {
        print('🔍 Ya tiene documentos, solo actualizando servicios...');
        await _updateWorkerServices(nestJSProvider);
      } else {
        // Validar documentos nuevos
        if (_dniFrontal == null || _dniPosterior == null || _certificatePdf == null) {
          throw Exception('Debe subir todos los documentos requeridos');
        }

        // Validar con el backend
        final result = await ValidateService.validateCertUnico(
          dni: _dniController.text.trim(),
          dniFrontal: _dniFrontal!,
          dniPosterior: _dniPosterior!,
          certUnico: _certificatePdf!,
        );
        
        if (result == null) {
          throw Exception('No se pudo conectar con el servidor');
        }
        
        final valido = result['valido'] ?? false;
        final antecedentes = result['antecedentes'] ?? [];
        
        if (valido == false && antecedentes.isNotEmpty) {
          throw Exception('TIENE ANTECEDENTES, NO PUEDE USAR LA APP');
        } else if (valido == false) {
          throw Exception('LOS DATOS NO COINCIDEN');
        }

        // Registrar trabajador con documentos nuevos
        await _registerWorker(nestJSProvider);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil completado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirigir al dashboard
        context.go('/worker/dashboard');
      }

    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  Future<void> _registerWorker(NestJSProvider nestJSProvider) async {
    // Subir documentos
    final uploadedDocs = <String, dynamic>{};
    if (_dniFrontal != null) {
      uploadedDocs['dniFrontal'] = await nestJSProvider.uploadFile(_dniFrontal!);
    }
    if (_dniPosterior != null) {
      uploadedDocs['dniPosterior'] = await nestJSProvider.uploadFile(_dniPosterior!);
    }
    if (_certificatePdf != null) {
      uploadedDocs['certificatePdf'] = await nestJSProvider.uploadFile(_certificatePdf!);
    }

    // Registrar trabajador
    final workerData = {
      'dniNumber': _dniController.text.trim(),
      'dniFrontalUrl': uploadedDocs['dniFrontal'],
      'dniPosteriorUrl': uploadedDocs['dniPosterior'],
      'certificatePdfUrl': uploadedDocs['certificatePdf'],
      'description': _descriptionController.text.trim().isNotEmpty 
        ? _descriptionController.text.trim() 
        : 'Trabajador registrado en ChambaPE',
      'radiusKm': 10,
      'serviceCategories': _selectedServices,
    };
    
    await nestJSProvider.registerWorker(workerData);
  }

  Future<void> _updateWorkerServices(NestJSProvider nestJSProvider) async {
    // Solo actualizar servicios del trabajador
    final serviceData = {
      'serviceCategories': _selectedServices,
      'description': _descriptionController.text.trim().isNotEmpty 
        ? _descriptionController.text.trim() 
        : 'Trabajador registrado en ChambaPE',
    };
    
    await nestJSProvider.configureWorkerServices(serviceData);
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted 
                        ? Colors.green 
                        : isActive 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted 
                        ? Icons.check 
                        : Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ['Documentos', 'Servicios', 'Finalizar'][index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos de Identidad',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Si ya tiene documentos, mostrar mensaje diferente
        if (_hasExistingDocuments) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '✅ Ya tienes todos los documentos subidos y verificados',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          const Text(
            'Sube los documentos necesarios para validar tu identidad',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // DNI Number
        TextFormField(
          controller: _dniController,
          decoration: const InputDecoration(
            labelText: 'Número de DNI',
            hintText: '12345678',
            prefixIcon: Icon(Icons.badge),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese su número de DNI';
            }
            if (value.length != 8) {
              return 'El DNI debe tener 8 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        
        // Si ya tiene documentos, mostrar resumen
        if (_hasExistingDocuments) ...[
          _buildExistingDocumentsSummary(),
        ] else ...[
          // Document upload section
          _buildDocumentUpload(
            'DNI Frontal',
            _dniFrontal,
            (file) => setState(() => _dniFrontal = file),
            Icons.camera_alt,
          ),
          const SizedBox(height: 16),
          
          _buildDocumentUpload(
            'DNI Posterior',
            _dniPosterior,
            (file) => setState(() => _dniPosterior = file),
            Icons.camera_alt,
          ),
          const SizedBox(height: 16),
          
          _buildDocumentUpload(
            'Certificado Único Laboral',
            _certificatePdf,
            (file) => setState(() => _certificatePdf = file),
            Icons.description,
            isPdf: true,
          ),
        ],
      ],
    );
  }

  Widget _buildExistingDocumentsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documentos Subidos:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          // DNI Frontal
          _buildDocumentItem(
            'DNI Frontal',
            Icons.camera_alt,
            _existingDocuments?['dniFrontalUrl'] != null,
          ),
          const SizedBox(height: 8),
          
          // DNI Posterior
          _buildDocumentItem(
            'DNI Posterior',
            Icons.camera_alt,
            _existingDocuments?['dniPosteriorUrl'] != null,
          ),
          const SizedBox(height: 8),
          
          // Certificado PDF
          _buildDocumentItem(
            'Certificado Único Laboral',
            Icons.description,
            _existingDocuments?['certificatePdfUrl'] != null,
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Puedes continuar con la configuración de servicios',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _skipToServices,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continuar con Servicios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String title, IconData icon, bool hasDocument) {
    return Row(
      children: [
        Icon(
          hasDocument ? Icons.check_circle : Icons.cancel,
          color: hasDocument ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 12),
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        if (hasDocument)
          Text(
            'Subido',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildServicesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Servicios que Ofreces',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Selecciona los servicios que puedes realizar',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _availableServices.length,
          itemBuilder: (context, index) {
            final service = _availableServices[index];
            final isSelected = _selectedServices.contains(service['id']);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedServices.remove(service['id']);
                  } else {
                    _selectedServices.add(service['id']);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                    ? service['color'].withOpacity(0.1)
                    : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                      ? service['color']
                      : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      service['icon'],
                      size: 40,
                      color: isSelected 
                        ? service['color']
                        : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                          ? service['color']
                          : Colors.grey,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
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

  Widget _buildFinalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Adicional',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Cuéntanos sobre tu experiencia y especialidades',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Descripción de servicios',
            hintText: 'Describe tu experiencia, especialidades y lo que te hace único...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        
        // Resumen de información
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen de tu perfil:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('DNI: ${_dniController.text}'),
              Text('Servicios: ${_selectedServices.length} seleccionados'),
              Text('Documentos: ${_dniFrontal != null && _dniPosterior != null && _certificatePdf != null ? "Completos" : "Pendientes"}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUpload(
    String title,
    File? file,
    Function(File) onFileSelected,
    IconData icon, {
    bool isPdf = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (file != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.path.split('/').last,
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.green.shade700),
                    onPressed: () => onFileSelected(file),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () async {
                // Aquí implementarías la lógica de selección de archivos
                // Por ahora es un placeholder
              },
              icon: Icon(isPdf ? Icons.description : Icons.camera_alt),
              label: Text('Subir ${isPdf ? 'PDF' : 'Imagen'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_currentStep == 0) _buildDocumentsStep(),
                    if (_currentStep == 1) _buildServicesStep(),
                    if (_currentStep == 2) _buildFinalStep(),
                  ],
                ),
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _previousStep,
                        child: const Text('Anterior'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading 
                        ? null 
                        : _currentStep == 2 
                          ? _completeProfile
                          : _nextStep,
                      child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(_currentStep == 2 ? 'Completar' : 'Siguiente'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 