import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/featured_workers_section.dart';
import '../../widgets/promotional_banner.dart';
import '../../widgets/recent_services_section.dart';

class HomeClientScreen extends StatefulWidget {
  const HomeClientScreen({super.key});

  @override
  State<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends State<HomeClientScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final List<String> categories = const [
    'Todos',
    'Electricista',
    'Gasfitero',
    'Carpintero',
    'Técnico en computadoras',
  ];

  final List<Map<String, dynamic>> workers = const [
    {
      'name': 'Luis Rodríguez',
      'specialty': 'Electricista',
      'rating': 4.5,
      'phone': '987654321',
      'available': true,
      'experience': '5 años',
      'completedJobs': 127,
      'priceRange': 'S/. 80 - 150',
      'avatar': 'LR',
      'description':
          'Especialista en instalaciones eléctricas residenciales y comerciales',
    },
    {
      'name': 'Ana Torres',
      'specialty': 'Gasfitero',
      'rating': 4.8,
      'phone': '912345678',
      'available': true,
      'experience': '8 años',
      'completedJobs': 203,
      'priceRange': 'S/. 70 - 120',
      'avatar': 'AT',
      'description': 'Experta en reparaciones de tuberías y sistemas de agua',
    },
    {
      'name': 'Carlos Rivas',
      'specialty': 'Carpintero',
      'rating': 4.2,
      'phone': '956789012',
      'available': false,
      'experience': '12 años',
      'completedJobs': 89,
      'priceRange': 'S/. 100 - 200',
      'avatar': 'CR',
      'description':
          'Maestro carpintero especializado en muebles y estructuras',
    },
    {
      'name': 'Miguel Santos',
      'specialty': 'Técnico en computadoras',
      'rating': 4.6,
      'phone': '923456789',
      'available': true,
      'experience': '6 años',
      'completedJobs': 156,
      'priceRange': 'S/. 60 - 100',
      'avatar': 'MS',
      'description': 'Soporte técnico y reparación de equipos informáticos',
    },
    {
      'name': 'Roberto Mendoza',
      'specialty': 'Electricista',
      'rating': 4.3,
      'phone': '934567890',
      'available': true,
      'experience': '3 años',
      'completedJobs': 78,
      'priceRange': 'S/. 60 - 120',
      'avatar': 'RM',
      'description': 'Electricista especializado en instalaciones domésticas',
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

    // Listener para la búsqueda
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredWorkers {
    var filtered = workers;

    // Filtrar por categoría
    if (selectedCategory != 'Todos') {
      filtered =
          filtered
              .where((worker) => worker['specialty'] == selectedCategory)
              .toList();
    }

    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      filtered =
          filtered.where((worker) {
            return worker['name'].toLowerCase().contains(searchQuery) ||
                worker['specialty'].toLowerCase().contains(searchQuery) ||
                worker['description'].toLowerCase().contains(searchQuery);
          }).toList();
    }

    return filtered;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Electricista':
        return Colors.yellow[600]!;
      case 'Gasfitero':
        return Colors.blue[600]!;
      case 'Carpintero':
        return Colors.brown[600]!;
      case 'Técnico en computadoras':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electricista':
        return Icons.electrical_services;
      case 'Gasfitero':
        return Icons.plumbing;
      case 'Carpintero':
        return Icons.handyman;
      case 'Técnico en computadoras':
        return Icons.computer;
      default:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header personalizado
              _buildHeader(context),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Banner promocional
                      const PromotionalBanner(),

                      const SizedBox(height: 24),

                      // Sección de técnicos destacados
                      FeaturedWorkersSection(workers: workers),

                      const SizedBox(height: 24),

                      // Sección de categorías
                      _buildCategoriesSection(),

                      const SizedBox(height: 24),

                      // Lista de técnicos
                      _buildWorkersSection(),

                      const SizedBox(height: 24),

                      // Sección de servicios recientes
                      const RecentServicesSection(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Botones de acción flotantes
              _buildFloatingActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final availableWorkers =
        workers.where((w) => w['available'] == true).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                    Text(
                      'Manos Expertas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$availableWorkers técnicos disponibles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de configuración
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: IconButton(
                  onPressed: () => context.go('/settings'),
                  icon: Icon(
                    Icons.settings,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Configuración',
                ),
              ),
              const SizedBox(width: 8),
              // Botón de cerrar sesión
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _showLogoutDialog(context),
                  icon: Icon(
                    Icons.logout,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: 'Cerrar sesión',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de búsqueda
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar técnicos o servicios...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  size: 20,
                ),
                suffixIcon:
                    searchQuery.isNotEmpty
                        ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                          },
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                            size: 18,
                          ),
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categorías de servicio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                final color = _getCategoryColor(category);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? color.withOpacity(0.1)
                              : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? color
                                : Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getCategoryIcon(category),
                            color: isSelected ? Colors.white : color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category == 'Técnico en computadoras'
                              ? 'Técnico PC'
                              : category,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected
                                    ? color
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersSection() {
    final workers = filteredWorkers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Técnicos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (selectedCategory != 'Todos' || searchQuery.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${workers.length} encontrados',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Mostrar mensaje si no hay resultados
          if (workers.isEmpty)
            _buildNoResultsMessage()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeOutBack,
                  child: _buildWorkerCard(workers[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNoResultsMessage() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron técnicos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o la búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final isAvailable = worker['available'] as bool;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(worker['specialty']),
                        _getCategoryColor(worker['specialty']).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      worker['avatar'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                              worker['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          _buildAvailabilityBadge(isAvailable),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        worker['specialty'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[400], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${worker['rating']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.work_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${worker['completedJobs']} trabajos',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botón de menú
                PopupMenuButton<String>(
                  onSelected:
                      (value) => _handleWorkerAction(value, worker, context),
                  icon: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder:
                      (ctx) => [
                        const PopupMenuItem(
                          value: 'ver',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Ver perfil'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'llamar',
                          child: Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Llamar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'chat',
                          child: Row(
                            children: [
                              Icon(Icons.chat_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Chatear'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'contratar',
                          child: Row(
                            children: [
                              Icon(Icons.handshake_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Contratar'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Descripción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                worker['description'],
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Detalles adicionales
            Row(
              children: [
                Expanded(
                  child: _buildDetailChip(
                    Icons.schedule,
                    worker['experience'],
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailChip(
                    Icons.attach_money,
                    worker['priceRange'],
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityBadge(bool isAvailable) {
    final color = isAvailable ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Disponible' : 'Ocupado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showServiceRequestDialog(context);
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text(
                'Solicitar servicio',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: IconButton(
              onPressed: () => context.go('/chats'),
              icon: Icon(
                Icons.chat_bubble_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              tooltip: 'Ir al chat',
            ),
          ),
        ],
      ),
    );
  }

  void _handleWorkerAction(
    String action,
    Map<String, dynamic> worker,
    BuildContext context,
  ) {
    switch (action) {
      case 'ver':
        _showWorkerProfileDialog(worker, context);
        break;
      case 'llamar':
        _showSnackBar(
          context,
          'Simulando llamada a ${worker['phone']}',
          Icons.phone,
        );
        break;
      case 'chat':
        _showSnackBar(context, 'Chat simulado en desarrollo', Icons.chat);
        break;
      case 'contratar':
        _showContractDialog(worker, context);
        break;
    }
  }

  void _showWorkerProfileDialog(
    Map<String, dynamic> worker,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(worker['specialty']),
                        _getCategoryColor(worker['specialty']).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      worker['avatar'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    worker['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileDetailRow('Especialidad', worker['specialty']),
                _buildProfileDetailRow('Calificación', '${worker['rating']} ⭐'),
                _buildProfileDetailRow('Experiencia', worker['experience']),
                _buildProfileDetailRow(
                  'Trabajos completados',
                  '${worker['completedJobs']}',
                ),
                _buildProfileDetailRow(
                  'Rango de precios',
                  worker['priceRange'],
                ),
                _buildProfileDetailRow(
                  'Estado',
                  worker['available'] ? 'Disponible' : 'Ocupado',
                ),
                const SizedBox(height: 8),
                Text(
                  worker['description'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Solicitar Servicio',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              '¿Deseas enviar una solicitud de servicio general?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSnackBar(
                    context,
                    'Solicitud enviada exitosamente',
                    Icons.check_circle_outline,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Enviar'),
              ),
            ],
          ),
    );
  }

  void _showContractDialog(
    Map<String, dynamic> worker,
    BuildContext context,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      _showSnackBar(
        context,
        'Error: No se pudo obtener información del usuario',
        Icons.error,
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Contratar Técnico',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              '¿Deseas contratar a ${worker['name']} para un trabajo?\n\nEsto creará un chat donde podrás comunicarte directamente con el técnico.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  try {
                    // Crear la conversación de chat
                    final conversationId = await chatProvider.createConversation(
                      clientId: currentUser.uid,
                      workerId:
                          worker['phone'], // Usamos el teléfono como ID del trabajador
                      clientName: currentUser.name ?? currentUser.email,
                      workerName: worker['name'],
                    );

                    // Enviar mensaje inicial automático
                    await chatProvider.sendMessage(
                      conversationId: conversationId,
                      senderId: currentUser.uid,
                      receiverId: worker['phone'],
                      message:
                          'Hola ${worker['name']}, he contratado tus servicios. ¿Cuándo podrías empezar el trabajo?',
                    );

                    _showSnackBar(
                      context,
                      '¡Has contratado a ${worker['name']}! Se ha creado un chat para comunicarte.',
                      Icons.handshake,
                    );

                    // Opcional: Navegar al chat después de contratar
                    if (context.mounted) {
                      context.go('/chats');
                    }
                  } catch (e) {
                    print('Error al crear chat: $e');
                    _showSnackBar(
                      context,
                      'Error al crear el chat. Inténtalo de nuevo.',
                      Icons.error,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              '¿Estás seguro de que deseas cerrar sesión?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Cierra el diálogo

                  try {
                    // Hace logout del AuthProvider
                    await context.read<AuthProvider>().logout();

                    // Navega a la pantalla de login
                    if (context.mounted) {
                      context.go('/');
                    }
                  } catch (e) {
                    // En caso de error, navega de todas formas
                    if (context.mounted) {
                      context.go('/');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
