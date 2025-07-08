import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../providers/nestjs_provider.dart';

class WorkerAvailabilityScreen extends StatefulWidget {
  const WorkerAvailabilityScreen({super.key});

  @override
  State<WorkerAvailabilityScreen> createState() => _WorkerAvailabilityScreenState();
}

class _WorkerAvailabilityScreenState extends State<WorkerAvailabilityScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _setAvailability(bool available) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final nestJSProvider = context.read<NestJSProvider>();
    try {
      bool disponibleOk = false; // Declarar aquí
      if (available) {
        // Pedir permisos de ubicación
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Permiso de ubicación denegado. No podrás recibir ofertas.';
            _isLoading = false;
          });
          return;
        }
        // Obtener ubicación
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        // Cambiar estado de disponibilidad con ubicación
        disponibleOk = await nestJSProvider.toggleActiveToday(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        // Solo cambiar estado de disponibilidad (sin ubicación)
        disponibleOk = await nestJSProvider.toggleActiveToday();
      }
      if (disponibleOk) {
        if (available) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Estás disponible y tu ubicación ha sido actualizada!'),
              backgroundColor: Colors.green,
            ),
          );
      } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hoy no recibirás ofertas. Puedes cambiar tu estado cuando quieras.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        context.go('/worker/dashboard');
      } else {
        setState(() {
          _errorMessage = 'Error al cambiar el estado de disponibilidad.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilidad de Hoy'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                '¿Hoy quieres trabajar?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Si eliges "Sí", se pedirá tu ubicación actual para que los clientes cercanos puedan encontrarte y recibirás ofertas automáticamente. Si eliges "No", no recibirás ofertas hoy.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _setAvailability(true),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Sí, estoy disponible'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _setAvailability(false),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('No, hoy no trabajo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (_isLoading) ...[
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 