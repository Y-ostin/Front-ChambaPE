import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nestjs_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreenNew extends StatefulWidget {
  const LoginScreenNew({super.key});

  @override
  State<LoginScreenNew> createState() => _LoginScreenNewState();
}

class _LoginScreenNewState extends State<LoginScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isConnected = false;

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nestJSProvider = context.read<NestJSProvider>();
      final response = await nestJSProvider.authenticateWithNestJS(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // También autenticar en Firebase para mantener compatibilidad
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        context,
      );

      if (mounted) {
        // Navegar según el rol del usuario
        final userRole = response['user']?['role']?['name'] ?? 'user';

        if (userRole == 'worker') {
          // Verificar si el trabajador tiene servicios configurados
          try {
            final hasServices = await nestJSProvider.hasWorkerServices();

            if (!hasServices) {
              // Si no tiene servicios configurados, redirigir a completar registro
              context.go('/complete-worker-registration');
            } else {
              context.go('/worker/dashboard');
            }
          } catch (e) {
            // Si hay error al verificar servicios, redirigir a completar registro
            print('Error verificando servicios del trabajador: $e');
            context.go('/complete-worker-registration');
          }
        } else {
          context.go('/client/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de autenticación: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo y título
                  _buildHeader(theme),
                  const SizedBox(height: 48),

                  // Indicador de conexión
                  _buildConnectionStatus(theme),
                  const SizedBox(height: 32),

                  // Formulario de login
                  _buildLoginForm(theme),
                  const SizedBox(height: 24),

                  // Botón de login
                  _buildLoginButton(theme),
                  const SizedBox(height: 16),

                  // Enlaces adicionales
                  _buildAdditionalLinks(theme),
                  const SizedBox(height: 32),

                  // Botón de registro
                  _buildRegisterButton(theme),
                ],
              ),
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
            Icons.handyman_rounded,
            size: 40,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ChambaPE',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Encuentra trabajadores expertos',
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

  Widget _buildLoginForm(ThemeData theme) {
    return Column(
      children: [
        // Campo de email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'ejemplo@correo.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu correo electrónico';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Por favor ingresa un correo válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Campo de contraseña
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            hintText: 'Ingresa tu contraseña',
            prefixIcon: const Icon(Icons.lock_outlined),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton(ThemeData theme) {
    return FilledButton(
      onPressed: _isConnected && !_isLoading ? _login : null,
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
              : const Text(
                'Iniciar Sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
    );
  }

  Widget _buildAdditionalLinks(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            // TODO: Implementar recuperación de contraseña
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Función en desarrollo')),
            );
          },
          child: const Text('¿Olvidaste tu contraseña?'),
        ),
        TextButton(
          onPressed: () {
            // TODO: Implementar login con Google
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Función en desarrollo')),
            );
          },
          child: const Text('Continuar con Google'),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: () => context.go('/register'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        '¿No tienes cuenta? Regístrate',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
