import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:geolocator_android/geolocator_android.dart'; // Usually not needed if geolocator exports it, but let's check.
// Actually, AndroidSettings is part of geolocator platform interface which is exported.

import 'driver_location_service.dart';
import 'auth_service.dart';

/// Tracking mode: distance-based (every N meters) or interval-based (every N seconds).
enum TrackingMode { distance, interval }

class LocationTrackingService {
  LocationTrackingService._();
  static final LocationTrackingService instance = LocationTrackingService._();

  // ── Configuration ──────────────────────────────────────────────────────────
  // Changed default to interval based on user request
  TrackingMode _mode = TrackingMode.interval;
  TrackingMode get mode => _mode;
  
  set mode(TrackingMode value) {
    if (_mode == value) return;
    final wasTracking = _isTracking;
    final savedTripId = _tripId;
    
    _mode = value;
    
    // Automatically restart tracking if active to apply new mode
    if (wasTracking) {
      stopTracking();
      startTracking(tripId: savedTripId);
    }
  }

  /// Minimum distance in meters before sending a new location (distance mode).
  double distanceThresholdMeters = 50.0;

  /// Interval in seconds between location sends (interval mode).
  // Changed default to 5 seconds
  int _intervalSeconds = 5;
  int get intervalSeconds => _intervalSeconds;
  
  set intervalSeconds(int value) {
    if (_intervalSeconds == value) return;
    final wasTracking = _isTracking;
    final savedTripId = _tripId;
    
    _intervalSeconds = value;
    
    // Automatically restart tracking if active to apply new interval
    if (wasTracking) {
      stopTracking();
      startTracking(tripId: savedTripId);
    }
  }

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isTracking = false;
  bool get isTracking => _isTracking;

  int? _tripId;
  int? get tripId => _tripId;

  Position? _lastSentPosition;
  Position? _currentPosition; // Keep track of latest position from stream
  StreamSubscription<Position>? _positionSubscription;
  Timer? _intervalTimer;

  /// Callback for when a location is successfully sent.
  void Function(double lat, double lng)? onLocationSent;

  /// Callback for errors during tracking.
  void Function(String error)? onError;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Check and request location permissions. Returns true if granted.
  Future<bool> ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onError?.call('Location services are disabled. Please enable GPS.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onError?.call('Location permission denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      onError?.call(
          'Location permission permanently denied. Please enable it in settings.');
      return false;
    }

    return true;
  }

  /// Start tracking. Call [ensurePermissions] first.
  Future<void> startTracking({int? tripId}) async {
    if (_isTracking) return;

    final ok = await ensurePermissions();
    if (!ok) return;

    // Resolve trip ID: use provided one, or fetch active one
    if (tripId != null) {
      _tripId = tripId;
    } else {
      // Try to fetch active trip ID
      try {
        final activeRecord = await DriverDcService.getActiveRecord();
        if (activeRecord != null) {
          _tripId = activeRecord.id;
        }
      } catch (e) {
        debugPrint('Error fetching active record: $e');
      }
    }

    _isTracking = true;
    _lastSentPosition = null;
    _currentPosition = null;

    // Send initial position immediately
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _currentPosition = pos;
      await _sendLocation(pos);
    } catch (e) {
      onError?.call('Gagal mendapatkan lokasi awal: $e');
    }

    // Always use stream for background support, regardless of mode
    _startLocationStream();

    // If interval mode, start the periodic timer to ensure heartbeat
    if (mode == TrackingMode.interval) {
      _startIntervalTimer();
    }
  }

  void _startIntervalTimer() {
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      Position? posToSend = _currentPosition;

      // If no position from stream yet, try to get current position
      if (posToSend == null) {
        try {
           posToSend = await Geolocator.getCurrentPosition(
             locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
           );
           _currentPosition = posToSend;
        } catch (_) {}
      }

      if (posToSend != null) {
        await _sendLocation(posToSend);
      }
    });
  }

  /// Stop tracking.
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _intervalTimer?.cancel();
    _intervalTimer = null;
    _lastSentPosition = null;
    _currentPosition = null;
    _tripId = null;
  }

  // ── Unified Location Stream (Background Supported) ─────────────────────────

  void _startLocationStream() {
    _positionSubscription?.cancel();

    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: mode == TrackingMode.distance ? distanceThresholdMeters.toInt() : 0,
        intervalDuration: Duration(seconds: intervalSeconds),
        // Important for background execution
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "FAM ZLOG Tracking",
          notificationText: "Location tracking is running in background",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: mode == TrackingMode.distance ? distanceThresholdMeters.toInt() : 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: mode == TrackingMode.distance ? distanceThresholdMeters.toInt() : 0,
      );
    }

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(
      (Position position) async {
        if (!_isTracking) return;

        _currentPosition = position;

        // If in interval mode, we DON'T send here (Timer handles it).
        // UNLESS we want to support distance mode too.
        if (mode == TrackingMode.interval) {
          return; 
        }

        // --- Distance Mode Logic (if needed later) ---
        // For now, if not interval, we assume distance or immediate
        
        // If tripId is still null, try to fetch it again (maybe started later)
        if (_tripId == null) {
           try {
             final activeRecord = await DriverDcService.getActiveRecord();
             if (activeRecord != null) {
               _tripId = activeRecord.id;
             }
           } catch (_) {}
        }

        await _sendLocation(position);
      },
      onError: (e) {
        onError?.call('Location stream error: $e');
      },
    );
  }

  // ── Send location to backend ───────────────────────────────────────────────

  Future<void> _sendLocation(Position position) async {
    try {
      final driverId = AuthService.currentUser?.id;
      
      // Double check tripId if still null
      if (_tripId == null) {
         final activeRecord = await DriverDcService.getActiveRecord();
         if (activeRecord != null) _tripId = activeRecord.id;
      }

      await DriverLocationService.store(
        driverId: driverId,
        tripId: _tripId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed, // Send actual speed (even if 0)
        accuracy: position.accuracy, // Send actual accuracy (even if 0)
        capturedAt: DateTime.now(),
      );
      _lastSentPosition = position;
      onLocationSent?.call(position.latitude, position.longitude);
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  // ── Haversine distance (meters) ────────────────────────────────────────────

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);
}
