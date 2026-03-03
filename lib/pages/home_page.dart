import 'package:flutter/material.dart';
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/services/warehouse_service.dart';
import 'package:famzlog_flutter/pages/driver_dc_page.dart';
import 'package:famzlog_flutter/pages/history_page.dart';
import 'package:famzlog_flutter/pages/account_page.dart';
import 'package:famzlog_flutter/pages/notification_page.dart';
import 'package:famzlog_flutter/pages/report_page.dart';
import 'package:famzlog_flutter/services/notification_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:famzlog_flutter/models/driver_dc_record.dart';
import 'package:famzlog_flutter/utils/date_formatter.dart';

import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _warehouseName;
  int _unread = 0;
  
  // Data for summary and recent activity
  Map<String, int> _summary = {'ongoing': 0, 'completed': 0};
  List<DriverDcRecord> _recentRecords = [];
  bool _isLoading = false;
  Timer? _alertTimer;
  bool _isAlertShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWarehouse();
    _loadUnread();
    _initBackgroundService();
    _loadDashboardData();
    _startAlertCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alertTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingAlerts();
      _loadUnread();
      _loadDashboardData();
    }
  }

  void _startAlertCheck() {
    _checkPendingAlerts();
    _alertTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkPendingAlerts();
    });
  }

  Future<void> _checkPendingAlerts() async {
    if (_isAlertShowing) return;

    try {
      final alerts = await NotificationService.fetchPendingAlerts();
      if (alerts.isNotEmpty) {
        // Show dialog for the first alert
        if (mounted) {
          _showBlockingAlert(alerts.first);
        }
      }
    } catch (e) {
      debugPrint('Error checking alerts: $e');
    }
  }

  void _showBlockingAlert(NotificationItem alert) {
    if (_isAlertShowing) return;
    _isAlertShowing = true;
    
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  alert.title,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.body),
                      const SizedBox(height: 16),
                      const Text(
                        'Silakan masukkan alasan/keterangan:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Tulis alasan di sini...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (isSubmitting)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () async {
                        if (reasonController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Alasan wajib diisi')),
                          );
                          return;
                        }

                        setState(() => isSubmitting = true);
                        try {
                          await NotificationService.submitResponse(
                            alert.id,
                            reasonController.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            _isAlertShowing = false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tanggapan berhasil dikirim')),
                            );
                            _loadUnread(); // Refresh unread count
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal mengirim: $e')),
                            );
                            setState(() => isSubmitting = false);
                          }
                        }
                      },
                      child: const Text('Kirim Tanggapan'),
                    ),
                ],
              );
            },
          ),
        );
      },
    ).then((_) {
      _isAlertShowing = false;
    });
  }

  Future<void> _initBackgroundService() async {
    // Request notification permission for Android 13+
    await Permission.notification.request();
    
    // Request location permission
    var status = await Permission.location.request();
    
    if (status.isGranted) {
      final service = FlutterBackgroundService();
      var isRunning = await service.isRunning();
      if (!isRunning) {
        service.startService();
      }
    }
  }

  Future<void> _loadWarehouse() async {
    final name = await WarehouseService.getSelectedWarehouseName();
    if (mounted) {
      setState(() {
        _warehouseName = name;
      });
    }
  }

  Future<void> _loadUnread() async {
    try {
      final count = await NotificationService.unreadCount();
      if (mounted) {
        setState(() {
          _unread = count;
        });
      }
    } catch (_) {}
  }
  
  Future<void> _loadDashboardData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      final summary = await DriverDcService.fetchSummary();
      final recent = await DriverDcService.fetchRecords(limit: 5);
      
      if (mounted) {
        setState(() {
          _summary = summary;
          _recentRecords = recent;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exitWarehouse() async {
    await WarehouseService.clearSelectedWarehouse();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/warehouse-selection');
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1580C1);

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await _loadDashboardData();
                await _loadUnread();
              },
              child: _buildHomeContent(),
            ),
            const HistoryPage(),
            const ReportPage(),
            const AccountPage(),
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
            onTap: (i) {
              setState(() => _currentIndex = i);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: primary,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assessment_rounded),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    const primary = Color(0xFF1580C1);
    final user = AuthService.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar: greeting + notification
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.name ?? 'User'} 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back to FAM ZLOG',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (_warehouseName != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _exitWarehouse,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.store_rounded,
                                size: 14,
                                color: Color(0xFF1580C1),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_warehouseName (Keluar)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1580C1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationPage()),
                    );
                    await _loadUnread();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.grey.shade700,
                        ),
                        if (_unread > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                _unread > 99 ? '99+' : '$_unread',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1580C1), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/famzlog.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.role ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      _ProfileStat(value: '${_summary['ongoing']}', label: 'Ongoing'),
                      _profileDivider(),
                      _ProfileStat(value: '${_summary['completed']}', label: 'Completed'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Menu title
            const Text(
              'Menu',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 14),

            // Menu grid (Live Track hidden)
            Row(
              children: [
                _ActionCard(
                  icon: Icons.local_shipping_rounded,
                  label: 'Driver DC',
                  color: primary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DriverDcRidePage(),
                      ),
                    ).then((_) => _loadDashboardData()); // Reload when coming back
                  },
                ),
                const SizedBox(width: 12),
                _ActionCard(
                  icon: Icons.history_rounded,
                  label: 'History',
                  color: const Color(0xFF00897B),
                  onTap: () {
                    setState(() => _currentIndex = 1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _currentIndex = 1);
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_recentRecords.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _isLoading ? 'Loading...' : 'No recent activity',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              ..._recentRecords.map((record) {
                final isCompleted = record.scanOutTime != null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_shipping_outlined,
                            color: primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${record.licensePlate}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                record.routeCode,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormatter.format(record.scanInTime),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFF00A86B).withOpacity(0.1)
                                    : const Color(0xFFF4A100).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCompleted ? 'Completed' : 'Ongoing',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? const Color(0xFF00A86B)
                                      : const Color(0xFFF4A100),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

Widget _profileDivider() {
  return Container(
    width: 1,
    height: 36,
    color: Colors.white.withOpacity(0.3),
  );
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _FleetCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
