import 'package:flutter/material.dart';

import 'package:famzlog_flutter/pages/drop_off_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/services/driver_location_service.dart';
import 'package:famzlog_flutter/services/location_tracking_service.dart';

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
    _checkActiveRide();
    _fetchLatestLocation();
  }

  Future<void> _fetchLatestLocation() async {
    final loc = await DriverLocationService.fetchLatest(driverId: AuthService.currentUser?.id);
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

  LatLng _currentCenter = const LatLng(-6.200000, 106.816666); // Default Jakarta
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
        const Icon(
          Icons.local_shipping,
          color: Colors.blue, // Or any color you prefer for the truck
          size: 30,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                Icon(Icons.list_rounded,
                                    size: 16, color: Colors.grey.shade700),
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

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: const _StartRideForm(),
        );
      },
    ).then((result) {
      if (result is DriverDcRecord) {
        setState(() {
          _licensePlate = result.licensePlate;
        });
        _startLocationTracking(result.id);
      }
    });
  }

  void _startLocationTracking(int tripId) {
    final tracker = LocationTrackingService.instance;
    // Configure: interval-based, every 5 minutes (300 seconds)
    tracker.mode = TrackingMode.interval;
    tracker.intervalSeconds = 300;

    tracker.onLocationSent = (lat, lng) {
      if (mounted) {
        final point = LatLng(lat, lng);
        _mapController.move(point, _currentZoom);
        setState(() {
          _driverLocation = point;
        });

        _showModernSnackBar(
          context,
          title: 'Location Sent',
          message: 'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
          success: true,
        );
      }
    };
    tracker.onError = (error) {
      if (mounted) {
        _showModernSnackBar(
          context,
          title: 'Tracking Error',
          message: error,
          success: false,
        );
      }
    };
    tracker.startTracking(tripId: tripId);
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
      _showModernSnackBar(
        context,
        title: 'Berhasil',
        message: 'Driver DC berhasil ditambahkan',
        success: true,
      );
      // Return the trip id so the ride page can start location tracking
      Navigator.of(context).pop(record);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showModernSnackBar(context, title: 'Error', message: e.message, success: false);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showModernSnackBar(context, title: 'Error', message: e.message, success: false);
    } catch (e) {
      if (!mounted) return;
      _showModernSnackBar(context, title: 'Error', message: e.toString(), success: false);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _pickVehicle() async {
    final selected = await showModalBottomSheet<VehicleOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _vehicles.length,
                itemBuilder: (ctx, i) {
                  final v = _vehicles[i];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_shipping_outlined,
                          color: _primary, size: 20),
                    ),
                    title: Text(v.licensePlate,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.of(ctx).pop(v),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
    if (selected != null) {
      _nopolController.text = selected.licensePlate;
    }
  }

  void _pickRoute() async {
    final selected = await showModalBottomSheet<RouteOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _routes.length,
                itemBuilder: (ctx, i) {
                  final r = _routes[i];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.route_outlined,
                          color: _primary, size: 20),
                    ),
                    title: Text(r.code,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(r.name,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    onTap: () => Navigator.of(ctx).pop(r),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
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
                  hintText: _vehicles.isNotEmpty ? 'Tap to select' : 'Enter nopol',
                  prefixIcon: Icon(Icons.local_shipping_outlined,
                      color: Colors.grey.shade500, size: 20),
                  suffixIcon: _vehicles.isNotEmpty
                      ? const Icon(Icons.arrow_drop_down)
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: _primary.withOpacity(0.3), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
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
                  hintText: _routes.isNotEmpty ? 'Tap to select' : 'Enter route',
                  prefixIcon: Icon(Icons.route_outlined,
                      color: Colors.grey.shade500, size: 20),
                  suffixIcon: _routes.isNotEmpty
                      ? const Icon(Icons.arrow_drop_down)
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: _primary.withOpacity(0.3), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilter);
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
      final list = await DriverDcService.fetchRecords();
      setState(() {
        _records = list;
        _filtered = list;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showModernSnackBar(
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
          .where((e) =>
              e.licensePlate.toLowerCase().contains(q) ||
              e.routeCode.toLowerCase().contains(q) ||
              (e.transporterName?.toLowerCase().contains(q) ?? false))
          .toList();
    });
  }

  Future<void> _openForm({DriverDcRecord? record}) async {
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DriverDcFormPage(record: record),
      ),
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
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (result != true) return;
    try {
      await DriverDcService.deleteRecord(record.id);
      _showModernSnackBar(
        context,
        title: 'Berhasil',
        message: 'Data Driver DC dihapus',
        success: true,
      );
      _loadData();
    } on ApiException catch (e) {
      _showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } catch (e) {
      _showModernSnackBar(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by nopol or route...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon:
                    Icon(Icons.search_rounded, color: Colors.grey.shade400),
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
                    vertical: 12, horizontal: 16),
              ),
            ),
          ),

          // Count badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 56, color: Colors.grey.shade300),
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _filtered[index];
                            final isCompleted = item.scanOutTime != null;
                            
                            return _DriverDcListTile(
                              item: item,
                              onTap: () => _openForm(record: item),
                              onDelete: () => _confirmDelete(item),
                              onEdit: () => _openForm(record: item),
                              onDropOff: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DropOffPage(recordId: item.id),
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
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onDropOff;
  final bool isCompleted;

  const _DriverDcListTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onDropOff,
    required this.isCompleted,
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      if (item.scanInTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.login_rounded,
                                  size: 12, color: Color(0xFF00A86B)),
                              const SizedBox(width: 4),
                              Text(
                                'In: ${item.scanInTime}',
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
                IconButton(
                  icon: const Icon(Icons.edit_rounded,
                      color: Colors.blue, size: 22),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.shade300, size: 22),
                  onPressed: onDelete,
                  tooltip: 'Hapus',
                ),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 12),
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
                  icon: const Icon(Icons.pin_drop_rounded,
                      color: Colors.white, size: 18),
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
        _showModernSnackBar(
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
        _showModernSnackBar(
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
      _showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showModernSnackBar(
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
                decoration: InputDecoration(
                  hintText: 'Pilih Nopol',
                  prefixIcon: Icon(Icons.local_shipping_outlined,
                      color: Colors.grey.shade500, size: 20),
                  suffixIcon: _vehicles.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: () async {
                            final selected = await showModalBottomSheet<
                                VehicleOption>(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (context) {
                                return ListView.builder(
                                  itemCount: _vehicles.length,
                                  itemBuilder: (context, index) {
                                    final v = _vehicles[index];
                                    return ListTile(
                                      title: Text(v.licensePlate),
                                      onTap: () =>
                                          Navigator.of(context).pop(v),
                                    );
                                  },
                                );
                              },
                            );
                            if (selected != null) {
                              setState(() {
                                _nopolController.text = selected.licensePlate;
                              });
                            }
                          },
                        ),
                  filled: true,
                  fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: _primary.withOpacity(0.3), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
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
                decoration: InputDecoration(
                  hintText: 'Pilih Route',
                  prefixIcon: Icon(Icons.route_outlined,
                      color: Colors.grey.shade500, size: 20),
                  suffixIcon: _routes.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: () async {
                            final selected =
                                await showModalBottomSheet<RouteOption>(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (context) {
                                return ListView.builder(
                                  itemCount: _routes.length,
                                  itemBuilder: (context, index) {
                                    final r = _routes[index];
                                    return ListTile(
                                      title: Text(r.code),
                                      subtitle: Text(r.name),
                                      onTap: () =>
                                          Navigator.of(context).pop(r),
                                    );
                                  },
                                );
                              },
                            );
                            if (selected != null) {
                              setState(() {
                                _routeController.text = selected.code;
                              });
                            }
                          },
                        ),
                  filled: true,
                  fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: _primary.withOpacity(0.3), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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

// ─────────────────────────────────────────────────────────────────────────────
// SNACKBAR HELPER
// ─────────────────────────────────────────────────────────────────────────────

OverlayEntry? _currentSnackBarOverlay;

void _showModernSnackBar(
  BuildContext context, {
  required String title,
  required String message,
  required bool success,
}) {
  // Remove any existing overlay
  _currentSnackBarOverlay?.remove();
  _currentSnackBarOverlay = null;

  final color = success ? const Color(0xFF00A86B) : const Color(0xFFE53935);
  final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      final topPadding = MediaQuery.of(context).padding.top;
      return Positioned(
        top: topPadding + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _TopSnackBarWidget(
            title: title,
            message: message,
            color: color,
            icon: icon,
            onDismiss: () {
              entry.remove();
              if (_currentSnackBarOverlay == entry) {
                _currentSnackBarOverlay = null;
              }
            },
          ),
        ),
      );
    },
  );

  _currentSnackBarOverlay = entry;
  Overlay.of(context).insert(entry);

  // Auto-dismiss after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    if (_currentSnackBarOverlay == entry) {
      entry.remove();
      _currentSnackBarOverlay = null;
    }
  });
}

class _TopSnackBarWidget extends StatefulWidget {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _TopSnackBarWidget({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              widget.onDismiss();
            }
          },
          onTap: widget.onDismiss,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.close, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
