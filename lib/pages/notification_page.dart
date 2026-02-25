import 'package:flutter/material.dart';
import 'package:famzlog_flutter/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const _primary = Color(0xFF1580C1);

  final List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _currentPage < _lastPage) {
      _loadNotifications(page: _currentPage + 1);
    }
  }

  Future<void> _loadNotifications({int page = 1}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await NotificationService.fetchNotifications(page: page);
      if (mounted) {
        setState(() {
          if (page == 1) {
            _notifications.clear();
          }
          _notifications.addAll(response.data);
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat notifikasi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      await _loadNotifications(page: 1); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(NotificationItem item) async {
    if (item.isRead) return;

    try {
      await NotificationService.markAsRead(item.id);
      // Update local state locally to avoid full reload
      setState(() {
        final index = _notifications.indexWhere((element) => element.id == item.id);
        if (index != -1) {
          // Create new item with isRead = true
          _notifications[index] = NotificationItem(
            id: item.id,
            userId: item.userId,
            title: item.title,
            body: item.body,
            type: item.type,
            isRead: true,
            data: item.data,
            createdAt: item.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
      });
    } catch (e) {
      // Ignore error or show snackbar
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
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Tandai semua sudah dibaca',
            icon: const Icon(Icons.done_all_rounded, color: _primary),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(page: 1),
        child: _notifications.isEmpty && !_isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada notifikasi',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _notifications.length + (_isLoading ? 1 : 0),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == _notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = _notifications[index];
                  return _buildNotificationItem(item);
                },
              ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem item) {
    final bgColor = item.isRead ? Colors.white : const Color(0xFFE3F2FD);
    final date = DateTime.tryParse(item.createdAt);
    final dateStr = date != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal())
        : item.createdAt;

    return InkWell(
      onTap: () => _markAsRead(item),
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.type == 'success'
                    ? Colors.green.withOpacity(0.1)
                    : _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.type == 'success'
                    ? Icons.check_circle_outline_rounded
                    : Icons.notifications_none_rounded,
                color: item.type == 'success' ? Colors.green : _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
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
