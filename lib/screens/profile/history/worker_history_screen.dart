import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkerHistoryScreen extends StatefulWidget {
  const WorkerHistoryScreen({super.key});

  @override
  State<WorkerHistoryScreen> createState() => _WorkerHistoryScreenState();
}

class _WorkerHistoryScreenState extends State<WorkerHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedFilter = 'Todos';
  final List<String> filterOptions = ['Todos', 'Completados', 'Cancelados'];

  final List<Map<String, dynamic>> mockHistory = [
    {
      'cliente': 'María López',
      'servicio': 'Electricidad',
      'fecha': '10/06/2025',
      'hora': '14:30',
      'calificacion': 5.0,
      'comentario': 'Excelente servicio, muy puntual y profesional.',
      'ganancia': 120.0,
      'estado': 'completado',
      'duracion': '2 horas',
      'ubicacion': 'Av. Ejemplo 123, Arequipa',
    },
    {
      'cliente': 'Pedro Ruiz',
      'servicio': 'Gasfitería',
      'fecha': '07/06/2025',
      'hora': '10:15',
      'calificacion': 4.5,
      'comentario': 'Buen trabajo aunque tardó un poco más de lo esperado.',
      'ganancia': 95.0,
      'estado': 'completado',
      'duracion': '1.5 horas',
      'ubicacion': 'Calle Falsa 456, Arequipa',
    },
    {
      'cliente': 'Sofía García',
      'servicio': 'Instalación de luces LED',
      'fecha': '03/06/2025',
      'hora': '16:00',
      'calificacion': 4.0,
      'comentario': 'Recomendado, pero podría mejorar en limpieza.',
      'ganancia': 80.0,
      'estado': 'completado',
      'duracion': '1 hora',
      'ubicacion': 'Jr. Los Pinos 789, Arequipa',
    },
    {
      'cliente': 'Carlos Mendoza',
      'servicio': 'Carpintería',
      'fecha': '28/05/2025',
      'hora': '09:00',
      'calificacion': 0.0,
      'comentario': 'Cliente canceló el servicio',
      'ganancia': 0.0,
      'estado': 'cancelado',
      'duracion': '0 horas',
      'ubicacion': 'Av. Independencia 321, Arequipa',
    },
    {
      'cliente': 'Ana Torres',
      'servicio': 'Pintura',
      'fecha': '25/05/2025',
      'hora': '13:45',
      'calificacion': 4.8,
      'comentario': 'Trabajo impecable, muy recomendado.',
      'ganancia': 150.0,
      'estado': 'completado',
      'duracion': '3 horas',
      'ubicacion': 'Calle Real 654, Arequipa',
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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
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

  List<Map<String, dynamic>> getFilteredHistory() {
    if (selectedFilter == 'Todos') return mockHistory;
    if (selectedFilter == 'Completados') {
      return mockHistory.where((job) => job['estado'] == 'completado').toList();
    }
    if (selectedFilter == 'Cancelados') {
      return mockHistory.where((job) => job['estado'] == 'cancelado').toList();
    }
    return mockHistory;
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
      case 'instalación de luces led':
        return Icons.lightbulb_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  Color _getStatusColor(String estado, ColorScheme colorScheme) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return colorScheme.primary;
      case 'cancelado':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredHistory = getFilteredHistory();
    final totalGanancias = mockHistory
        .where((job) => job['estado'] == 'completado')
        .fold<double>(0.0, (sum, job) => sum + job['ganancia']);
    final totalTrabajos =
        mockHistory.where((job) => job['estado'] == 'completado').length;
    final promedioCalificacion =
        mockHistory
            .where(
              (job) => job['estado'] == 'completado' && job['calificacion'] > 0,
            )
            .fold<double>(0.0, (sum, job) => sum + job['calificacion']) /
        mockHistory
            .where(
              (job) => job['estado'] == 'completado' && job['calificacion'] > 0,
            )
            .length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header personalizado
                _buildHeader(context),

                // Estadísticas del trabajador
                _buildWorkerStats(
                  totalGanancias,
                  totalTrabajos,
                  promedioCalificacion,
                ),

                // Filtros
                _buildFilters(),

                // Lista de historial
                Expanded(
                  child:
                      filteredHistory.isEmpty
                          ? _buildEmptyState()
                          : _buildHistoryList(filteredHistory),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => context.go('/workerProfile'),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Volver al perfil',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Historial',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Trabajos realizados',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () {
              // Compartir estadísticas
              _showShareDialog(context);
            },
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartir',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerStats(
    double totalGanancias,
    int totalTrabajos,
    double promedioCalificacion,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Ganancias',
              'S/. ${totalGanancias.toStringAsFixed(0)}',
              Icons.attach_money_rounded,
              colorScheme.primary,
            ),
          ),
          Container(
            height: 60,
            width: 1,
            color: colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Trabajos',
              totalTrabajos.toString(),
              Icons.work_rounded,
              colorScheme.tertiary,
            ),
          ),
          Container(
            height: 60,
            width: 1,
            color: colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Rating',
              promedioCalificacion.toStringAsFixed(1),
              Icons.star_rounded,
              Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 60,
      child: Row(
        children: [
          Text(
            'Filtrar por:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    filterOptions.map((filter) {
                      final isSelected = selectedFilter == filter;
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                          backgroundColor: colorScheme.surface,
                          selectedColor: colorScheme.primaryContainer,
                          checkmarkColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> history) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: history.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildHistoryCard(history[index]),
        );
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> trabajo) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(trabajo['estado'], colorScheme);
    final isCompleted = trabajo['estado'] == 'completado';

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
                // Icono del servicio
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getServiceIcon(trabajo['servicio']),
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trabajo['servicio'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: ${trabajo['cliente']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trabajo['fecha']} - ${trabajo['hora']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    trabajo['estado'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detalles
          if (isCompleted) ...[
            Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Rating y ganancia
                  Row(
                    children: [
                      // Rating
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              trabajo['calificacion'].toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ganancia
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            Text(
                              trabajo['ganancia'].toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Comentario
                  if (trabajo['comentario'].isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comentario del cliente:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${trabajo['comentario']}"',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Información adicional
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          Icons.schedule_rounded,
                          trabajo['duracion'],
                          colorScheme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.location_on_rounded,
                          trabajo['ubicacion'].split(',')[0],
                          colorScheme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Trabajo cancelado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel_rounded,
                    color: colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      trabajo['comentario'],
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildInfoChip(IconData icon, String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay historial',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus trabajos completados aparecerán aquí',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.share_rounded, color: colorScheme.primary, size: 28),
          title: const Text(
            'Compartir Estadísticas',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: const Text(
            '¿Quieres compartir tus estadísticas de trabajo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implementar lógica de compartir
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Estadísticas compartidas'),
                    backgroundColor: colorScheme.primary,
                  ),
                );
              },
              child: const Text('Compartir'),
            ),
          ],
        );
      },
    );
  }
}
