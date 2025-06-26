import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HomeWorkerScreen extends StatefulWidget {
  const HomeWorkerScreen({super.key});

  @override
  State<HomeWorkerScreen> createState() => _HomeWorkerScreenState();
}

class _HomeWorkerScreenState extends State<HomeWorkerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> availableJobs = [
    {
      'cliente': 'María López',
      'direccion': 'Av. Ejemplo 123, Arequipa',
      'servicio': 'Electricidad',
      'urgencia': 'Media',
      'horario': 'Hoy 4:00 PM',
      'estado': 'pendiente',
      'descripcion': 'Instalación de luminarias en sala principal',
      'presupuesto': 'S/. 80 - 120',
      'distancia': '2.5 km',
      'tiempoEstimado': '2-3 horas',
    },
    {
      'cliente': 'Juan Pérez',
      'direccion': 'Calle Falsa 456, Arequipa',
      'servicio': 'Gasfitería',
      'urgencia': 'Alta',
      'horario': 'Mañana 10:00 AM',
      'estado': 'pendiente',
      'descripcion': 'Reparación urgente de tubería con fuga',
      'presupuesto': 'S/. 100 - 150',
      'distancia': '1.2 km',
      'tiempoEstimado': '1-2 horas',
    },
    {
      'cliente': 'Ana García',
      'direccion': 'Jr. Los Pinos 789, Arequipa',
      'servicio': 'Carpintería',
      'urgencia': 'Baja',
      'horario': 'Pasado mañana 2:00 PM',
      'estado': 'pendiente',
      'descripcion': 'Reparación de puerta principal',
      'presupuesto': 'S/. 60 - 90',
      'distancia': '3.8 km',
      'tiempoEstimado': '1-2 horas',
    },
  ];

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void actualizarEstado(int index, String nuevoEstado) {
    setState(() {
      availableJobs[index]['estado'] = nuevoEstado;
    });

    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              nuevoEstado == 'aceptado'
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: colorScheme.onInverseSurface,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Trabajo ${nuevoEstado == 'aceptado' ? 'aceptado' : 'rechazado'}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: colorScheme.onInverseSurface,
              ),
            ),
          ],
        ),
        backgroundColor:
            nuevoEstado == 'aceptado' ? colorScheme.primary : colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getUrgencyColor(String urgencia) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (urgencia.toLowerCase()) {
      case 'alta':
        return colorScheme.error;
      case 'media':
        return colorScheme.tertiary;
      case 'baja':
        return colorScheme.primary;
      default:
        return colorScheme.outline;
    }
  }

  IconData _getServiceIcon(String servicio) {
    switch (servicio.toLowerCase()) {
      case 'electricidad':
        return Icons.electrical_services_rounded;
      case 'gasfitería':
        return Icons.plumbing_rounded;
      case 'carpintería':
        return Icons.handyman_rounded;
      case 'pintura':
        return Icons.format_paint_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header moderno similar al cliente
                _buildHeader(),

                // Contenido principal con scroll
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner de servicios disponibles
                        _buildServiceBanner(),

                        // Estadísticas rápidas
                        _buildQuickStats(),

                        // Trabajos disponibles
                        _buildAvailableJobsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _animationController.reset();
            _animationController.forward();
          });
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Actualizar'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trabajos Disponibles',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${availableJobs.where((job) => job['estado'] == 'pendiente').length} trabajos disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                onPressed: () => context.go('/workerHistory'),
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Historial',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainer,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => context.go('/workerChats'),
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Chats',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainer,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => context.go('/workerProfile'),
                icon: const Icon(Icons.person_rounded),
                tooltip: 'Perfil',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainer,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Salir',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBanner() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.work_rounded,
                        color: colorScheme.onPrimary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Trabajos 24/7',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encuentra trabajos disponibles en tu área',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onPrimary.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.search_rounded,
                color: colorScheme.onPrimary,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final colorScheme = Theme.of(context).colorScheme;
    final acceptedJobs =
        availableJobs.where((job) => job['estado'] == 'aceptado').length;
    final rejectedJobs =
        availableJobs.where((job) => job['estado'] == 'rechazado').length;
    final pendingJobs =
        availableJobs.where((job) => job['estado'] == 'pendiente').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Pendientes',
              pendingJobs,
              colorScheme.primary,
              Icons.schedule_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Aceptados',
              acceptedJobs,
              colorScheme.tertiary,
              Icons.check_circle_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Rechazados',
              rejectedJobs,
              colorScheme.error,
              Icons.cancel_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Trabajos Disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Ver todos los trabajos
                },
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (availableJobs.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableJobs.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildJobCard(availableJobs[index], index),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.work_outline_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay trabajos disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los nuevos trabajos aparecerán aquí',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = job['estado'] != 'pendiente';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la tarjeta
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar del técnico
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getServiceIcon(job['servicio']),
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Información del cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['cliente'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['servicio'],
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            job['distancia'],
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge de urgencia
                _buildUrgencyBadge(job['urgencia']),
              ],
            ),
          ),

          // Detalles del trabajo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildDetailRow(Icons.description_rounded, job['descripcion']),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.schedule_rounded, job['horario']),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on_rounded, job['direccion']),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      job['presupuesto'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      job['tiempoEstimado'],
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botones de acción o estado
          if (!isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => actualizarEstado(index, 'rechazado'),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => actualizarEstado(index, 'aceptado'),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Aceptar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Estado final
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    job['estado'] == 'aceptado'
                        ? colorScheme.primaryContainer.withOpacity(0.5)
                        : colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    job['estado'] == 'aceptado'
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color:
                        job['estado'] == 'aceptado'
                            ? colorScheme.primary
                            : colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    job['estado'].toUpperCase(),
                    style: TextStyle(
                      color:
                          job['estado'] == 'aceptado'
                              ? colorScheme.primary
                              : colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(String urgencia) {
    final color = _getUrgencyColor(urgencia);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        urgencia,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.logout_rounded, color: colorScheme.error, size: 28),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
                context.go('/');
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
