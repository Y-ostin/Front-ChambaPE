import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class MapHomeClientScreen extends StatefulWidget {
  const MapHomeClientScreen({super.key});

  @override
  State<MapHomeClientScreen> createState() => _MapHomeClientScreenState();
}

class _MapHomeClientScreenState extends State<MapHomeClientScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  // Filtros
  int? _selectedCategoryId;
  RangeValues _priceRange = const RangeValues(50, 500);
  double _radiusKm = 5;

  // Lista de categorías de servicio obtenidas del backend
  List<Map<String, dynamic>> _serviceCategories = [];
  bool _categoryLoading = false;

  // Datos de trabajadores cercanos
  final Set<Marker> _markers = {};

  final _requestFormKey = GlobalKey<FormState>();
  // Fields for new request
  String _reqDescription = '';
  RangeValues _reqBudgetRange = const RangeValues(50, 500);
  int _reqCategoryId = 1;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchServiceCategories();
  }

  Future<void> _determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
    });
    _mapController?.moveCamera(CameraUpdate.newLatLng(_currentLatLng!));
    _loadNearbyWorkers();
  }

  Future<void> _fetchServiceCategories() async {
    setState(() => _categoryLoading = true);
    final cats = await ApiService.getServiceCategories();
    if (mounted) {
      setState(() {
        _serviceCategories = cats;
        _categoryLoading = false;
      });
    }
  }

  Future<void> _loadNearbyWorkers() async {
    if (_currentLatLng == null) return;

    try {
      final endpoint =
          '/workers/nearby?lat=${_currentLatLng!.latitude}&lng=${_currentLatLng!.longitude}&radiusKm=$_radiusKm${_selectedCategoryId != null ? '&categoryId=$_selectedCategoryId' : ''}&maxPrice=${_priceRange.end}';

      final response = await ApiService.get(endpoint);

      if (response['success'] == true) {
        final workers = List<Map<String, dynamic>>.from(response['data']);

        setState(() {
          _markers.clear();
          for (var w in workers) {
            final marker = Marker(
              markerId: MarkerId('worker_${w['id']}'),
              position: LatLng(w['latitude'], w['longitude']),
              infoWindow: InfoWindow(title: w['name'] ?? 'Trabajador'),
            );
            _markers.add(marker);
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando trabajadores cercanos: $e');
    }
  }

  void _openFilters() async {
    if (_serviceCategories.isEmpty) {
      await _fetchServiceCategories();
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (_serviceCategories.isEmpty && !_categoryLoading) {
              Future.microtask(() async {
                setModalState(() => _categoryLoading = true);
                final cats = await ApiService.getServiceCategories();
                if (mounted) {
                  setModalState(() {
                    _serviceCategories = cats;
                    _categoryLoading = false;
                  });
                }
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Especialidad
                  _categoryLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<int?>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Especialidad',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ..._serviceCategories.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c['id'] as int?,
                              child: Text(c['name'] as String),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() => _selectedCategoryId = value);
                        },
                      ),
                  const SizedBox(height: 16),
                  // Rango de precio
                  Text(
                    'Rango de precio (S/): ${_priceRange.start.round()} - ${_priceRange.end.round()}',
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels(
                      _priceRange.start.round().toString(),
                      _priceRange.end.round().toString(),
                    ),
                    onChanged: (values) {
                      setModalState(() => _priceRange = values);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Radio
                  Text('Radio de búsqueda: ${_radiusKm.toStringAsFixed(1)} km'),
                  Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: _radiusKm.toStringAsFixed(1),
                    onChanged: (value) {
                      setModalState(() => _radiusKm = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _loadNearbyWorkers();
                        },
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openCreateRequest() {
    if (_currentLatLng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Obteniendo ubicación...')));
      return;
    }

    if (_serviceCategories.isEmpty) {
      // Cargar categorías antes de mostrar el modal
      _fetchServiceCategories();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Cargar categorías dentro del modal si aún no están disponibles
            if (_serviceCategories.isEmpty && !_categoryLoading) {
              Future.microtask(() async {
                setModalState(() => _categoryLoading = true);
                final cats = await ApiService.getServiceCategories();
                if (mounted) {
                  setModalState(() {
                    _serviceCategories = cats;
                    _categoryLoading = false;
                  });
                }
              });
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _requestFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Nueva Solicitud',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                        minLines: 2,
                        maxLines: 4,
                        validator:
                            (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        onChanged: (v) => _reqDescription = v,
                      ),
                      const SizedBox(height: 12),
                      _categoryLoading
                          ? const CircularProgressIndicator()
                          : _serviceCategories.isEmpty
                          ? const Text('Sin categorías')
                          : DropdownButtonFormField<int>(
                            value:
                                _serviceCategories.any(
                                      (c) => c['id'] == _reqCategoryId,
                                    )
                                    ? _reqCategoryId
                                    : null,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                            ),
                            items:
                                _serviceCategories
                                    .map(
                                      (c) => DropdownMenuItem<int>(
                                        value: c['id'] as int,
                                        child: Text(c['name'] as String),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setModalState(
                                  () => _reqCategoryId = v ?? _reqCategoryId,
                                ),
                          ),
                      const SizedBox(height: 12),
                      // Ubicación actual
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ubicación:\nLat: ${_currentLatLng?.latitude.toStringAsFixed(4) ?? '--'}, Lng: ${_currentLatLng?.longitude.toStringAsFixed(4) ?? '--'}',
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _determinePosition();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.my_location),
                            tooltip: 'Actualizar ubicación',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rango de precio: S/ ${_reqBudgetRange.start.round()} - ${_reqBudgetRange.end.round()}',
                      ),
                      RangeSlider(
                        values: _reqBudgetRange,
                        min: 10,
                        max: 5000,
                        divisions: 100,
                        labels: RangeLabels(
                          _reqBudgetRange.start.round().toString(),
                          _reqBudgetRange.end.round().toString(),
                        ),
                        onChanged: (r) {
                          setModalState(() => _reqBudgetRange = r);
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_requestFormKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          final result = await ApiService.createServiceRequest(
                            title: 'Solicitud de servicio',
                            description: _reqDescription,
                            address: 'Ubicación',
                            latitude: _currentLatLng!.latitude,
                            longitude: _currentLatLng!.longitude,
                            serviceCategoryId: _reqCategoryId,
                            estimatedBudget:
                                (_reqBudgetRange.start + _reqBudgetRange.end) /
                                2,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['success'] == true
                                      ? 'Solicitud publicada correctamente'
                                      : 'Error: ${result['message']}',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Publicar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar servicio')),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Menú',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Buscar'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/client/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Chats'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/chats');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Ajustes'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-12.0464, -77.0428), // Lima default
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (ctrl) => _mapController = ctrl,
          ),
          // Botón de filtros eliminado
          // Botón nueva solicitud centrado
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                heroTag: 'request',
                onPressed: _openCreateRequest,
                icon: const Icon(Icons.add),
                label: const Text('Solicitar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
