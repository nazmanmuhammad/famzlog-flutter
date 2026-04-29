import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TripTrackPage extends StatefulWidget {
  final int recordId;
  final String? routeCode;

  const TripTrackPage({super.key, required this.recordId, this.routeCode});

  @override
  State<TripTrackPage> createState() => _TripTrackPageState();
}

class _TripTrackPageState extends State<TripTrackPage> {
  static const int _maxRoutePointsForMap = 800;

  bool _isLoading = true;
  String? _errorMessage;
  DriverDcDetail? _detail;
  final MapController _mapController = MapController();
  String? _currentUserStoreName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.fetchMe();
      if (mounted) {
        setState(() {
          _currentUserStoreName = user.storeName;
        });
      }

      final detail = await DriverDcService.getDropOffDetail(widget.recordId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });

        // Fit bounds after build to ensure map is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBounds();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _fitBounds() {
    if (_detail == null) return;

    final points = <LatLng>[];

    // Add vehicle history points
    points.addAll(_buildOptimizedRoutePoints());

    // Add store locations
    for (var store in _detail!.stores) {
      if (_isValidCoordinate(store.latitude, store.longitude)) {
        points.add(LatLng(store.latitude!, store.longitude!));
      }
    }

    if (points.isEmpty) return;

    try {
      final uniquePoints = points
          .map(
            (p) =>
                '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}',
          )
          .toSet();
      if (uniquePoints.length < 2) {
        _mapController.move(points.first, 15);
        return;
      }

      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;
      for (final point in points.skip(1)) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      if ((maxLat - minLat).abs() < 0.00001 &&
          (maxLng - minLng).abs() < 0.00001) {
        _mapController.move(points.first, 15);
        return;
      }

      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    } catch (e) {
      debugPrint('Error fitting bounds: $e');
    }
  }

  bool _isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (!latitude.isFinite || !longitude.isFinite) return false;
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  List<LatLng> _buildOptimizedRoutePoints() {
    if (_detail == null || _detail!.locations.isEmpty) return [];

    final validPoints = _detail!.locations
        .where((loc) => _isValidCoordinate(loc.latitude, loc.longitude))
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();

    if (validPoints.length <= _maxRoutePointsForMap) {
      return validPoints;
    }

    final step = (validPoints.length / _maxRoutePointsForMap).ceil();
    final sampled = <LatLng>[];
    for (int i = 0; i < validPoints.length; i += step) {
      sampled.add(validPoints[i]);
    }
    if (sampled.isEmpty || sampled.last != validPoints.last) {
      sampled.add(validPoints.last);
    }
    return sampled;
  }

  bool _isOverloadOrFailed(Store store) {
    final plannedStatus = (store.plannedStatus ?? '').toLowerCase();
    final qtyStatus = (store.qtyStatus ?? '').toLowerCase();
    return store.overloadTime != null ||
        plannedStatus.contains('overload') ||
        plannedStatus.contains('gagal bongkar') ||
        qtyStatus.contains('overload');
  }

  void _showStoreInfo(Store store) {
    final currentRitase = _detail?.record.ritase ?? 1;
    final nextRitase = currentRitase + 1;
    final isOverloadOrFailed = _isOverloadOrFailed(store);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    store.storeName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isOverloadOrFailed) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Overload/Gagal Bongkar, akan dikirim dengan ritase $nextRitase',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              "Status: ${isOverloadOrFailed ? 'RITASE $nextRitase' : store.status.toUpperCase()}",
            ),
            if (store.unloadingStartTime != null)
              Text('Unloading Start: ${store.unloadingStartTime}'),
            if (store.unloadingFinishTime != null)
              Text('Unloading Finish: ${store.unloadingFinishTime}'),
          ],
        ),
      ),
    );
  }

  void _showVehicleInfo() {
    if (_detail == null) return;
    final record = _detail!.record;

    // Find next unvisited store with ETA
    final nextStore = _detail!.stores
        .where((s) => s.status != 'finished' && s.overloadTime == null)
        .firstOrNull;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.licensePlate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Driver', record.driverName ?? '-'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Last Update',
              _detail!.locations.isNotEmpty
                  ? DateFormatter.format(_detail!.locations.last.capturedAt)
                  : '-',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.speed,
              'Speed',
              _detail!.locations.isNotEmpty &&
                      _detail!.locations.last.speed != null
                  ? '${(_detail!.locations.last.speed! * 3.6).toStringAsFixed(1)} km/h'
                  : '-',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.map, 'Route', record.routeCode),
            if (nextStore != null && nextStore.hasEta) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.schedule,
                'ETA',
                nextStore.estimatedArrivalTime ?? '-',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate points for polyline
    final routePoints = _buildOptimizedRoutePoints();

    // Calculate initial center
    LatLng initialCenter = const LatLng(
      -6.200000,
      106.816666,
    ); // Default Jakarta
    if (routePoints.isNotEmpty) {
      initialCenter = routePoints.last;
    } else if (_detail?.stores.isNotEmpty == true) {
      final firstValidStore = _detail!.stores
          .where((s) => _isValidCoordinate(s.latitude, s.longitude))
          .firstOrNull;

      if (firstValidStore != null) {
        initialCenter = LatLng(
          firstValidStore.latitude!,
          firstValidStore.longitude!,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Trip ${widget.routeCode ?? ""}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $_errorMessage', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.famzlog.flutter',
                ),

                // Vehicle Path Polyline
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: Colors.blue,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    // Store Markers
                    ...(_detail?.stores ?? [])
                        .where(
                          (s) => _isValidCoordinate(s.latitude, s.longitude),
                        )
                        .map((store) {
                          final isMyStore =
                              _currentUserStoreName != null &&
                              store.storeName == _currentUserStoreName;

                          Color markerColor =
                              Colors.grey; // Default pending/not_visited
                          if (store.status == 'finished') {
                            markerColor = Colors.green;
                          } else if (store.status == 'process' ||
                              store.status == 'unloading') {
                            markerColor = Colors.amber;
                          } else if (store.status == 'pending' ||
                              store.status == 'not_visited') {
                            markerColor = Colors.grey;
                          }

                          if (_isOverloadOrFailed(store)) {
                            markerColor = Colors.red;
                          }

                          return Marker(
                            point: LatLng(store.latitude!, store.longitude!),
                            width: isMyStore ? 50 : 40,
                            height: isMyStore ? 50 : 40,
                            child: GestureDetector(
                              onTap: () => _showStoreInfo(store),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: markerColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isMyStore
                                      ? const Icon(
                                          Icons.store,
                                          color: Colors.white,
                                          size: 28,
                                        )
                                      : Text(
                                          '${store.sequence}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          );
                        }),

                    // Start Point (Vehicle)
                    if (routePoints.isNotEmpty)
                      Marker(
                        point: routePoints.first,
                        width: 30,
                        height: 30,
                        child: GestureDetector(
                          onTap: _showVehicleInfo,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Current/End Point (Vehicle)
                    if (routePoints.isNotEmpty)
                      Marker(
                        point: routePoints.last,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: _showVehicleInfo,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
