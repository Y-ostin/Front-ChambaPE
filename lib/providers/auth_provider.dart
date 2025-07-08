import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/app_user.dart';
import 'package:provider/provider.dart';
import 'nestjs_provider.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  AppUser? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  AppUser? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Verificar estado de autenticación al iniciar
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar usuario de Firebase
      _user = _auth.currentUser;

      // Si hay usuario, obtener perfil del backend
      if (_user != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      _errorMessage = 'Error al verificar autenticación: $e';
      print(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login con email y contraseña (Backend + Firebase)
  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Login en el backend usando NestJSProvider para mantener consistencia
      final nestJSProvider = context.read<NestJSProvider>();
      final backendResult = await nestJSProvider.authenticateWithNestJS(
        email,
        password,
      );

      // 2. Intentar login en Firebase (puede fallar si el usuario sólo existe en backend)
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        _user = credential.user;
      } on FirebaseAuthException catch (e) {
        // Si el usuario no existe en Firebase o contraseña incorrecta,
        // continuamos con la sesión del backend.
        print('Firebase login failed: \\(e.code). Continuando con backend.');
        _user = null;
      }

      // 3. Cargar perfil del usuario
      await _loadUserProfile();

      // 4. Si es trabajador, verificar si necesita completar registro
      if (_currentUser?.role == 'WORKER' ||
          _currentUser?.role == 'trabajador') {
        final hasServices = await nestJSProvider.hasWorkerServices();
        if (!hasServices) {
          // Redirigir a completar registro
          context.go('/complete-worker-registration');
          return;
        }
      }
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Registro (Backend + Firebase)
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Registro en el backend
      final backendResult = await ApiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (!backendResult['success']) {
        throw Exception(backendResult['message']);
      }

      // 2. Registro en Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Actualizar perfil en Firebase
      await credential.user?.updateDisplayName('$firstName $lastName');

      _user = credential.user;
    } catch (e) {
      _errorMessage = 'Error al registrar: $e';
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login con Google
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      // Verificar si el usuario existe en el backend
      if (_user != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión con Google: $e';
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('AuthProvider.logout(): iniciando logout');
      await _auth.signOut();
      await _googleSignIn.signOut();
      await ApiService.logout();

      // Limpiar inmediatamente estado y token de NestJS para que GoRouter detecte la desautenticación
      context.read<NestJSProvider>().clearAuth();
      _user = null;
      _currentUser = null;
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
      print('Logout error: $e');
    } finally {
      print(
        'AuthProvider.logout(): logout finalizado - isAuthenticated Firebase: ${_auth.currentUser == null}',
      );

      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar perfil del usuario desde el backend
  Future<void> _loadUserProfile() async {
    try {
      final profileResult = await ApiService.getProfile();

      if (profileResult['success']) {
        _userProfile = profileResult['data'];
        // Crear AppUser desde los datos del backend
        if (_userProfile != null && _user != null) {
          _currentUser = AppUser(
            uid: _user!.uid,
            email: _userProfile!['email'] ?? _user!.email ?? '',
            name:
                '${_userProfile!['firstName'] ?? ''} ${_userProfile!['lastName'] ?? ''}'
                    .trim(),
            phone: _userProfile!['phone'],
            address: _userProfile!['address'],
            role: _userProfile!['role']?['name'] ?? 'USER',
            isActive: _userProfile!['isActive'] ?? true,
            photoURL: _user!.photoURL,
          );
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Logout/SignOut
  Future<void> signOut(BuildContext context) async {
    await logout(context);
  }

  // Método para eliminar cuenta
  Future<void> deleteAccountWithReauth(String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_user != null) {
        // Re-autenticar antes de eliminar
        final credential = EmailAuthProvider.credential(
          email: _user!.email!,
          password: password,
        );
        await _user!.reauthenticateWithCredential(credential);

        // Eliminar usuario de Firebase
        await _user!.delete();

        // Limpiar estado
        _user = null;
        _currentUser = null;
        _userProfile = null;
        await ApiService.logout();
      }
    } catch (e) {
      _errorMessage = 'Error al eliminar cuenta: $e';
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos auxiliares
  bool get isWorker =>
      _currentUser?.role == 'WORKER' || _currentUser?.role == 'trabajador';
  bool get isClient =>
      _currentUser?.role == 'USER' || _currentUser?.role == 'cliente';
  String get fullName => _currentUser?.name ?? '';
}
