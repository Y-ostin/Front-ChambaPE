import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/nestjs_provider.dart';
import '../../widgets/document_upload_widget.dart';
import '../../services/validate_service.dart';

class RegisterScreenNew extends StatefulWidget {
  const RegisterScreenNew({super.key});

  @override
  State<RegisterScreenNew> createState() => _RegisterScreenNewState();
}

class _RegisterScreenNewState extends State<RegisterScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dniController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isWorker = false;
  bool _isConnected = false;

  // Documentos para trabajadores
  File? _dniFrontal;
  File? _dniPosterior;
  File? _certificatePdf;

  // Función helper para mostrar errores de manera elegante
  void _showErrorSnackBar(
    String title,
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  backgroundColor == Colors.orange
                      ? Icons.warning
                      : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Entendido',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkConnection();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nestJSProvider = context.read<NestJSProvider>();

      // Si es trabajador, validar documentos ANTES del registro
      if (_isWorker) {
        print('🔍 Iniciando validación de documentos para trabajador...');

        // Verificar que todos los archivos estén subidos
        if (_dniFrontal == null ||
            _dniPosterior == null ||
            _certificatePdf == null) {
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
          // Error de conexión o respuesta nula
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ERROR INTERNO: No se pudo conectar con el servidor',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        print('🔍 Resultado completo de validación: $result');
        print('🔍 Tipo de valido: ${result['valido'].runtimeType}');
        print('🔍 Valor de valido: ${result['valido']}');

        final valido = result['valido'] ?? false;
        final antecedentes = result['antecedentes'] ?? [];
        final mensaje = result['mensaje'] ?? 'Sin mensaje';

        print('🔍 Valido procesado: $valido (tipo: ${valido.runtimeType})');
        print('🔍 Antecedentes: $antecedentes');
        print('🔍 Mensaje: $mensaje');

        if (valido == false && antecedentes.isNotEmpty) {
          // Tiene antecedentes
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('TIENE ANTECEDENTES, NO PUEDE USAR LA APP'),
              backgroundColor: Colors.red,
            ),
          );
          print('❌ Antecedentes detectados, registro cancelado');
          return;
        } else if (valido == false) {
          // Datos no coinciden u otro error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LOS DATOS NO COINCIDEN: $mensaje'),
              backgroundColor: Colors.red,
            ),
          );
          print('❌ Datos no coinciden: $mensaje');
          return;
        } else if (valido == true && antecedentes.isEmpty) {
          // Validación exitosa, continuar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Documentos validados correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          print('✅ Validación exitosa, continuando con registro...');
        } else {
          // Caso inesperado
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error inesperado: $mensaje'),
              backgroundColor: Colors.red,
            ),
          );
          print('❌ Error inesperado: $mensaje');
          return;
        }
      }

      // Registro básico de usuario en el backend
      if (_isWorker) {
        print('🚀 Registrando como trabajador en el backend...');
        try {
          await _registerWorker(nestJSProvider);
          print('✅ Trabajador registrado exitosamente');
        } catch (e) {
          print('❌ Error al registrar trabajador: $e');
          // No bloquear el flujo, solo mostrar warning
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Usuario registrado pero error al completar perfil de trabajador: $e',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        // Si es usuario normal, registrar usuario
        print('🚀 Registrando usuario en el backend...');
        final userResponse = await nestJSProvider.registerUser({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });
      }

      // Mostrar éxito del backend ANTES de Firebase
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('REVISA TU CORREO'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Registrar en Firebase (opcional, pero no debe bloquear el éxito del backend)
      final authProvider = context.read<AuthProvider>();
      try {
        await authProvider.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
      } catch (e) {
        // Si falla Firebase, solo muestra un warning, pero no un error fatal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Usuario creado en ChambaPE, pero ya existe en Firebase.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Navegar según tipo de usuario
      if (mounted) {
        if (_isWorker) {
          // Trabajador: ir a verificación de email
          context.go(
            '/email-verification',
            extra: {
              'email': _emailController.text.trim(),
              'isWorker': _isWorker,
            },
          );
        } else {
          // Cliente: ir directamente a su dashboard
          context.go('/client/dashboard');
        }
      }
    } catch (e) {
      print('❌ Error en registro: $e');
      String errorMsg = 'Error interno del servidor';
      String errorTitle = 'Error';
      Color backgroundColor = Colors.red;

      // Manejar errores específicos del backend
      if (e.toString().contains('emailAlreadyExists') ||
          e.toString().contains('emailExists') ||
          e.toString().contains('email already exists')) {
        errorMsg =
            'Este correo electrónico ya está registrado. Por favor, intenta con otro correo.';
        errorTitle = 'Correo existente';
        backgroundColor = Colors.orange;
      } else if (e.toString().contains('password') &&
          e.toString().contains('weak')) {
        errorMsg = 'La contraseña debe tener al menos 6 caracteres.';
        errorTitle = 'Contraseña débil';
        backgroundColor = Colors.orange;
      } else if (e.toString().contains('firstName') ||
          e.toString().contains('lastName')) {
        errorMsg = 'Por favor, completa todos los campos obligatorios.';
        errorTitle = 'Campos incompletos';
        backgroundColor = Colors.orange;
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMsg = 'Error de conexión. Verifica tu conexión a internet.';
        errorTitle = 'Error de conexión';
        backgroundColor = Colors.red;
      } else if (e.toString().contains('422')) {
        errorMsg = 'Datos inválidos. Verifica la información ingresada.';
        errorTitle = 'Datos inválidos';
        backgroundColor = Colors.orange;
      }

      _showErrorSnackBar(
        errorTitle,
        errorMsg,
        backgroundColor: backgroundColor,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerWorker(NestJSProvider nestJSProvider) async {
    print('🚀 Iniciando registro público de trabajador...');

    // Validar que todos los archivos estén presentes
    if (_dniFrontal == null ||
        _dniPosterior == null ||
        _certificatePdf == null) {
      throw Exception(
        'Todos los documentos son requeridos: DNI frontal, DNI posterior y certificado PDF',
      );
    }

    try {
      // Usar el nuevo método de registro público que incluye la subida de archivos
      final result = await nestJSProvider.registerWorkerPublic(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dniNumber: _dniController.text.trim(),
        dniFrontal: _dniFrontal!,
        dniPosterior: _dniPosterior!,
        certificatePdf: _certificatePdf!,
        description: 'Trabajador registrado en ChambaPE',
        radiusKm: 15,
      );

      print('📡 Resultado registro público trabajador: $result');
      print('✅ Trabajador registrado exitosamente');
    } catch (e) {
      print('❌ Error en registro público de trabajador: $e');

      // Manejar errores específicos del registro de trabajador
      String errorMsg = 'Error al registrar trabajador';
      String errorTitle = 'Error de registro';
      Color backgroundColor = Colors.red;

      // Extraer el tipo de error del mensaje (formato: tipo:mensaje)
      String errorString = e.toString();
      if (errorString.contains(':')) {
        final parts = errorString.split(':');
        if (parts.length >= 2) {
          final errorType = parts[0].replaceAll('Exception: ', '');
          final errorMessage = parts.sublist(1).join(':');

          switch (errorType) {
            case 'emailAlreadyExists':
              errorMsg =
                  'Este correo electrónico ya está registrado. Por favor, intenta con otro correo.';
              errorTitle = 'Correo existente';
              backgroundColor = Colors.orange;
              break;
            case 'files':
              errorMsg = errorMessage;
              errorTitle = 'Documentos faltantes';
              backgroundColor = Colors.orange;
              break;
            case 'dni':
              errorMsg = errorMessage;
              errorTitle = 'DNI inválido';
              backgroundColor = Colors.orange;
              break;
            case 'password':
              errorMsg = errorMessage;
              errorTitle = 'Contraseña inválida';
              backgroundColor = Colors.orange;
              break;
            case 'fields':
              errorMsg = errorMessage;
              errorTitle = 'Campos incompletos';
              backgroundColor = Colors.orange;
              break;
            case 'general':
              errorMsg = errorMessage;
              errorTitle = 'Error de registro';
              backgroundColor = Colors.red;
              break;
            default:
              errorMsg = errorMessage;
              errorTitle = 'Error de registro';
              backgroundColor = Colors.red;
          }
        }
      } else {
        // Fallback para errores sin formato específico
        if (errorString.contains('emailAlreadyExists') ||
            errorString.contains('emailExists') ||
            errorString.contains('email already exists')) {
          errorMsg =
              'Este correo electrónico ya está registrado. Por favor, intenta con otro correo.';
          errorTitle = 'Correo existente';
          backgroundColor = Colors.orange;
        } else if (errorString.contains('files') &&
            errorString.contains('required')) {
          errorMsg =
              'Todos los documentos son requeridos: DNI frontal, DNI posterior y certificado PDF.';
          errorTitle = 'Documentos faltantes';
          backgroundColor = Colors.orange;
        } else if (errorString.contains('dni') &&
            errorString.contains('invalid')) {
          errorMsg = 'El número de DNI ingresado no es válido.';
          errorTitle = 'DNI inválido';
          backgroundColor = Colors.orange;
        } else if (errorString.contains('validation') ||
            errorString.contains('422')) {
          errorMsg = 'Por favor, verifica que todos los datos sean correctos.';
          errorTitle = 'Datos inválidos';
          backgroundColor = Colors.orange;
        }
      }

      _showErrorSnackBar(
        errorTitle,
        errorMsg,
        backgroundColor: backgroundColor,
      );

      throw Exception('Error al registrar trabajador: $e');
    }
  }

  Future<void> _pickImage(
    ImageSource source,
    Function(File) onImagePicked,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      onImagePicked(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(theme),
                const SizedBox(height: 32),

                // Indicador de conexión
                _buildConnectionStatus(theme),
                const SizedBox(height: 24),

                // Tipo de usuario
                _buildUserTypeSelector(theme),
                const SizedBox(height: 24),

                // Formulario básico
                _buildBasicForm(theme),
                const SizedBox(height: 24),

                // Formulario de trabajador (condicional)
                if (_isWorker) ...[
                  _buildWorkerForm(theme),
                  const SizedBox(height: 24),
                ],

                // Botón de registro
                _buildRegisterButton(theme),
                const SizedBox(height: 16),

                // Enlace a login
                _buildLoginLink(theme),
              ],
            ),
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
            Icons.person_add_rounded,
            size: 40,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Crear cuenta',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Únete a ChambaPE',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            _isConnected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color:
                _isConnected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onErrorContainer,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Conectado al servidor' : 'Sin conexión al servidor',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  _isConnected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector(ThemeData theme) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de cuenta',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildUserTypeCard(
                    theme,
                    title: 'Cliente',
                    subtitle: 'Buscar trabajadores',
                    icon: Icons.person_outline,
                    isSelected: !_isWorker,
                    onTap: () => setState(() => _isWorker = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUserTypeCard(
                    theme,
                    title: 'Trabajador',
                    subtitle: 'Ofrecer servicios',
                    icon: Icons.handyman_outlined,
                    isSelected: _isWorker,
                    onTap: () => setState(() => _isWorker = true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surface,
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color:
                  isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    isSelected
                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                        : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicForm(ThemeData theme) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información personal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Nombres
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Nombres',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Apellidos
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Apellidos',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                if (!value.contains('@')) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Teléfono
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Contraseña
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                if (value.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Confirmar contraseña
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerForm(ThemeData theme) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de trabajador',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // DNI
            _buildDniField(),
            const SizedBox(height: 16),

            // Documentos requeridos
            Text(
              'Documentos requeridos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Carga de archivos DNI frontal
            DocumentUploadWidget(
              title: 'DNI Frontal',
              subtitle: 'Sube la foto frontal de tu DNI',
              icon: Icons.credit_card,
              file: _dniFrontal,
              onPickImage: (file) => setState(() => _dniFrontal = file),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Carga de archivos DNI posterior
            DocumentUploadWidget(
              title: 'DNI Posterior',
              subtitle: 'Sube la foto posterior de tu DNI',
              icon: Icons.credit_card,
              file: _dniPosterior,
              onPickImage: (file) => setState(() => _dniPosterior = file),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Carga de certificado único laboral
            DocumentUploadWidget(
              title: 'Certificado Único Laboral',
              subtitle: 'Sube tu certificado único laboral (PDF)',
              icon: Icons.picture_as_pdf,
              file: _certificatePdf,
              onPickImage: (file) => setState(() => _certificatePdf = file),
              isRequired: true,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDniField() {
    return TextFormField(
      controller: _dniController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'DNI',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () async {
            final dni = _dniController.text.trim();
            if (dni.length == 8) {
              final data = await ValidateService.getDniData(dni);
              if (data != null) {
                setState(() {
                  _firstNameController.text = data['nombres'] ?? '';
                  _lastNameController.text =
                      '${data['apellido_paterno'] ?? ''} ${data['apellido_materno'] ?? ''}'
                          .trim();
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('DNI no válido o no encontrado'),
                  ),
                );
              }
            }
          },
        ),
      ),
      validator: (value) {
        if (_isWorker) {
          if (value == null || value.isEmpty) {
            return 'Campo requerido';
          }
          if (value.length != 8) {
            return 'DNI inválido';
          }
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton(ThemeData theme) {
    return FilledButton(
      onPressed: _isConnected && !_isLoading ? _register : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child:
          _isLoading
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Text(
                _isWorker ? 'Registrar como Trabajador' : 'Crear Cuenta',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
    );
  }

  Widget _buildLoginLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿Ya tienes cuenta? ', style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Iniciar sesión'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dniController.dispose();
    super.dispose();
  }
}
