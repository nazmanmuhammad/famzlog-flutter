import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'driver_location_service.dart';
import 'driver_dc_service.dart';

const String notificationChannelId = 'famzlog_location_channel';
const int notificationId = 888;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    // Only available for flutter 3.0.0 and later
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    debugPrint('Background Service: onStart started');

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialize notification plugin in background isolate
    if (Platform.isAndroid) {
      // Re-create channel to ensure it exists in this isolate context
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        notificationChannelId,
        'FamzLog Location Service',
        description: 'This channel is used for important notifications.',
        importance: Importance.low,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await flutterLocalNotificationsPlugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
    }

    debugPrint('Background Service: Notification plugin initialized');

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    
    // Initial run
    await _processLocation(service, flutterLocalNotificationsPlugin);

    // Bring to foreground
    debugPrint('Background Service: Starting periodic timer (5 seconds)');
    Timer.periodic(const Duration(seconds: 300), (timer) async {
      debugPrint('Background Service: Timer tick (5s)');
      await _processLocation(service, flutterLocalNotificationsPlugin);
    });
  } catch (e, stack) {
    debugPrint('Background Service CRITICAL ERROR: $e');
    debugPrint(stack.toString());
    // Try to update notification to show error
    try {
      final FlutterLocalNotificationsPlugin errorPlugin = FlutterLocalNotificationsPlugin();
      await errorPlugin.show(
        id: notificationId,
        title: 'FamzLog Location Service',
        body: 'Service Error: ${e.toString().split('\n').first}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'FamzLog Location Service',
            icon: '@mipmap/ic_launcher',
            ongoing: true,
            importance: Importance.low,
          ),
        ),
      );
    } catch (_) {}
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

bool _isProcessing = false;

Future<void> _processLocation(
  ServiceInstance service,
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
) async {
  if (_isProcessing) {
    debugPrint('Background Service: Skipped (Already processing)');
    return;
  }
  _isProcessing = true;
  
  try {
    // 1. Notify status: Processing
    await _updateNotification(flutterLocalNotificationsPlugin, 'Processing location...');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final driverId = prefs.getInt('auth_driver_id');

    if (token == null || driverId == null) {
      debugPrint(
          'Background Service: Token or Driver ID not found. Stopping service.');
      await _updateNotification(flutterLocalNotificationsPlugin, 'Stopped: Auth missing');
      service.stopSelf();
      return;
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('Background Service: Location permission denied.');
      await _updateNotification(flutterLocalNotificationsPlugin, 'Error: Permission denied');
      return;
    }
    
    if (permission == LocationPermission.deniedForever) {
       debugPrint('Background Service: Location permission denied forever.');
       await _updateNotification(flutterLocalNotificationsPlugin, 'Error: Permission denied forever');
       return;
    }

    // 2. Notify status: Getting Location
    await _updateNotification(flutterLocalNotificationsPlugin, 'Acquiring GPS signal...');

    // Check for active trip
    int? tripId;
    try {
      final activeRecord = await DriverDcService.getActiveRecord(token: token);
      if (activeRecord != null) {
        tripId = activeRecord.id;
        debugPrint('Background Service: Found active trip ID: $tripId');
      } else {
        debugPrint('Background Service: No active trip found.');
      }
    } catch (e) {
      debugPrint('Background Service: Failed to check active trip: $e');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5), // Matches 5s interval
      forceAndroidLocationManager: true, // Better for background service
    );

    debugPrint(
        'Background Service: Location obtained: ${position.latitude}, ${position.longitude}');
    
    // 3. Notify status: Sending
    await _updateNotification(flutterLocalNotificationsPlugin, 'Sending data${tripId != null ? " (Trip #$tripId)" : ""}...');

    final locationId = await DriverLocationService.store(
      driverId: driverId,
      tripId: tripId,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      accuracy: position.accuracy,
      capturedAt: DateTime.now(),
      token: token,
    );

    debugPrint('Background Service: Location sent successfully. ID: $locationId');
    
    // 4. Notify status: Success
    final time = DateTime.now().toString().split('.')[0].split(' ')[1];
    await _updateNotification(flutterLocalNotificationsPlugin, 'Sent #$locationId at $time');
    
  } catch (e) {
    debugPrint('Background Service Error: $e');
    await _updateNotification(flutterLocalNotificationsPlugin, 'Err: ${e.toString().split('\n').first}');
  } finally {
    _isProcessing = false;
  }
}

class BackgroundLocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    /// OPTIONAL, using custom notification channel id
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId, // id
      'FamzLog Location Service', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.low, // importance must be at low or higher level
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
        // this will be executed when app is in foreground or background in separated isolate
        onStart: onStart,

        // auto start service
        autoStart: false,
        isForegroundMode: true,

        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'FamzLog Location Service',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        autoStart: false,

        // this will be executed when app is in foreground in separated isolate
        onForeground: onStart,

        // you have to enable background fetch capability on xcode project
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
