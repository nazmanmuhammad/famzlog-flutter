import 'dart:async';

import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:famzlog_flutter/services/driver_location_service.dart';
import 'package:flutter/material.dart';
import 'package:famzlog_flutter/pages/driver_dc_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DropOffPage extends StatefulWidget {
  final int recordId;

  const DropOffPage({super.key, required this.recordId});

  @override
  State<DropOffPage> createState() => _DropOffPageState();
}

class _DropOffPageState extends State<DropOffPage> {
  static const _primary = Color(0xFF1580C1);

  bool _loading = true;
  DriverDcDetail? _detail;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

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

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  double _calculateDistance(
      double startLat, double startLng, double endLat, double endLng) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, LatLng(startLat, startLng),
        LatLng(endLat, endLng));
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final detail = await DriverDcService.getDropOffDetail(widget.recordId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startDropOff(Store store) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await DriverDcService.startDropOff(widget.recordId, store.id);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showSuccess('Berhasil memulai unloading');
      _loadData(); // Refresh data
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _finishDropOff(Store store) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await DriverDcService.finishDropOff(widget.recordId, store.id);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showSuccess('Berhasil menyelesaikan unloading');
      _loadData(); // Refresh data
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _scanOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Scan Out'),
        content: const Text('Apakah Anda yakin ingin menyelesaikan trip ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text(
              'Ya, Selesai',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await DriverDcService.scanOut(widget.recordId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showSuccess('Berhasil scan out (Trip selesai)');
      
      // Navigate back to DriverDcRidePage (Siap Mengantar Barang)
      // Removing previous routes to prevent back navigation to finished trip
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DriverDcRidePage()),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSuccess(String message) {
    _showModernSnackBar(
      context,
      title: 'Berhasil',
      message: message,
      success: true,
    );
  }

  void _showError(String message) {
    _showModernSnackBar(
      context,
      title: 'Gagal',
      message: message,
      success: false,
    );
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
          'Drop Off Detail',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Text('Gagal memuat data'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final record = _detail!.record;
    final stores = _detail!.stores;
    final allFinished = stores.isNotEmpty &&
        stores.every((s) => s.status == 'finished');
    final isScannedOut = record.scanOutTime != null;

    return Column(
      children: [
        // Header Info
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_shipping_outlined,
                        color: _primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            record.licensePlate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isScannedOut) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
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
                        ],
                      ),
                      Text(
                        record.routeCode,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Store List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final store = stores[index];
              return _buildStoreCard(store, isScannedOut);
            },
          ),
        ),

        // Scan Out Button
        if (allFinished && !isScannedOut)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _scanOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Scan Out (Selesai Trip)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _processDropOff(Store store) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await DriverDcService.processDropOff(widget.recordId, store.id);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showSuccess('Berhasil mengubah status ke process');
      _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Widget _buildStoreCard(Store store, bool isScannedOut) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    // Default
    statusText = 'Belum Ke Toko';
    statusColor = Colors.grey;
    statusIcon = Icons.circle_outlined;

    if (store.unloadingStartTime != null && store.unloadingFinishTime == null) {
      statusText = 'Unloading';
      statusColor = Colors.orange; // Amber/Orange equivalent
      statusIcon = Icons.downloading_rounded;
    } else if (store.unloadingFinishTime != null) {
      statusText = 'Finish';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _primary.withOpacity(0.1),
                  radius: 14,
                  child: Text(
                    '${store.sequence}',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.storeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Tujuan: ${store.plannedStatus ?? '-'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon,
                                    size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isScannedOut) ...[
              if (store.status == 'process')
                Builder(builder: (context) {
                  if (store.latitude == null || store.longitude == null) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _startDropOff(store),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    );
                  }

                  if (_currentPosition == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Mencari lokasi GPS...',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    );
                  }

                  final distance = _calculateDistance(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    store.latitude!,
                    store.longitude!,
                  );

                  if (distance > 100) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off_outlined,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Jarak ke toko: ${distance.toStringAsFixed(0)}m\n(Maksimal 100m untuk mulai)',
                              style: TextStyle(
                                  color: Colors.orange.shade800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _startDropOff(store),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  );
                }),
              if (store.status != 'process' && store.status != 'unloading' && store.status != 'finished')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _processDropOff(store),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              if (store.status == 'unloading')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _finishDropOff(store),
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    label: const Text(
                      'Finish',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
            if (store.status == 'finished')
              Row(
                children: [
                  Expanded(
                    child: _buildTimeInfo(
                      'Mulai',
                      store.unloadingStartTime,
                    ),
                  ),
                  Expanded(
                    child: _buildTimeInfo(
                      'Selesai',
                      store.unloadingFinishTime,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String? time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        Text(
          time ?? '-',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

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
