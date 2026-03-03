import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:famzlog_flutter/models/driver_dc_record.dart';
import 'package:famzlog_flutter/pages/account_page.dart';
import 'package:famzlog_flutter/utils/date_formatter.dart';
import 'package:famzlog_flutter/widgets/skeletons.dart';
import 'package:shimmer/shimmer.dart';

class StoreDashboardPage extends StatefulWidget {
  const StoreDashboardPage({super.key});

  @override
  State<StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends State<StoreDashboardPage> {
  int _currentIndex = 0;
  bool _isLoading = false;

  // Data
  List<VehicleOption> _vehicles = [];
  List<DriverDcRecord> _trips = [];
  
  // Map
  final MapController _mapController = MapController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Refresh every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    // Only show loading indicator on first load to avoid flickering
    if (_vehicles.isEmpty && _trips.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final vehicles = await DriverDcService.fetchVehicles();
      final trips = await DriverDcService.fetchRecords(limit: 50);

      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _trips = trips;
      });
    } catch (e) {
      // Ignore errors for now or show snackbar
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1580C1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(),
          _buildPerTripTab(),
          const AccountPage(), // Reuse account page
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: primary,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.route_rounded),
              label: 'Per Trip',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    // Filter vehicles with location
    final activeVehicles = _vehicles.where((v) => v.latitude != null && v.longitude != null).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(-6.200000, 106.816666), // Jakarta
            initialZoom: 10,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.famzlog.app',
            ),
            MarkerLayer(
              markers: activeVehicles.map((v) {
                return Marker(
                  point: LatLng(v.latitude!, v.longitude!),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.licensePlate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Last Update: ${DateFormatter.format(v.capturedAt)}'),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${activeVehicles.length} Vehicles Active',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerTripTab() {
    if (_isLoading && _trips.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonListTile(),
      );
    }

    // Calculate summary counts
    int grayCount = 0;
    int blueCount = 0;
    int greenCount = 0;

    for (var trip in _trips) {
      if (trip.scanOutTime != null) {
        greenCount++;
      } else if (trip.loadingStartTime != null) {
        blueCount++;
      } else {
        grayCount++;
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Per Trip Status',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryItem('Queued', grayCount, Colors.grey),
                  const SizedBox(width: 12),
                  _buildSummaryItem('Process', blueCount, Colors.blue),
                  const SizedBox(width: 12),
                  _buildSummaryItem('Finished', greenCount, Colors.green),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trip = _trips[index];
                
                Color statusColor;
                String statusText;

                if (trip.scanOutTime != null) {
                  statusColor = Colors.green;
                  statusText = 'Finished';
                } else if (trip.loadingStartTime != null) {
                  statusColor = Colors.blue;
                  statusText = 'On Process';
                } else {
                  statusColor = Colors.grey;
                  statusText = 'Queued';
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
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
                            trip.licensePlate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            trip.transporterName ?? 'Unknown Driver',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.alt_route, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Route: ${trip.routeCode}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Created: ${DateFormatter.format(trip.scanInTime)}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                          if (trip.scanOutTime != null)
                            Text(
                              'Finished: ${DateFormatter.format(trip.scanOutTime)}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
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
      ),
    );
  }
}

