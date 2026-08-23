import 'dart:async';

import 'package:flutter/material.dart';

import 'package:famzlog_flutter/pages/drop_off_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/services/driver_location_service.dart';
import 'package:famzlog_flutter/services/location_tracking_service.dart';
import 'package:famzlog_flutter/services/warehouse_service.dart';
import 'package:famzlog_flutter/pages/driver_dc_shipment_page.dart';
import 'package:famzlog_flutter/models/driver_dc_record.dart';
import 'package:famzlog_flutter/widgets/skeletons.dart';
import 'package:famzlog_flutter/utils/date_formatter.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';
import 'package:famzlog_flutter/widgets/start_ride_form.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RIDE PAGE — Entry point when tapping "Driver DC" from home
// ─────────────────────────────────────────────────────────────────────────────

class DriverDcRidePage extends StatefulWidget {
  const DriverDcRidePage({super.key});

  @override
  State<DriverDcRidePage> createState() => _DriverDcRidePageState();
}

class _DriverDcRidePageState extends State<DriverDcRidePage> {
  static const _primary = Color(0xFF1580C1);

  @override
  void initState() {
    super.initState();
    // STOP legacy tracking service to prevent conflict (especially if it was running every 5 min)
    try {
      LocationTrackingService.instance.stopTracking();
      debugPrint('DriverDcRidePage: Legacy LocationTrackingService stopped.');
    } catch (_) {}

    _checkActiveRide();
    _fetchLatestLocation();
  }

  Future<void> _fetchLatestLocation() async {
    final loc = await DriverLocationService.fetchLatest(
      driverId: AuthService.currentUser?.id,
    );
    if (loc != null && mounted) {
      final lat = double.tryParse(loc['latitude'].toString()) ?? 0.0;
      final lng = double.tryParse(loc['longitude'].toString()) ?? 0.0;
      if (lat != 0 && lng != 0) {
        setState(() {
          _currentCenter = LatLng(lat, lng);
          _driverLocation = _currentCenter;
          _mapController.move(_currentCenter, _currentZoom);
        });
      }
    }
  }

  LatLng _currentCenter = const LatLng(
    -6.200000,
    106.816666,
  ); // Default Jakarta
  LatLng? _driverLocation;
  double _currentZoom = 15.0;
  final MapController _mapController = MapController();
  String? _licensePlate;

  Future<void> _checkActiveRide() async {
    try {
      final activeRecord = await DriverDcService.getActiveRecord();
      if (activeRecord != null && mounted) {
        setState(() {
          _licensePlate = activeRecord.licensePlate;
        });
        _startLocationTracking(activeRecord.id);
      }
    } catch (_) {}
  }

  Widget _buildMarkerWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _licensePlate ?? 'Vehicle',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_shipping,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          // Map placeholder background
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: _currentZoom,
                onPositionChanged: (pos, hasGesture) {
                  if (pos.zoom != null) {
                    setState(() {
                      _currentZoom = pos.zoom!;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.famzlog.flutter',
                ),
                MarkerLayer(
                  markers: _driverLocation == null
                      ? []
                      : [
                          Marker(
                            point: _driverLocation!,
                            width: 80 * (_currentZoom / 15.0),
                            height: 60 * (_currentZoom / 15.0),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: _buildMarkerWidget(),
                            ),
                          ),
                        ],
                ),
              ],
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _circleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _circleButton(
                      icon: Icons.list_alt_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DriverDcPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Siap Mengantar Barang',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lacak lokasi dan status pengiriman\nbarang Anda secara real-time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start Ride button
                  if (AuthService.currentUser?.role != 'shipment')
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _showStartRideDialog(context),
                        child: const Text(
                          'Mulai Pengiriman',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Info row: See you in 2 min + car info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Car illustration placeholder
                        Container(
                          width: 56,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.grey.shade600,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informasi Pengiriman',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lihat daftar drop off',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DriverDcPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.list_rounded,
                                  size: 16,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'List',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF1A1A2E)),
      ),
    );
  }

  void _showStartRideDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return const StartRideForm();
      },
    ).then((result) {
      if (result is DriverDcRecord) {
        setState(() {
          _licensePlate = result.licensePlate;
        });
        _startLocationTracking(result.id);

        // Navigate to Shipment Page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DriverDcShipmentPage(recordId: result.id),
          ),
        );
      }
    });
  }

  // ignore: unused_field
  StreamSubscription<Position>? _positionStreamSubscription;

  void _startLocationTracking(int tripId) {
    // NEW: Use local Geolocator stream for UI updates ONLY.
    // BackgroundLocationService handles the API posting every 5 seconds.

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            final point = LatLng(position.latitude, position.longitude);
            _mapController.move(point, _currentZoom);
            setState(() {
              _driverLocation = point;
            });
          }
        });

    showModernSnackBar(
      context,
      title: 'Tracking Started',
      message: 'Background service is sending location every 5s.',
      success: true,
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// START RIDE FORM — Modal bottom sheet for inputting nopol + route
// ─────────────────────────────────────────────────────────────────────────────

class _StartRideForm extends StatefulWidget {
  const _StartRideForm();

  @override
  State<_StartRideForm> createState() => _StartRideFormState();
}

class _StartRideFormState extends State<_StartRideForm> {
  static const _primary = Color(0xFF1580C1);

  final _formKey = GlobalKey<FormState>();
  final _nopolController = TextEditingController();
  final _routeController = TextEditingController();

  List<VehicleOption> _vehicles = [];
  List<RouteOption> _routes = [];
  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _nopolController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DriverDcService.fetchVehicles(),
        DriverDcService.fetchRoutes(),
      ]);
      if (!mounted) return;
      setState(() {
        _vehicles = results[0] as List<VehicleOption>;
        _routes = results[1] as List<RouteOption>;
      });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final record = await DriverDcService.createRecord(
        licensePlate: _nopolController.text.trim(),
        routeCode: _routeController.text.trim(),
      );
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Berhasil',
        message: 'Driver DC berhasil ditambahkan',
        success: true,
      );
      // Return the trip id so the ride page can start location tracking
      Navigator.of(context).pop(record);
    } on ApiException catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.toString(),
        success: false,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _pickVehicle() async {
    final selected = await showModalBottomSheet<VehicleOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VehiclePickerSheet(vehicles: _vehicles),
    );
    if (selected != null) {
      _nopolController.text = selected.licensePlate;
    }
  }

  void _pickRoute() async {
    final selected = await showModalBottomSheet<RouteOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RoutePickerSheet(routes: _routes),
    );
    if (selected != null) {
      _routeController.text = selected.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Start New Ride',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Input vehicle plate number and route',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else ...[
              // Nopol field
              TextFormField(
                controller: _nopolController,
                readOnly: _vehicles.isNotEmpty,
                onTap: _vehicles.isNotEmpty ? _pickVehicle : null,
                decoration: InputDecoration(
                  labelText: 'Nopol',
                  hintText: _vehicles.isNotEmpty
                      ? 'Tap to select'
                      : 'Enter nopol',
                  prefixIcon: Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  suffixIcon: _vehicles.isNotEmpty
                      ? const Icon(Icons.arrow_drop_down)
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _primary.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nopol wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Route field
              TextFormField(
                controller: _routeController,
                readOnly: _routes.isNotEmpty,
                onTap: _routes.isNotEmpty ? _pickRoute : null,
                decoration: InputDecoration(
                  labelText: 'Route',
                  hintText: _routes.isNotEmpty
                      ? 'Tap to select'
                      : 'Enter route',
                  prefixIcon: Icon(
                    Icons.route_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  suffixIcon: _routes.isNotEmpty
                      ? const Icon(Icons.arrow_drop_down)
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _primary.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Route wajib diisi' : null,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Confirm Ride',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehiclePickerSheet extends StatefulWidget {
  const _VehiclePickerSheet({required this.vehicles});

  final List<VehicleOption> vehicles;

  @override
  State<_VehiclePickerSheet> createState() => _VehiclePickerSheetState();
}

class _VehiclePickerSheetState extends State<_VehiclePickerSheet> {
  static const _primary = Color(0xFF1580C1);

  final TextEditingController _searchController = TextEditingController();
  List<VehicleOption> _filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    _filteredVehicles = List.of(widget.vehicles);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = List.of(widget.vehicles);
      } else {
        _filteredVehicles = widget.vehicles
            .where(
              (vehicle) => vehicle.licensePlate.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Nopol',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nopol...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filteredVehicles.isEmpty
                    ? Center(
                        child: Text(
                          'Nopol tidak ditemukan',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredVehicles.length,
                        itemBuilder: (context, i) {
                          final v = _filteredVehicles[i];
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_shipping_outlined,
                                color: _primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              v.licensePlate,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => Navigator.of(context).pop(v),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePickerSheet extends StatefulWidget {
  const _RoutePickerSheet({required this.routes});

  final List<RouteOption> routes;

  @override
  State<_RoutePickerSheet> createState() => _RoutePickerSheetState();
}

class _RoutePickerSheetState extends State<_RoutePickerSheet> {
  static const _primary = Color(0xFF1580C1);

  final TextEditingController _searchController = TextEditingController();
  List<RouteOption> _filteredRoutes = [];

  @override
  void initState() {
    super.initState();
    _filteredRoutes = List.of(widget.routes);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredRoutes = List.of(widget.routes);
      } else {
        _filteredRoutes = widget.routes
            .where(
              (route) =>
                  route.code.toLowerCase().contains(query) ||
                  route.name.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Route',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari route...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filteredRoutes.isEmpty
                    ? Center(
                        child: Text(
                          'Route tidak ditemukan',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredRoutes.length,
                        itemBuilder: (context, i) {
                          final r = _filteredRoutes[i];
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.route_outlined,
                                color: _primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              r.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              r.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            onTap: () => Navigator.of(context).pop(r),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAP GRID PAINTER — Simple grid lines to simulate a map background
// ─────────────────────────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.12)
      ..strokeWidth = 0.8;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Some diagonal "roads"
    final roadPaint = Paint()
      ..color = Colors.grey.withOpacity(0.08)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.8, size.height * 0.7),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// DRIVER DC LIST PAGE — existing list with search, edit, delete
// ─────────────────────────────────────────────────────────────────────────────

class DriverDcPage extends StatefulWidget {
  const DriverDcPage({super.key});

  @override
  State<DriverDcPage> createState() => _DriverDcPageState();
}

class _DriverDcPageState extends State<DriverDcPage> {
  static const _primary = Color(0xFF1580C1);

  final TextEditingController _searchController = TextEditingController();
  List<DriverDcRecord> _records = [];
  List<DriverDcRecord> _filtered = [];
  bool _loading = false;
  DateTime _selectedDate = DateTime.now();
  String? _selectedStatus;

  // Warehouse geofence
  Position? _currentPosition;
  double? _warehouseLatitude;
  double? _warehouseLongitude;
  static const double _warehouseRadius = 500.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilter);
    _loadWarehouseCoords();
    _startLocationUpdates();
  }

  Future<void> _loadWarehouseCoords() async {
    final lat = await WarehouseService.getSelectedWarehouseLatitude();
    final lng = await WarehouseService.getSelectedWarehouseLongitude();
    if (mounted) {
      setState(() {
        _warehouseLatitude = lat;
        _warehouseLongitude = lng;
      });
    }
  }

  Future<void> _startLocationUpdates() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
  }

  bool get _isInsideWarehouseRadius {
    if (_currentPosition == null || _warehouseLatitude == null || _warehouseLongitude == null) {
      return false;
    }
    const distance = Distance();
    final meters = distance.as(
      LengthUnit.Meter,
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      LatLng(_warehouseLatitude!, _warehouseLongitude!),
    );
    return meters <= _warehouseRadius;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    try {
      final list = await DriverDcService.fetchRecords(
        date: _selectedDate,
        status: _selectedStatus,
      );
      setState(() {
        _records = list;
        _filtered = list;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.toString(),
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() {
        _filtered = _records;
      });
      return;
    }
    setState(() {
      _filtered = _records
          .where(
            (e) =>
                e.licensePlate.toLowerCase().contains(q) ||
                e.routeCode.toLowerCase().contains(q) ||
                (e.transporterName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    });
  }

  Future<void> _openForm({DriverDcRecord? record}) async {
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DriverDcFormPage(record: record)),
    );
    if (refreshed == true) {
      _loadData();
    }
  }

  Future<void> _confirmDelete(DriverDcRecord record) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Hapus Driver DC'),
          content: Text(
            'Hapus data ${record.licensePlate} - ${record.routeCode}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (result != true) return;
    try {
      await DriverDcService.deleteRecord(record.id);
      showModernSnackBar(
        context,
        title: 'Berhasil',
        message: 'Data Driver DC dihapus',
        success: true,
      );
      _loadData();
    } on ApiException catch (e) {
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } catch (e) {
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.toString(),
        success: false,
      );
    }
  }

  Future<void> _scanOutWarehouse(DriverDcRecord record) async {
    // Geofence check
    if (_warehouseLatitude != null && _warehouseLongitude != null && !_isInsideWarehouseRadius) {
      showModernSnackBar(
        context,
        title: 'Lokasi Tidak Valid',
        message: 'Anda harus berada dalam radius 500m dari DC untuk Scan Out Warehouse',
        success: false,
      );
      return;
    }

    try {
      await DriverDcService.scanOutWarehouse(record.id);
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Berhasil',
        message: 'Scan Out Warehouse Berhasil',
        success: true,
      );
      _loadData();
    } on ApiException catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.toString(),
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Driver DC List',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton:
          ((AuthService.currentUser?.role ?? '').toLowerCase() == 'driver')
          ? FloatingActionButton(
              onPressed: () => _openForm(),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                        _loadData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        hint: Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _selectedStatus = val;
                          });
                          _loadData();
                        },
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'process',
                            child: Text('Proses'),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Belum Diproses'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by nopol, route, or transporter...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primary, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // Count badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_filtered.length} records',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: _loadData,
              child: _loading
                  ? const DriverDcListSkeleton()
                  : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No records found',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _filtered[index];
                        final isCompleted = item.scanOutTime != null;
                        final currentUserId = AuthService.currentUser?.id;

                        return _DriverDcListTile(
                          item: item,
                          currentUserId: currentUserId,
                          onTap: () => _openForm(record: item),
                          onDelete: () => _confirmDelete(item),
                          onEdit: () => _openForm(record: item),
                          onScanOutWarehouse: () => _scanOutWarehouse(item),
                          isInsideWarehouse: _isInsideWarehouseRadius,
                          hasWarehouseCoords: _warehouseLatitude != null && _warehouseLongitude != null,
                          onShipment: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DriverDcShipmentPage(recordId: item.id),
                              ),
                            );
                          },
                          onDropOff: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DropOffPage(recordId: item.id),
                              ),
                            );
                          },
                          isCompleted: isCompleted,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverDcListTile extends StatelessWidget {
  final DriverDcRecord item;
  final int? currentUserId;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onDropOff;
  final VoidCallback onShipment;
  final VoidCallback onScanOutWarehouse;
  final bool isCompleted;
  final bool isInsideWarehouse;
  final bool hasWarehouseCoords;

  const _DriverDcListTile({
    required this.item,
    this.currentUserId,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onDropOff,
    required this.onShipment,
    required this.onScanOutWarehouse,
    required this.isCompleted,
    this.isInsideWarehouse = false,
    this.hasWarehouseCoords = false,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1580C1);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.licensePlate,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.routeCode}${item.ritase != null ? ' • Rit ${item.ritase}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (item.transporterName != null)
                        Text(
                          item.transporterName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (item.warehouseScanOutTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                size: 12,
                                color: Color(0xFF00897B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Out: ${item.warehouseScanOutTime}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF00897B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item.scanInTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.login_rounded,
                                size: 12,
                                color: Color(0xFF00A86B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'In: ${DateFormatter.format(item.scanInTime)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF00A86B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.driverId == currentUserId &&
                    (AuthService.currentUser?.role ?? '').toLowerCase() !=
                        'shipment' &&
                    !item.dropOff &&
                    !isCompleted &&
                    !item.routeCode.startsWith('CUSTOM-')) // Hide edit for custom routes
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.blue,
                      size: 22,
                    ),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                if (item.driverId == currentUserId)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade300,
                      size: 22,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                  ),
              ],
            ),
            if (!isCompleted) ...[
              if (item.warehouseScanOutTime == null &&
                  (AuthService.currentUser?.role ?? '').toLowerCase() ==
                      'driver') ...[
                const SizedBox(height: 12),
                if (hasWarehouseCoords && !isInsideWarehouse)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.location_off, size: 13, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Harus dalam radius 500m dari DC',
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: (isInsideWarehouse || !hasWarehouseCoords)
                        ? onScanOutWarehouse
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isInsideWarehouse || !hasWarehouseCoords)
                          ? const Color(0xFF00897B)
                          : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      (isInsideWarehouse || !hasWarehouseCoords)
                          ? Icons.qr_code_scanner_rounded
                          : Icons.lock_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Scan Out Warehouse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onShipment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Shipment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (item.driverId == currentUserId &&
                  (AuthService.currentUser?.role ?? '').toLowerCase() !=
                      'shipment') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onDropOff,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.pin_drop_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Drop Off',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRIVER DC FORM PAGE — create / edit
// ─────────────────────────────────────────────────────────────────────────────

class DriverDcFormPage extends StatefulWidget {
  final DriverDcRecord? record;

  const DriverDcFormPage({super.key, this.record});

  @override
  State<DriverDcFormPage> createState() => _DriverDcFormPageState();
}

class _DriverDcFormPageState extends State<DriverDcFormPage> {
  static const _primary = Color(0xFF1580C1);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nopolController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();

  List<VehicleOption> _vehicles = [];
  List<RouteOption> _routes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _nopolController.text = widget.record!.licensePlate;
      _routeController.text = widget.record!.routeCode;
    }
    _loadOptions();
  }

  @override
  void dispose() {
    _nopolController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        DriverDcService.fetchVehicles(),
        DriverDcService.fetchRoutes(),
      ]);
      if (!mounted) return;
      setState(() {
        _vehicles = results[0] as List<VehicleOption>;
        _routes = results[1] as List<RouteOption>;
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _loading = true;
    });
    final nopol = _nopolController.text.trim();
    final route = _routeController.text.trim();
    try {
      if (widget.record == null) {
        await DriverDcService.createRecord(
          licensePlate: nopol,
          routeCode: route,
        );
        showModernSnackBar(
          context,
          title: 'Berhasil',
          message: 'Data Driver DC ditambahkan',
          success: true,
        );
      } else {
        await DriverDcService.updateRecord(
          id: widget.record!.id,
          licensePlate: nopol,
          routeCode: route,
        );
        showModernSnackBar(
          context,
          title: 'Berhasil',
          message: 'Data Driver DC diperbarui',
          success: true,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.toString(),
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickVehicle() async {
    final selected = await showModalBottomSheet<VehicleOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VehiclePickerSheet(vehicles: _vehicles),
    );
    if (selected != null) {
      setState(() {
        _nopolController.text = selected.licensePlate;
      });
    }
  }

  Future<void> _pickRoute() async {
    final selected = await showModalBottomSheet<RouteOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RoutePickerSheet(routes: _routes),
    );
    if (selected != null) {
      setState(() {
        _routeController.text = selected.code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.record != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Driver DC' : 'Tambah Driver DC',
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nopol
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Nopol',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              TextFormField(
                controller: _nopolController,
                readOnly: _vehicles.isNotEmpty,
                onTap: _vehicles.isNotEmpty ? _pickVehicle : null,
                decoration: InputDecoration(
                  hintText: 'Pilih Nopol',
                  prefixIcon: Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  suffixIcon: _vehicles.isEmpty
                      ? null
                      : const Icon(Icons.arrow_drop_down),
                  filled: true,
                  fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _primary.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Route
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Route',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              TextFormField(
                controller: _routeController,
                readOnly: _routes.isNotEmpty,
                onTap: _routes.isNotEmpty ? _pickRoute : null,
                decoration: InputDecoration(
                  hintText: 'Pilih Route',
                  prefixIcon: Icon(
                    Icons.route_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  suffixIcon: _routes.isEmpty
                      ? null
                      : const Icon(Icons.arrow_drop_down),
                  filled: true,
                  fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _primary.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          isEdit ? 'Simpan Perubahan' : 'Simpan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
