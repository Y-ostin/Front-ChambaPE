import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/delete_account_dialog.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    // Cargar datos del trabajador
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final workerProvider = context.read<WorkerProvider>();
      if (authProvider.currentUser != null) {
        workerProvider.loadWorkerData(authProvider.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Datos dinámicos basados en el usuario autenticado
  String get name =>
      context.read<AuthProvider>().currentUser?.name ?? 'Usuario';
  String get email =>
      context.read<AuthProvider>().currentUser?.email ?? 'usuario@example.com';
  String get phone =>
      context.read<AuthProvider>().currentUser?.phone ?? '+51 987 654 321';

  // Datos específicos del trabajador
  String get specialty =>
      context.read<WorkerProvider>().workerData?.specialty ?? 'Electricista';
  String get experience =>
      context.read<WorkerProvider>().workerData?.experience ?? '5 años';
  double get rating => context.read<WorkerProvider>().workerData?.rating ?? 4.7;
  int get jobsDone =>
      context.read<WorkerProvider>().workerData?.jobsDone ?? 127;
  int get reviewsCount =>
      context.read<WorkerProvider>().workerData?.reviewsCount ?? 89;
  bool get isAvailable =>
      context.read<WorkerProvider>().workerData?.isAvailable ?? true;

  List<String> get certifications =>
      context.read<WorkerProvider>().workerData?.certifications ??
      [
        'Certificación en Instalaciones Eléctricas',
        'Seguridad Industrial - TECSUP',
        'Automatización Residencial',
      ];

  // Trabajos recientes dinámicos
  List<Map<String, dynamic>> get recentJobs =>
      context.read<WorkerProvider>().recentJobs;

  // Reseñas dinámicas
  List<Map<String, dynamic>> get reviews =>
      context.read<WorkerProvider>().reviews;

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar perfil',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  controller: TextEditingController(text: name),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Especialidad'),
                  controller: TextEditingController(text: specialty),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  controller: TextEditingController(text: phone),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Card(
      color: color.withOpacity(0.12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
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
              style: TextStyle(fontSize: 13, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  certifications
                      .map(
                        (cert) => Chip(
                          avatar: const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: Colors.green,
                          ),
                          label: Text(
                            cert,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          backgroundColor: colorScheme.surfaceContainer
                              .withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trabajos recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/workerHistory'),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentJobs.map(
              (job) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Icon(
                    Icons.handyman_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                title: Text(
                  job['servicio'].toString(),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Cliente: ${job['cliente'].toString()}\nFecha: ${job['fecha'].toString()}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    Text(
                      job['calificacion'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilledButton.icon(
              onPressed: () => _showEditProfileSheet(context),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Editar'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_rounded),
              label: const Text('Compartir'),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/workerHistory'),
              icon: const Icon(Icons.history_rounded),
              label: const Text('Historial'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _showDeleteAccountDialog(context),
          icon: const Icon(Icons.delete_forever_rounded),
          label: const Text('Eliminar Cuenta'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedReviews() {
    final colorScheme = Theme.of(context).colorScheme;
    // Usar reseñas dinámicas del WorkerProvider
    final featuredReviews = reviews;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reseñas destacadas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...featuredReviews.map(
              (review) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Icon(Icons.person, color: colorScheme.primary),
                ),
                title: Text(
                  review['cliente'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('"${review['comentario']}"'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    Text(
                      review['calificacion'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Consumer<WorkerProvider>(
              builder: (context, workerProvider, child) {
                return CustomScrollView(
                  slivers: [
                    SliverAppBar.large(
                      backgroundColor: colorScheme.surface,
                      surfaceTintColor: colorScheme.surfaceTint,
                      leading: IconButton.filledTonal(
                        onPressed: () => context.go('/homeWorker'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Volver al inicio',
                      ),
                      title: const Text(
                        'Mi Perfil',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      actions: [
                        IconButton.filledTonal(
                          onPressed: () => _showEditProfileSheet(context),
                          icon: const Icon(Icons.edit_rounded),
                          tooltip: 'Editar perfil',
                        ),
                        const SizedBox(width: 16),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primaryContainer.withOpacity(0.3),
                                colorScheme.secondaryContainer.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          _buildStatsSection(),
                          const SizedBox(height: 16),
                          _buildCertificationsSection(),
                          const SizedBox(height: 16),
                          _buildRecentJobsSection(),
                          const SizedBox(height: 16),
                          _buildFeaturedReviews(),
                          const SizedBox(height: 16),
                          _buildActionButtons(),
                          const SizedBox(height: 80),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/workerHistory'),
        icon: const Icon(Icons.history_rounded),
        label: const Text('Ver Historial'),
      ),
    );
  }

  Widget _buildProfileCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar y información básica
            Row(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          specialty,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Disponible',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Switch(
                            value: isAvailable,
                            activeColor: colorScheme.primary,
                            onChanged: (val) async {
                              try {
                                final authProvider =
                                    context.read<AuthProvider>();
                                final workerProvider =
                                    context.read<WorkerProvider>();
                                if (authProvider.currentUser != null) {
                                  await workerProvider.updateAvailability(
                                    authProvider.currentUser!.uid,
                                    val,
                                  );
                                }
                              } catch (e) {
                                // Mostrar error si algo falla
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al actualizar disponibilidad: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Información de contacto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildContactRow(Icons.email_rounded, email),
                  const SizedBox(height: 12),
                  _buildContactRow(Icons.phone_rounded, phone),
                  const SizedBox(height: 12),
                  _buildContactRow(
                    Icons.work_history_rounded,
                    '$experience de experiencia',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
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

  Widget _buildStatsSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.star_rounded,
                    rating.toString(),
                    'Calificación',
                    colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    Icons.check_circle_rounded,
                    jobsDone.toString(),
                    'Trabajos',
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    Icons.rate_review_rounded,
                    reviewsCount.toString(),
                    'Reseñas',
                    colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => DeleteAccountDialog(
            title: 'Eliminar Cuenta',
            message: '¿Estás seguro de que quieres eliminar tu cuenta?',
            itemsToDelete: [
              'Tu perfil de trabajador',
              'Todas tus conversaciones',
              'Tu historial de trabajos',
              'Tus calificaciones y reseñas',
            ],
          ),
    );
  }
}
