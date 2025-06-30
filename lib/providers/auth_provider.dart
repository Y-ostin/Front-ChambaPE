import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final String? name;
  final String? phone;
  final String? address;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.phone,
    this.address,
  });
}

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  StreamSubscription<User?>? _authStateSubscription;
  bool _disposed = false;

  // Constructor que escucha cambios de estado de autenticación
  AuthProvider() {
    _authStateSubscription = _auth.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Maneja cambios automáticos en el estado de autenticación
  void _onAuthStateChanged(User? user) async {
    if (_disposed) return; // Evita notificar si el provider ya fue disposed

    if (user == null) {
      _currentUser = null;
    } else {
      // Solo carga datos si no tenemos usuario actual
      if (_currentUser?.uid != user.uid) {
        await _loadUserData(user);
      }
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Carga datos del usuario desde Firestore
  Future<void> _loadUserData(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = AppUser(
          uid: user.uid,
          email: data['email'] ?? user.email ?? '',
          role: data['role'] ?? 'cliente',
          name: data['name'],
          phone: data['phone'],
          address: data['address'],
        );

        // Si es trabajador, cargar información adicional
        if (data['role'] == 'trabajador') {
          await _loadWorkerData(user.uid);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Carga información específica del trabajador
  Future<void> _loadWorkerData(String uid) async {
    try {
      final workerDoc = await _firestore.collection('workers').doc(uid).get();

      if (workerDoc.exists) {
        final workerData = workerDoc.data()!;
        // Actualizar el usuario actual con información del trabajador
        _currentUser = AppUser(
          uid: _currentUser!.uid,
          email: _currentUser!.email,
          role: _currentUser!.role,
          name: _currentUser!.name,
          phone: workerData['phone'] ?? _currentUser!.phone,
          address: workerData['address'] ?? _currentUser!.address,
        );
      }
    } catch (e) {
      print('Error loading worker data: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc =
          await _firestore.collection('users').doc(cred.user!.uid).get();

      if (!doc.exists) {
        throw Exception('El usuario no tiene datos registrados en Firestore.');
      }

      final data = doc.data()!;
      _currentUser = AppUser(
        uid: cred.user!.uid,
        email: data['email'] ?? '',
        role: data['role'] ?? 'cliente',
        name: data['name'],
        phone: data['phone'],
        address: data['address'],
      );

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // Usuario canceló

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      final userDoc =
          await _firestore.collection('users').doc(userCred.user!.uid).get();

      if (!userDoc.exists) {
        // Si es su primer login, lo guardamos en Firestore
        await _firestore.collection('users').doc(userCred.user!.uid).set({
          'name': userCred.user!.displayName ?? '',
          'email': userCred.user!.email ?? '',
          'role': 'cliente',
          'uid': userCred.user!.uid,
        });
      }

      _currentUser = AppUser(
        uid: userCred.user!.uid,
        email: userCred.user!.email ?? '',
        role: userDoc.data()?['role'] ?? 'cliente',
        name: userDoc.data()?['name'],
        phone: userDoc.data()?['phone'],
        address: userDoc.data()?['address'],
      );
      notifyListeners();
    } catch (e) {
      throw Exception('Error en Google Sign-In: $e');
    }
  }

  // Método de logout mejorado
  Future<void> logout() async {
    try {
      // Cierra sesión en Google si está activa
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Cierra sesión en Firebase Auth
      await _auth.signOut();

      // Limpia el usuario actual
      _currentUser = null;

      // Notifica los cambios
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
      // Incluso si hay error, limpia el estado local
      _currentUser = null;
      notifyListeners();
    }
  }

  // Método para verificar si hay una sesión activa al iniciar la app
  Future<void> checkAuthStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user);
    }
  }

  // Método para cerrar sesión (alias de logout)
  Future<void> signOut() async {
    await logout();
  }
}
