import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/nestjs_provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isActiveToday = false;
  bool _isLoading = false;

  Timer? _pollingTimer;
  Timer? _offerTimer;
  Map<String, dynamic>? _currentOffer;
  int _offerSecondsLeft = 30;
  bool _showOfferPush = false;
  Position? _currentPosition;

  // Mock data - después se cargará del backend
  final Map<String, dynamic> _stats = {
    'totalJobsCompleted': 0,
    'totalEarnings': 0.0,
    'averageRating': 0.0,
    'jobsThisWeek': 0,
    'availableJobsNearby': 0,
  };

  final List<Map<String, dynamic>> _availableJobs = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    _loadWorkerData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollingTimer?.cancel();
    _offerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWorkerData() async {
    setState(() => _isLoading = true);
    try {
      final nestJSProvider = context.read<NestJSProvider>();
      final stats = await nestJSProvider.getWorkerDashboardStats();
      final jobs = await nestJSProvider.getWorkerAvailableJobs();
      final profile = await nestJSProvider.getWorkerProfile();

      if (profile != null && profile['isActiveToday'] != null) {
        _isActiveToday = profile['isActiveToday'] as bool;
      }

      if (stats != null) {
        _stats.addAll(stats);
      }

      _availableJobs
        ..clear()
        ..addAll(jobs);

      _stats['availableJobsNearby'] = _availableJobs.length;
    } catch (e) {
      print('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActiveToday() async {
    setState(() => _isLoading = true);

    try {
      final nestJSProvider = context.read<NestJSProvider>();
      bool success = false;

      if (!_isActiveToday) {
        // Vamos a ACTIVAR disponibilidad → necesitamos ubicación
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception(
              'Permiso de ubicación denegado. Actívalo para recibir trabajos.');
        }

        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        success = await nestJSProvider.toggleActiveToday(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        // Desactivando – no necesitamos enviar ubicación
        success = await nestJSProvider.toggleActiveToday();
      }

      if (!success) {
        throw Exception('No se pudo actualizar la disponibilidad');
      }

      // Actualizar estado local y recargar datos
      setState(() => _isActiveToday = !_isActiveToday);
      
      // Recargar datos y manejar polling según el estado
      await _loadWorkerData();
      if (_isActiveToday) {
        await _requestLocationAndStartPolling();
      } else {
        _stopPolling();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isActiveToday
              ? '✅ Ahora estás disponible para recibir trabajos'
              : '⏸️ Has pausado la recepción de trabajos'),
          backgroundColor: _isActiveToday ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocationAndStartPolling() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
      _currentPosition = await Geolocator.getCurrentPosition();
      _startPolling();
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de ubicación: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isActiveToday = false);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollForOffers());
    _pollForOffers();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _offerTimer?.cancel();
    setState(() {
      _showOfferPush = false;
      _currentOffer = null;
      _offerSecondsLeft = 30;
    });
  }

  Future<void> _pollForOffers() async {
    if (!_isActiveToday || _showOfferPush) return;
    try {
      final nestJSProvider = context.read<NestJSProvider>();
      final matches = await nestJSProvider.getMyMatches(
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );
      if (matches.isNotEmpty) {
        setState(() {
          _currentOffer = matches[0];
          _showOfferPush = true;
          _offerSecondsLeft = 30;
        });
        _startOfferTimer();
      }
    } catch (e) {
      print('Error polling matches: $e');
    }
  }

  void _startOfferTimer() {
    _offerTimer?.cancel();
    _offerTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_offerSecondsLeft <= 1) {
        timer.cancel();
        await _handleOfferTimeout();
      } else {
        setState(() {
          _offerSecondsLeft--;
        });
      }
    });
  }

  Future<void> _handleOfferTimeout() async {
    if (_currentOffer != null) {
      final nestJSProvider = context.read<NestJSProvider>();
      try {
        await nestJSProvider.rejectMatch(_currentOffer!['id'], reason: 'timeout');
      } catch (e) {
        print('Error rechazando por timeout: $e');
      }
    }
    setState(() {
      _showOfferPush = false;
      _currentOffer = null;
      _offerSecondsLeft = 30;
    });
    // Buscar siguiente oferta
    _pollForOffers();
  }

  Future<void> _acceptCurrentOffer() async {
    if (_currentOffer != null) {
      final nestJSProvider = context.read<NestJSProvider>();
      try {
        await nestJSProvider.acceptMatch(_currentOffer!['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Trabajo aceptado exitosamente'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() {
      _showOfferPush = false;
      _currentOffer = null;
      _offerSecondsLeft = 30;
    });
    // Buscar siguiente oferta
    _pollForOffers();
  }

  Future<void> _rejectCurrentOffer() async {
    if (_currentOffer != null) {
      final nestJSProvider = context.read<NestJSProvider>();
      try {
        await nestJSProvider.rejectMatch(_currentOffer!['id'], reason: 'manual');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Trabajo rechazado'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() {
      _showOfferPush = false;
      _currentOffer = null;
      _offerSecondsLeft = 30;
    });
    // Buscar siguiente oferta
    _pollForOffers();
  }

  Widget _buildOfferPush() {
    if (!_showOfferPush || _currentOffer == null) return const SizedBox.shrink();
    final offer = _currentOffer!;
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    offer['job']?['title'] ?? 'Oferta de trabajo',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text('$_offerSecondsLeft', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(offer['job']?['description'] ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(offer['job']?['location'] ?? '', style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('S/. ${offer['job']?['estimatedEarnings'] ?? ''}', style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _rejectCurrentOffer,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _acceptCurrentOffer,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptJob(int jobId) async {
    try {
      final nestJSProvider = context.read<NestJSProvider>();
      await nestJSProvider.acceptJob(jobId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Trabajo aceptado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Remover el trabajo de la lista
      setState(() {
        _availableJobs.removeWhere((job) => job['id'] == jobId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectJob(int jobId) async {
    try {
      final nestJSProvider = context.read<NestJSProvider>();
      await nestJSProvider.rejectJob(jobId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Trabajo rechazado'),
          backgroundColor: Colors.orange,
        ),
      );

      // Remover el trabajo de la lista
      setState(() {
        _availableJobs.removeWhere((job) => job['id'] == jobId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Hola!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      '¿Listo para trabajar?',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/worker/profile'),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Toggle de disponibilidad
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    _isActiveToday ? Icons.work : Icons.pause_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isActiveToday ? 'Disponible' : 'No disponible',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _isActiveToday
                              ? 'Recibiendo ofertas de trabajo'
                              : 'No recibirás ofertas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActiveToday,
                    onChanged:
                        _isLoading ? null : (value) => _toggleActiveToday(),
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Trabajos\nCompletados',
                  '${_stats['totalJobsCompleted']}',
                  Icons.work,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Ganancias\nTotales',
                  'S/. ${_stats['totalEarnings']}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Calificación\nPromedio',
                  '${_stats['averageRating']}',
                  Icons.star,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Trabajos\nEsta Semana',
                  '${_stats['jobsThisWeek']}',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trabajos Disponibles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_availableJobs.length} disponibles',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_availableJobs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No hay trabajos disponibles',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activa tu disponibilidad para recibir ofertas',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableJobs.length,
              itemBuilder: (context, index) {
                final job = _availableJobs[index];
                return _buildJobCard(job);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final urgencyColor = _getUrgencyColor(job['urgency']);
    final timeLeft = job['expiresAt'].difference(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job['urgency'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: urgencyColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  job['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job['location'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${job['distanceKm']} km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'S/. ${job['estimatedEarnings']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                if (timeLeft.isNegative)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Expirado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Expira en ${timeLeft.inMinutes} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (!timeLeft.isNegative)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectJob(job['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptJob(job['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildStatsSection(),
                              _buildAvailableJobsSection(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
          _buildOfferPush(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadWorkerData,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
