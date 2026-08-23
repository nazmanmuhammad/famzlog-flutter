import 'dart:async';

import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:famzlog_flutter/services/driver_location_service.dart';
import 'package:famzlog_flutter/services/warehouse_service.dart';
import 'package:flutter/material.dart';
import 'package:famzlog_flutter/pages/driver_dc_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:famzlog_flutter/widgets/skeletons.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';
import 'package:famzlog_flutter/utils/date_formatter.dart';

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
  String _gpsStatusMessage = 'Mencari lokasi GPS...';

  // Warehouse geofence
  double? _warehouseLatitude;
  double? _warehouseLongitude;
  static const double _warehouseRadius = 500.0; // 500 meter

  @override
  void initState() {
    super.initState();
    _loadData();
    _startLocationUpdates();
    _loadWarehouseCoords();
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

  bool get _isInsideWarehouseRadius {
    if (_currentPosition == null || _warehouseLatitude == null || _warehouseLongitude == null) {
      return false;
    }
    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _warehouseLatitude!,
      _warehouseLongitude!,
    );
    return distance <= _warehouseRadius;
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
      if (mounted) {
        setState(() {
          _gpsStatusMessage = 'GPS tidak aktif. Aktifkan lokasi perangkat.';
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _gpsStatusMessage = 'Izin lokasi ditolak.';
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _gpsStatusMessage =
              'Izin lokasi ditolak permanen. Aktifkan dari pengaturan aplikasi.';
        });
      }
      return;
    }

    try {
      final current = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = current;
          _gpsStatusMessage = '';
        });
      }
    } catch (_) {}

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen(
          (Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
                _gpsStatusMessage = '';
              });
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() {
                _gpsStatusMessage = 'Gagal membaca lokasi GPS.';
              });
            }
          },
        );
  }

  double _calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(startLat, startLng),
      LatLng(endLat, endLng),
    );
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Start'),
        content: const Text(
          'Apakah Anda yakin ingin memulai unloading di toko ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text(
              'Ya, Mulai',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Finish'),
        content: const Text(
          'Apakah Anda yakin ingin menyelesaikan unloading di toko ini?',
        ),
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

  Future<void> _failDropOff(Store store) async {
    String selectedReason = 'Toko Tutup';
    final otherReasonController = TextEditingController();
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Gagal Bongkar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih reason gagal bongkar'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    items: const [
                      DropdownMenuItem(
                        value: 'Toko Tutup',
                        child: Text('Toko Tutup'),
                      ),
                      DropdownMenuItem(
                        value: 'Lainnya',
                        child: Text('Lainnya'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedReason = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (selectedReason == 'Lainnya') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: otherReasonController,
                      decoration: const InputDecoration(
                        labelText: 'Alasan lainnya',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedReason == 'Lainnya' &&
                        otherReasonController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      otherReasonController.dispose();
      notesController.dispose();
      return;
    }

    final reason = selectedReason == 'Lainnya'
        ? otherReasonController.text.trim()
        : selectedReason;
    final notes = notesController.text.trim();
    otherReasonController.dispose();
    notesController.dispose();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await DriverDcService.ignoreDropOff(
        widget.recordId,
        store.id,
        action: 'failed_unloading',
        reason: reason,
        notes: notes,
      );
      if (!mounted) return;
      Navigator.pop(context);
      _showSuccess('Gagal bongkar disimpan. Lanjut ke toko selanjutnya.');
      _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _ignoreDropOff(Store store, int nextRitase) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Ritase $nextRitase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin melanjutkan toko ini ke Ritase $nextRitase?',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Ya, Ritase $nextRitase',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      notesController.dispose();
      return;
    }
    final notes = notesController.text.trim();
    notesController.dispose();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Using ignoreDropOff to mark as done/skipped
      await DriverDcService.ignoreDropOff(
        widget.recordId,
        store.id,
        action: 'overload',
        notes: notes,
      );
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showSuccess('Toko berhasil dipindahkan ke Ritase $nextRitase');
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
      final response = await DriverDcService.scanOut(widget.recordId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Check for new trip creation
      if (response.containsKey('new_trip_id') &&
          response['new_trip_id'] != null) {
        final newTripId = response['new_trip_id'];

        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Trip Baru (Overload)'),
            content: Text(
              'Trip baru (Ritase ${(response['data']?['ritase'] ?? 0) + 1}) telah dibuat otomatis untuk toko yang Overload/Gagal Bongkar.\n\nApakah Anda ingin langsung memulai trip tersebut?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tidak, Nanti'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E7D96),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya, Mulai Trip'),
              ),
            ],
          ),
        );

        if (!mounted) return;

        if (proceed == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => DropOffPage(recordId: newTripId),
            ),
            (route) => route.isFirst,
          );
          return;
        }
      }

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
    showModernSnackBar(
      context,
      title: 'Berhasil',
      message: message,
      success: true,
    );
  }

  void _showError(String message) {
    showModernSnackBar(
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
          ? const DropOffSkeleton()
          : _detail == null
          ? const Center(child: Text('Gagal memuat data'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final record = _detail!.record;
    final stores = _detail!.stores;
    final nextRitase = (record.ritase ?? 1) + 1; // Calculate next ritase
    final allFinished =
        stores.isNotEmpty && stores.every((s) => s.status == 'finished');
    final isScannedOut = record.scanOutTime != null;

    // Check if any store is currently in progress or unloading
    final hasActiveStore = stores.any(
      (s) =>
          s.status == 'process' ||
          s.status == 'unloading' ||
          (s.unloadingStartTime != null &&
              s.unloadingFinishTime == null &&
              s.status != 'finished'),
    );

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
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: _primary,
                    ),
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
              return _buildStoreCard(
                store,
                isScannedOut,
                hasActiveStore,
                nextRitase, // Pass nextRitase to store card
              );
            },
          ),
        ),

        // Scan Out Button
        if (allFinished && !isScannedOut)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                if (_warehouseLatitude != null && _warehouseLongitude != null && !_isInsideWarehouseRadius)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.location_off, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Anda harus berada dalam radius 500m dari DC untuk scan finish trip',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isInsideWarehouseRadius || _warehouseLatitude == null ? _scanOut : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isInsideWarehouseRadius || _warehouseLatitude == null
                          ? Colors.green
                          : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isInsideWarehouseRadius || _warehouseLatitude == null
                              ? Icons.check_circle_outline
                              : Icons.lock_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Scan Finish Trip (Scan in DC)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Future<void> _processDropOff(Store store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Menuju Toko'),
        content: const Text(
          'Apakah Anda yakin ingin mengubah status ke process (Menuju Toko)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text(
              'Ya, Proses',
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

  Widget _buildStoreCard(
    Store store,
    bool isScannedOut,
    bool hasActiveStore,
    int nextRitase, // Add nextRitase parameter
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    // Default
    statusText = 'Belum Ke Toko';
    statusColor = Colors.grey;
    statusIcon = Icons.circle_outlined;
    
    // Check if qty_status is "Ritase" to show as overload
    final isRitase = store.qtyStatus?.toLowerCase() == 'ritase';
    final plannedStatusText = store.plannedStatus ?? '-';
    final isFailedUnloading =
        (store.plannedStatus?.toLowerCase() == 'gagal bongkar') &&
        store.overloadTime != null;

    if (store.overloadTime != null) {
      statusText = isFailedUnloading ? 'Gagal Bongkar' : 'Overload';
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
    } else if (isRitase) {
      // Store marked as "Ritase" in qty_status
      statusText = 'Ritase';
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
    } else if (store.unloadingStartTime != null &&
        store.unloadingFinishTime == null) {
      statusText = 'Unloading';
      statusColor = Colors.orange;
      statusIcon = Icons.downloading_rounded;
    } else if (store.unloadingFinishTime != null) {
      statusText = 'Finish';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    } else if (store.status == 'process') {
      statusText = 'Menuju Toko';
      statusColor = Colors.blue;
      statusIcon = Icons.directions_car_rounded;
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
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Tujuan: ${(store.status == 'not_visited') ? '-' : plannedStatusText}',
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
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
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
            
            // ETA Information
            if (store.estimatedArrivalTime != null && 
                store.unloadingFinishTime == null && 
                store.overloadTime == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, 
                      size: 18, 
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ETA: ${store.estimatedArrivalTime}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          if (store.distanceKm != null || 
                              store.estimatedTravelMinutes != null)
                            const SizedBox(height: 4),
                          if (store.distanceKm != null || 
                              store.estimatedTravelMinutes != null)
                            Row(
                              children: [
                                if (store.distanceKm != null) ...[
                                  Icon(Icons.straighten, 
                                    size: 12, 
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${store.distanceKm!.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                                if (store.distanceKm != null && 
                                    store.estimatedTravelMinutes != null)
                                  const SizedBox(width: 12),
                                if (store.estimatedTravelMinutes != null) ...[
                                  Icon(Icons.directions_car, 
                                    size: 12, 
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    store.estimatedTravelMinutes! >= 60
                                        ? '${store.estimatedTravelMinutes! ~/ 60}h ${store.estimatedTravelMinutes! % 60}m'
                                        : '${store.estimatedTravelMinutes}m',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            if (!isScannedOut) ...[
              if (store.status == 'process')
                Builder(
                  builder: (context) {
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
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _gpsStatusMessage,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
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

                    if (distance > 500) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_off_outlined,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Jarak ke toko: ${distance.toStringAsFixed(0)}m\n(Maksimal 500m untuk mulai)',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 12,
                                ),
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
                  },
                ),
              if (store.status != 'process' &&
                  store.status != 'unloading' &&
                  store.status != 'finished')
                SizedBox(
                  width: double.infinity,
                  child: (store.qtyStatus?.toLowerCase() == 'ritase')
                      ? ElevatedButton(
                          onPressed: () => _ignoreDropOff(store, nextRitase), // Pass nextRitase
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Abaikan (Overload)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: hasActiveStore
                              ? null
                              : () => _processDropOff(store),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasActiveStore
                                ? Colors.grey.shade400
                                : _primary,
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
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _finishDropOff(store),
                        icon: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                        ),
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
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _failDropOff(store),
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text('Gagal Bongkar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
            if (store.overloadTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildTimeInfo(
                  isFailedUnloading ? 'Waktu Gagal Bongkar' : 'Waktu Overload',
                  store.overloadTime,
                ),
              )
            else if (store.status == 'finished')
              Row(
                children: [
                  Expanded(
                    child: _buildTimeInfo('Mulai', store.unloadingStartTime),
                  ),
                  Expanded(
                    child: _buildTimeInfo('Selesai', store.unloadingFinishTime),
                  ),
                ],
              ),
            if (store.overloadTime != null &&
                (store.driverNotes?.trim().isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Notes: ${store.driverNotes}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
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
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        Text(
          DateFormatter.format(time),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
