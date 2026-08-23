import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class NotificationItem {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String createdAt;
  final String updatedAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] is bool
          ? json['is_read'] as bool
          : (json['is_read'] == 1 || json['is_read'] == '1'),
      data: json['data'] is String
          ? jsonDecode(json['data'])
          : json['data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class NotificationResponse {
  final int currentPage;
  final int lastPage;
  final List<NotificationItem> data;
  final int total;

  NotificationResponse({
    required this.currentPage,
    required this.lastPage,
    required this.data,
    required this.total,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List)
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return NotificationResponse(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      data: dataList,
      total: json['total'] as int,
    );
  }
}

class NotificationService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'https://fm.fam-zlog.web.id/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://fm.fam-zlog.web.id/api';
    }
    return 'https://fm.fam-zlog.web.id/api';
  }

  static Map<String, String> _headers() {
    final token = AuthService.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<NotificationItem>> fetchPendingAlerts() async {
    final uri = Uri.parse('$_baseUrl/notifications/pending-alerts');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final dataList = (json['data'] as List)
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return dataList;
    }
    throw Exception('Failed to load pending alerts');
  }

  static Future<void> submitResponse(int id, String responseText) async {
    final uri = Uri.parse('$_baseUrl/notifications/$id/response');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'response': responseText}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit response');
    }
  }

  static Future<NotificationResponse> fetchNotifications({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/notifications?page=$page');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'ok' && json['data'] != null) {
        return NotificationResponse.fromJson(json['data']);
      }
    }
    throw Exception('Gagal memuat notifikasi');
  }

  static Future<void> markAsRead(int id) async {
    final uri = Uri.parse('$_baseUrl/notifications/$id/read');
    final response = await http.put(uri, headers: _headers());

    if (response.statusCode != 200) {
      throw Exception('Gagal menandai notifikasi sudah dibaca');
    }
  }

  static Future<void> markAllAsRead() async {
    final uri = Uri.parse('$_baseUrl/notifications/read-all');
    final response = await http.put(uri, headers: _headers());

    if (response.statusCode != 200) {
      throw Exception('Gagal menandai semua notifikasi sudah dibaca');
    }
  }

  static Future<int> unreadCount() async {
    try {
      final uri = Uri.parse('$_baseUrl/notifications/unread-count');
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonResp['status'] == 'ok') {
          final data = jsonResp['data'];
          if (data is Map && data['unread'] is int) {
            return data['unread'] as int;
          }
          if (data is int) return data;
        }
      }
    } catch (_) {}
    try {
      final page = await fetchNotifications(page: 1);
      return page.data.where((e) => !e.isRead).length;
    } catch (_) {
      return 0;
    }
  }
}
