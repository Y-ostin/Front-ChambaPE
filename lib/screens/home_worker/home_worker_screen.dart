import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeWorkerScreen extends StatefulWidget {
  const HomeWorkerScreen({super.key});

  @override
  State<HomeWorkerScreen> createState() => _HomeWorkerScreenState();
}

class _HomeWorkerScreenState extends State<HomeWorkerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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

    // SnackBar elegante
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              nuevoEstado == 'aceptado' ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Trabajo ${nuevoEstado == 'aceptado' ? 'aceptado' : 'rechazado'}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ],
        ),
        backgroundColor:
            nuevoEstado == 'aceptado' ? Colors.green[400] : Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getUrgencyColor(String urgencia) {
    switch (urgencia.toLowerCase()) {
      case 'alta':
        return Colors.red[400]!;
      case 'media':
        return Colors.orange[400]!;
      case 'baja':
        return Colors.green[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getServiceIcon(String servicio) {
    switch (servicio.toLowerCase()) {
      case 'electricidad':
        return Icons.electrical_services;
      case 'gasfitería':
        return Icons.plumbing;
      case 'carpintería':
        return Icons.handyman;
      case 'pintura':
        return Icons.format_paint;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header personalizado
              _buildHeader(context),

              // Contenido principal
              Expanded(
                child:
                    availableJobs.isEmpty
                        ? _buildEmptyState()
                        : _buildJobsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final pendingJobs =
        availableJobs.where((job) => job['estado'] == 'pendiente').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trabajos Disponibles',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pendingJobs trabajos pendientes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderActions(context),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Row(
      children: [
        _buildHeaderButton(
          Icons.history,
          'Historial',
          () => context.go('/workerHistory'),
        ),
        const SizedBox(width: 8),
        _buildHeaderButton(
          Icons.person_outline,
          'Perfil',
          () => context.go('/workerProfile'),
        ),
        const SizedBox(width: 8),
        _buildHeaderButton(
          Icons.logout,
          'Salir',
          () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.grey[700]),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildQuickStats() {
    final acceptedJobs =
        availableJobs.where((job) => job['estado'] == 'aceptado').length;
    final rejectedJobs =
        availableJobs.where((job) => job['estado'] == 'rechazado').length;
    final pendingJobs =
        availableJobs.where((job) => job['estado'] == 'pendiente').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Pendientes', pendingJobs, Colors.blue[400]!),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Aceptados', acceptedJobs, Colors.green[400]!),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Rechazados', rejectedJobs, Colors.red[400]!),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(Icons.work_outline, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay trabajos disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los nuevos trabajos aparecerán aquí',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: availableJobs.length,
      itemBuilder: (context, index) {
        final job = availableJobs[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildJobCard(job, index),
        );
      },
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, int index) {
    final isExpanded = job['estado'] == 'pendiente';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la tarjeta
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono del servicio
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getServiceIcon(job['servicio']),
                    color: Colors.blue[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job['servicio'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _buildUrgencyBadge(job['urgencia']),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['cliente'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detalles expandidos
          if (isExpanded) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildDetailRow(Icons.location_on, job['direccion']),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.schedule, job['horario']),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.description, job['descripcion']),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.attach_money, job['presupuesto']),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Rechazar',
                      Colors.red[50]!,
                      Colors.red[400]!,
                      Icons.close,
                      () => actualizarEstado(index, 'rechazado'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Aceptar',
                      Colors.green[50]!,
                      Colors.green[400]!,
                      Icons.check,
                      () => actualizarEstado(index, 'aceptado'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Estado final
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    job['estado'] == 'aceptado'
                        ? Colors.green[50]
                        : Colors.red[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    job['estado'] == 'aceptado'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color:
                        job['estado'] == 'aceptado'
                            ? Colors.green[400]
                            : Colors.red[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    job['estado'].toUpperCase(),
                    style: TextStyle(
                      color:
                          job['estado'] == 'aceptado'
                              ? Colors.green[400]
                              : Colors.red[400],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    Color backgroundColor,
    Color textColor,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: textColor.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
