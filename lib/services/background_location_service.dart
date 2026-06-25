import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'driver_location_service.dart';
import 'driver_dc_service.dart';

const String notificationChannelId = 'famzlog_location_channel';
const int notificationId = 888;

// Global state for background service
Position? _lastValidPosition;
StreamSubscription<Position>? _positionSubscription;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    debugPrint('Background Service: onStart started');

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialize notification plugin
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        notificationChannelId,
        'FamzLog Location Service',
        description: 'GPS tracking service for fleet management',
        importance: Importance.low,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const AndroidNotificationChannel alertChannel =
          AndroidNotificationChannel(
        'famzlog_alert_channel',
        'FamzLog Alerts',
        description: 'Important alerts from admin',
        importance: Importance.high,
        playSound: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(alertChannel);

      await flutterLocalNotificationsPlugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
    }

    debugPrint('Background Service: Notification initialized');

    service.on('stopService').listen((event) {
      _positionSubscription?.cancel();
      service.stopSelf();
    });

    // Start position stream - NO TIMER!
    await _startLocationStream(service, flutterLocalNotificationsPlugin);

    // Check notifications every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkNotifications(flutterLocalNotificationsPlugin);
    });
  } catch (e, stack) {
    debugPrint('Background Service ERROR: $e');
    debugPrint(stack.toString());
  }
}

Future<void> _startLocationStream(
  ServiceInstance service,
  FlutterLocalNotificationsPlugin notificationPlugin,
) async {
  try {
    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _updateNotification(
        notificationPlugin,
        'Location permission denied',
      );
      return;
    }

    // Update notification
    await _updateNotification(notificationPlugin, 'Starting GPS tracking...');

    // Cancel previous subscription if exists
    _positionSubscription?.cancel();

    // Configure location settings - USE STREAM!
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10, // Only update when moved 10m
    );

    // Start position stream
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(
      (Position position) async {
        await _handlePosition(position, notificationPlugin);
      },
      onError: (error) {
        debugPrint('Background Service: Stream error: $error');
        _updateNotification(notificationPlugin, 'GPS error: $error');
      },
    );

    debugPrint('Background Service: Position stream started');
  } catch (e) {
    debugPrint('Background Service: Failed to start stream: $e');
    await _updateNotification(notificationPlugin, 'Failed to start: $e');
  }
}

Future<void> _handlePosition(
  Position position,
  FlutterLocalNotificationsPlugin notificationPlugin,
) async {
  try {
    // ===== FILTER 1: Accuracy =====
    if (position.accuracy > 30) {
      debugPrint(
        'Background: Poor accuracy (${position.accuracy}m) - SKIPPED',
      );
      return;
    }

    // ===== FILTER 2: Minimum distance =====
    if (_lastValidPosition != null) {
      final double distance = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < 10) {
        debugPrint('Background: Distance too small (${distance.toStringAsFixed(1)}m) - SKIPPED');
        return;
      }
    }

    // ===== FILTER 3: Duplicate timestamp =====
    if (_lastValidPosition != null &&
        position.timestamp == _lastValidPosition!.timestamp) {
      debugPrint('Background: Duplicate timestamp - SKIPPED');
      return;
    }

    // ===== FILTER 4: Duplicate coordinates =====
    if (_lastValidPosition != null &&
        position.latitude == _lastValidPosition!.latitude &&
        position.longitude == _lastValidPosition!.longitude) {
      debugPrint('Background: Duplicate coordinates - SKIPPED');
      return;
    }

    // ===== GPS VALID - SEND TO SERVER =====

    // Get auth data
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final driverId = prefs.getInt('auth_driver_id');

    if (token == null || driverId == null) {
      debugPrint('Background: No auth data - STOPPED');
      await _updateNotification(notificationPlugin, 'Auth missing - stopped');
      return;
    }

    // Get active trip
    int? tripId;
    try {
      final activeRecord = await DriverDcService.getActiveRecord(token: token);
      if (activeRecord != null) {
        tripId = activeRecord.id;
      }
    } catch (e) {
      debugPrint('Background: Failed to get trip: $e');
    }

    // Calculate speed if needed
    double speedToSend = position.speed;
    if (speedToSend <= 0 && _lastValidPosition != null) {
      final double dist = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      final int timeDiff = position.timestamp
          .difference(_lastValidPosition!.timestamp)
          .inSeconds;
      if (timeDiff > 0) {
        speedToSend = dist / timeDiff; // m/s
      }
    }

    // Convert m/s to km/h
    speedToSend = speedToSend * 3.6;

    // Send to server - USE GPS TIMESTAMP!
    final locationId = await DriverLocationService.store(
      driverId: driverId,
      tripId: tripId,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: speedToSend,
      accuracy: position.accuracy,
      capturedAt: position.timestamp, // ← GPS timestamp, NOT DateTime.now()!
      token: token,
    );

    _lastValidPosition = position;

    final time = DateTime.now().toString().split('.')[0].split(' ')[1];
    await _updateNotification(
      notificationPlugin,
      'Sent #$locationId at $time${tripId != null ? " (Trip #$tripId)" : ""}',
    );

    debugPrint(
      'Background: ✅ Sent #$locationId, Acc: ${position.accuracy.toStringAsFixed(1)}m, Speed: ${speedToSend.toStringAsFixed(1)} km/h',
    );
  } catch (e) {
    debugPrint('Background: Error handling position: $e');
    await _updateNotification(notificationPlugin, 'Error: $e');
  }
}

Future<void> _checkNotifications(
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    const String baseUrl = 'https://fm.fam-zlog.web.id/api';
    final uri = Uri.parse('$baseUrl/notifications');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final notifications = data['data']['data'] as List;

      for (var notification in notifications) {
        if (notification['is_read'] == false) {
          final int notifId = notification['id'];
          final String title = notification['title'] ?? 'Alert';
          final String body = notification['body'] ?? '';

          await flutterLocalNotificationsPlugin.show(
            id: notifId,
            title: title,
            body: body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'famzlog_alert_channel',
                'FamzLog Alerts',
                channelDescription: 'Important alerts from admin',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
              ),
            ),
          );

          // Mark as read
          await http.put(
            Uri.parse('$baseUrl/notifications/$notifId/read'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        }
      }
    }
  } catch (e) {
    debugPrint('Background: Failed to check notifications: $e');
  }
}

Future<void> _updateNotification(
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  String message,
) async {
  final timestamp = DateTime.now().toString().split('.')[0];
  debugPrint('[$timestamp] NOTIF: $message');

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: 'FamzLog Location Service',
      body: message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'FamzLog Location Service',
          icon: '@mipmap/ic_launcher',
          ongoing: true,
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
    );
  }
}

class BackgroundLocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'FamzLog Location Service',
      description: 'GPS tracking service for fleet management',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
    }

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'FamzLog Location Service',
        initialNotificationContent: 'Initializing GPS tracking...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }
}
