import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _status = 'Listo para testing';
  bool _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = 'demo@chambaipe.com';
    _passwordController.text = 'secret123';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChambaPE API Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status de conexión
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status, 
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            
            // Campos de entrada
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'demo@chambaipe.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'secret123',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            // Estado de autenticación
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: authProvider.isAuthenticated 
                      ? Colors.green.shade100 
                      : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        authProvider.isAuthenticated 
                          ? Icons.check_circle 
                          : Icons.warning,
                        color: authProvider.isAuthenticated 
                          ? Colors.green 
                          : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authProvider.isAuthenticated
                            ? 'Autenticado: ${authProvider.currentUser?.email ?? ""}'
                            : 'No autenticado',
                          style: TextStyle(
                            color: authProvider.isAuthenticated 
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            
            // Botones de testing
            if (_loading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: ListView(
                  children: [
                    _buildTestButton('🔗 Test Conexión', _testConnection),
                    _buildTestButton('📝 Crear Usuario Demo', _createDemoUser),
                    _buildTestButton('🔐 Login con AuthProvider', _testLoginProvider),
                    _buildTestButton('🔓 Login Directo API', _testLoginDirect),
                    _buildTestButton('👤 Mi Perfil', _testProfile),
                    _buildTestButton('📋 Categorías', _testCategories),
                    _buildTestButton('👷 Trabajadores Cercanos', _testNearbyWorkers),
                    _buildTestButton('📍 Registrar Trabajador', _testWorkerRegister),
                    _buildTestButton('💼 Crear Trabajo', _testCreateJob),
                    _buildTestButton('📋 Mis Trabajos', _testMyJobs),
                    _buildTestButton('🚪 Logout', _testLogout),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _status = 'Probando conexión con backend...';
    });

    final isConnected = await ApiService.checkConnection();
    
    setState(() {
      _loading = false;
      _status = isConnected 
        ? '✅ Conexión exitosa con el backend'
        : '❌ Error de conexión. Verifica que el backend esté corriendo en puerto 3000';
    });
  }

  Future<void> _createDemoUser() async {
    setState(() {
      _loading = true;
      _status = 'Creando usuario demo...';
    });

    final result = await ApiService.register(
      email: 'demo@chambaipe.com',
      password: 'secret123',
      firstName: 'Demo',
      lastName: 'User',
    );

    setState(() {
      _loading = false;
      _status = result['success'] 
        ? '✅ Usuario demo creado exitosamente.\n📧 Email: demo@chambaipe.com\n🔑 Password: secret123\n⚠️ Verifica el email en MailDev (http://localhost:1080)'
        : '❌ Error al crear usuario: ${result['message']}';
    });
  }

  Future<void> _testLoginProvider() async {
    final email = _emailController.text.isNotEmpty 
      ? _emailController.text 
      : 'demo@chambaipe.com';
    final password = _passwordController.text.isNotEmpty 
      ? _passwordController.text 
      : 'secret123';

    setState(() {
      _loading = true;
      _status = 'Iniciando sesión con AuthProvider...';
    });

    try {
      await context.read<AuthProvider>().login(email, password);
      setState(() {
        _status = '✅ Login exitoso con AuthProvider. Usuario autenticado.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error en login con AuthProvider: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _testLoginDirect() async {
    final email = _emailController.text.isNotEmpty 
      ? _emailController.text 
      : 'demo@chambaipe.com';
    final password = _passwordController.text.isNotEmpty 
      ? _passwordController.text 
      : 'secret123';

    setState(() {
      _loading = true;
      _status = 'Iniciando sesión directamente con API...';
    });

    final result = await ApiService.login(email: email, password: password);

    setState(() {
      _loading = false;
      _status = result['success'] 
        ? '✅ Login directo exitoso. Token guardado en ApiService.'
        : '❌ Error en login directo: ${result['message']}';
    });
  }

  Future<void> _testProfile() async {
    setState(() {
      _loading = true;
      _status = 'Obteniendo perfil del usuario...';
    });

    final result = await ApiService.getProfile();

    setState(() {
      _loading = false;
      _status = result['success'] 
        ? '✅ Perfil obtenido:\n📧 Email: ${result['data']['email']}\n👤 Nombre: ${result['data']['firstName']} ${result['data']['lastName']}\n🎭 Rol: ${result['data']['role']['name']}'
        : '❌ Error al obtener perfil: ${result['message']}';
    });
  }

  Future<void> _testCategories() async {
    setState(() {
      _loading = true;
      _status = 'Obteniendo categorías de servicios...';
    });

    final categories = await ApiService.getServiceCategories();

    setState(() {
      _loading = false;
      _status = categories.isNotEmpty 
        ? '✅ ${categories.length} categorías obtenidas:\n${categories.map((cat) => '• ${cat['name']}').join('\n')}'
        : '❌ No se pudieron obtener categorías';
    });
  }

  Future<void> _testNearbyWorkers() async {
    setState(() {
      _loading = true;
      _status = 'Buscando trabajadores cercanos...';
    });

    final workers = await ApiService.getNearbyWorkers(
      latitude: -12.0464, // Lima, Perú
      longitude: -77.0428,
      radiusKm: 10.0,
    );

    setState(() {
      _loading = false;
      _status = '✅ ${workers.length} trabajadores encontrados cerca de Lima, Perú';
    });
  }

  Future<void> _testWorkerRegister() async {
    setState(() {
      _loading = true;
      _status = 'Registrando como trabajador...';
    });

    final result = await ApiService.registerWorker(
      phoneNumber: '+51999999999',
      latitude: -12.0464,
      longitude: -77.0428,
      address: 'Lima, Perú',
      specialty: 'Plomería',
      bio: 'Plomero con 5 años de experiencia',
    );

    setState(() {
      _loading = false;
      _status = result['success'] 
        ? '✅ Perfil de trabajador registrado exitosamente'
        : '❌ Error al registrar trabajador: ${result['message']}';
    });
  }

  Future<void> _testCreateJob() async {
    setState(() {
      _loading = true;
      _status = 'Creando trabajo de prueba...';
    });

    final result = await ApiService.createJob(
      title: 'Reparación de tubería',
      description: 'Necesito reparar una tubería que está goteando en el baño',
      serviceCategoryId: 2, // Asumiendo que existe esta categoría
      latitude: -12.0464,
      longitude: -77.0428,
      address: 'Lima, Perú',
      estimatedBudget: 150.0,
    );

    setState(() {
      _loading = false;
      _status = result['success'] 
        ? '✅ Trabajo creado exitosamente'
        : '❌ Error al crear trabajo: ${result['message']}';
    });
  }

  Future<void> _testMyJobs() async {
    setState(() {
      _loading = true;
      _status = 'Obteniendo mis trabajos...';
    });

    final jobs = await ApiService.getMyJobs();

    setState(() {
      _loading = false;
      _status = '✅ ${jobs.length} trabajos encontrados';
    });
  }

  Future<void> _testLogout() async {
    setState(() {
      _loading = true;
      _status = 'Cerrando sesión...';
    });

    try {
      await context.read<AuthProvider>().logout();
      setState(() {
        _status = '✅ Sesión cerrada exitosamente';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error al cerrar sesión: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
