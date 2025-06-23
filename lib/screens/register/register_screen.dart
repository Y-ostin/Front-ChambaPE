import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  String selectedRole = 'cliente';
  bool isLoading = false;

  Future<void> _registerUser() async {
    setState(() => isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'email': emailController.text.trim(),
            'name': nameController.text.trim(),
            'role': selectedRole,
            'uid': credential.user!.uid,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );

      context.pop();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Crear cuenta',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Nombre completo',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                onChanged: (value) {
                  if (value != null) setState(() => selectedRole = value);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                items: const [
                  DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                  DropdownMenuItem(
                    value: 'trabajador',
                    child: Text('Trabajador'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Registrarse'),
                  ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
