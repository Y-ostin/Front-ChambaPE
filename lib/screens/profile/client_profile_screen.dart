import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nestjs_provider.dart';
import '../../models/app_user.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  AppUser? _user;

  AppUser? _getInitialUser() {
    final authUser = context.read<AuthProvider>().currentUser;
    if (authUser != null) return authUser;
    final nest = context.read<NestJSProvider>().currentUser;
    if (nest != null) {
      return AppUser(
        uid: nest['id'].toString(),
        email: nest['email'] ?? '',
        name: '${nest['firstName'] ?? ''} ${nest['lastName'] ?? ''}'.trim(),
        phone: nest['phone'],
        address: nest['address'],
        role: nest['role']?['name'] ?? 'USER',
        isActive: nest['status']?['name'] == 'active',
        photoURL: null,
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _user = _getInitialUser();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authUser = context.read<AuthProvider>().currentUser;
    if (authUser != null && authUser.phone != null) {
      setState(() => _user = authUser);
      return;
    }

    final profileRes = await ApiService.getProfile();
    if (profileRes['success'] == true && profileRes['data'] != null) {
      final data = profileRes['data'];
      setState(() {
        _user = AppUser(
          uid: data['id'].toString(),
          email: data['email'] ?? '',
          name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          phone: data['phone'] ?? data['phoneNumber'],
          address: data['address'],
          role: data['role']?['name'] ?? 'USER',
          isActive: data['status']?['name'] == 'active',
          photoURL: null,
        );
      });
    } else {
      if (authUser != null) {
        setState(() => _user = authUser);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/client/dashboard'),
        ),
      ),
      body:
          _user == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20),
                child: _buildProfile(_user!, context),
              ),
    );
  }

  Widget _buildProfile(AppUser user, BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Teléfono'),
              subtitle: Text(user.phone ?? '-'),
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Rol'),
              subtitle: Text(user.role),
            ),
          ],
        ),
      ),
    );
  }
}
