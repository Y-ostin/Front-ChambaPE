import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/nestjs_provider.dart';
import '../../services/validate_service.dart';

class CompleteWorkerProfileScreen extends StatefulWidget {
  const CompleteWorkerProfileScreen({super.key});

  @override
  State<CompleteWorkerProfileScreen> createState() => _CompleteWorkerProfileScreenState();
}

class _CompleteWorkerProfileScreenState extends State<CompleteWorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isConnected = false;
  
  // Documentos para trabajadores
  File? _dniFrontal;
  File? _dniPosterior;
  File? _certificatePdf;
  String? _dniFrontalUrl;
  String? _dniPosteriorUrl;
  String? _certificatePdfUrl;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadWorkerDocuments();
  }

  Future<void> _loadWorkerDocuments() async {
    final nestJSProvider = context.read<NestJSProvider>();
    final user = await nestJSProvider.getCurrentUser();
    if (user != null) {
      final worker = await nestJSProvider.getWorkerData(user['id'].toString());
      if (worker != null) {
        setState(() {
          _dniFrontalUrl = worker['dniFrontalUrl'];
          _dniPosteriorUrl = worker['dniPosteriorUrl'];
          _certificatePdfUrl = worker['certificatePdfUrl'];
        });
      }
    }
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

  Future<void> _completeWorkerProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nestJSProvider = context.read<NestJSProvider>();

      print('🔍 Iniciando validación de documentos para trabajador...');
      
      // Verificar que todos los archivos estén subidos
      if (_dniFrontal == null || _dniPosterior == null || _certificatePdf == null) {
        print('❌ Faltan archivos para validar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe subir todos los documentos requeridos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validar documentos con el backend
      final result = await ValidateService.validateCertUnico(
        dni: _dniController.text.trim(),
        dniFrontal: _dniFrontal!,
        dniPosterior: _dniPosterior!,
        certUnico: _certificatePdf!,
      );
      
      print('📡 Resultado de validación: $result');
      
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ERROR INTERNO: No se pudo conectar con el servidor'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final valido = result['valido'] ?? false;
      final antecedentes = result['antecedentes'] ?? [];
      final mensaje = result['mensaje'] ?? 'Sin mensaje';
      
      if (valido == false && antecedentes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TIENE ANTECEDENTES, NO PUEDE USAR LA APP'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else if (valido == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('LOS DATOS NO COINCIDEN: $mensaje'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Registrar trabajador
      print('🔧 Completando perfil de trabajador...');
      await _registerWorker(nestJSProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil de trabajador completado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirigir al dashboard de trabajador
        context.go('/worker/dashboard');
      }

    } catch (e) {
      print('❌ Error al completar perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar perfil: $e'),
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
    print('📤 Subiendo documentos...');
    
    // Subir documentos primero
    final uploadedDocs = <String, dynamic>{};
    if (_dniFrontal != null) {
      uploadedDocs['dniFrontal'] = await nestJSProvider.uploadFile(_dniFrontal!);
      print('✅ DNI frontal subido: ${uploadedDocs['dniFrontal']}');
    }
    if (_dniPosterior != null) {
      uploadedDocs['dniPosterior'] = await nestJSProvider.uploadFile(_dniPosterior!);
      print('✅ DNI posterior subido: ${uploadedDocs['dniPosterior']}');
    }
    if (_certificatePdf != null) {
      uploadedDocs['certificatePdf'] = await nestJSProvider.uploadFile(_certificatePdf!);
      print('✅ Certificado subido: ${uploadedDocs['certificatePdf']}');
    }

    // Registrar trabajador con los documentos subidos
    print('🚀 Registrando trabajador en el backend...');
    final workerData = {
      'dniNumber': _dniController.text.trim(),
      'dniFrontalUrl': uploadedDocs['dniFrontal'],
      'dniPosteriorUrl': uploadedDocs['dniPosterior'],
      'certificatePdfUrl': uploadedDocs['certificatePdf'],
      'description': _descriptionController.text.trim().isNotEmpty 
        ? _descriptionController.text.trim() 
        : 'Trabajador registrado en ChambaPE',
      'radiusKm': 15,
      'serviceCategories': [1], // Categoría por defecto
    };
    
    print('📤 Enviando datos: ${jsonEncode(workerData)}');
    
    final workerResult = await nestJSProvider.registerWorker(workerData);
    
    print('📡 Resultado registro trabajador: $workerResult');
    print('✅ Trabajador registrado exitosamente');
  }

  Future<void> _pickImage(ImageSource source, Function(File) onImagePicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      onImagePicked(File(pickedFile.path));
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _certificatePdf = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil'),
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
                    _buildDocumentSection(theme),
                    const SizedBox(height: 32),
                    // ... aquí irían otros campos como descripción, etc ...
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
          'Completar Perfil',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sube tus documentos para completar tu perfil de trabajador',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isConnected 
          ? theme.colorScheme.primaryContainer 
          : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected 
              ? theme.colorScheme.onPrimaryContainer 
              : theme.colorScheme.onErrorContainer,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Conectado al servidor' : 'Sin conexión al servidor',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _isConnected 
                ? theme.colorScheme.onPrimaryContainer 
                : theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(ThemeData theme) {
    // Si existen URLs, mostrar solo los documentos subidos
    if (_dniFrontalUrl != null && _dniPosteriorUrl != null && _certificatePdfUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Documentos subidos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildDocumentPreview('DNI Frontal', _dniFrontalUrl!, isImage: true),
          const SizedBox(height: 16),
          _buildDocumentPreview('DNI Posterior', _dniPosteriorUrl!, isImage: true),
          const SizedBox(height: 16),
          _buildDocumentPreview('Certificado Único Laboral', _certificatePdfUrl!, isImage: false),
        ],
      );
    }
    // Si no existen, mostrar los campos para subir
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documentos de Identidad', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        // DNI Frontal
        _buildDocumentUpload(
          title: 'DNI Frontal',
          subtitle: 'Foto del frente de tu DNI',
          icon: Icons.camera_alt,
          file: _dniFrontal,
          onPick: (file) => setState(() => _dniFrontal = file),
          onPickImage: () => _pickImage(ImageSource.camera, (file) => setState(() => _dniFrontal = file)),
          onPickGallery: () => _pickImage(ImageSource.gallery, (file) => setState(() => _dniFrontal = file)),
        ),
        const SizedBox(height: 16),
        // DNI Posterior
        _buildDocumentUpload(
          title: 'DNI Posterior',
          subtitle: 'Foto del reverso de tu DNI',
          icon: Icons.camera_alt,
          file: _dniPosterior,
          onPick: (file) => setState(() => _dniPosterior = file),
          onPickImage: () => _pickImage(ImageSource.camera, (file) => setState(() => _dniPosterior = file)),
          onPickGallery: () => _pickImage(ImageSource.gallery, (file) => setState(() => _dniPosterior = file)),
        ),
        const SizedBox(height: 16),
        // Certificado Único
        _buildDocumentUpload(
          title: 'Certificado Único',
          subtitle: 'PDF del certificado de trabajo',
          icon: Icons.picture_as_pdf,
          file: _certificatePdf,
          onPick: (file) => setState(() => _certificatePdf = file),
          onPickPdf: _pickPdf,
        ),
      ],
    );
  }

  Widget _buildDocumentPreview(String title, String url, {bool isImage = true}) {
    return Row(
      children: [
        Icon(isImage ? Icons.image : Icons.picture_as_pdf, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        isImage
            ? Image.network(url, width: 80, height: 80, fit: BoxFit.cover)
            : IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () {
                  // Abrir PDF en navegador o visor externo
                  // Puedes usar url_launcher para abrir el enlace
                },
        ),
      ],
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required Function(File) onPick,
    VoidCallback? onPickImage,
    VoidCallback? onPickGallery,
    VoidCallback? onPickPdf,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: file != null ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: file != null ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: file != null ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (file != null)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
            ],
          ),
          if (file != null) ...[
            const SizedBox(height: 8),
            Text(
              'Archivo: ${file.path.split('/').last}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (onPickImage != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPickImage,
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Cámara'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              if (onPickImage != null && onPickGallery != null)
                const SizedBox(width: 8),
              if (onPickGallery != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPickGallery,
                    icon: const Icon(Icons.photo_library, size: 16),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              if (onPickPdf != null) ...[
                if (onPickImage != null || onPickGallery != null)
                  const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPickPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _completeWorkerProfile,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
            'Completar Perfil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
    );
  }

  @override
  void dispose() {
    _dniController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 