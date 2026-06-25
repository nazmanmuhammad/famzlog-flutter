import 'dart:async';
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
  // Changed default to 30 seconds for better GPS accuracy
  int _intervalSeconds = 30;
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
        'Location permission permanently denied. Please enable it in settings.',
      );
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
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      _currentPosition = pos;
      await _sendLocation(pos);
    } catch (e) {
      onError?.call('Gagal mendapatkan lokasi awal: $e');
    }

    // Use position stream - NO MORE TIMER!
    _startLocationStream();
  }

  /// Stop tracking.
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
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
        // Use bestForNavigation for stable GPS tracking
        accuracy: LocationAccuracy.bestForNavigation,
        // Only send updates when moved at least 10 meters
        distanceFilter: 10,
        // Minimum time between updates (prevents rapid updates)
        intervalDuration: const Duration(seconds: 10),
        // Important for background execution
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "FAM ZLOG Tracking",
          notificationText: "Location tracking is running in background",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      );
    }

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            if (!_isTracking) return;

            _currentPosition = position;

            // If tripId is still null, try to fetch it again
            if (_tripId == null) {
              try {
                final activeRecord = await DriverDcService.getActiveRecord();
                if (activeRecord != null) {
                  _tripId = activeRecord.id;
                }
              } catch (_) {}
            }

            // Send location through stream - filtering happens in _sendLocation
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
      // ===== CRITICAL FILTERS - Prevent GPS spider web =====

      // 1. Filter: Accuracy must be < 30 meters
      if (position.accuracy > 30) {
        debugPrint(
          'LocationTracking: GPS accuracy too poor (${position.accuracy}m) - SKIPPED',
        );
        return;
      }

      // 2. Filter: Minimum distance from last sent position
      if (_lastSentPosition != null) {
        final double distance = Geolocator.distanceBetween(
          _lastSentPosition!.latitude,
          _lastSentPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Skip if distance < 10 meters
        if (distance < 10) {
          debugPrint(
            'LocationTracking: Distance too small (${distance.toStringAsFixed(1)}m) - SKIPPED',
          );
          return;
        }

        // 3. Filter: Check for impossible jumps
        final int timeDiffSeconds = position.timestamp
            .difference(_lastSentPosition!.timestamp)
            .inSeconds;

        if (timeDiffSeconds > 0) {
          // Calculate speed from distance and time
          final double speedKmh = (distance / 1000) / (timeDiffSeconds / 3600);

          // Skip if calculated speed > 150 km/h (impossible for truck)
          if (speedKmh > 150) {
            debugPrint(
              'LocationTracking: Impossible speed detected (${speedKmh.toStringAsFixed(0)} km/h) - SKIPPED',
            );
            return;
          }

          // Skip hard jumps (> 500m in < 30 seconds)
          if (distance > 500 && timeDiffSeconds < 30) {
            debugPrint(
              'LocationTracking: Hard jump detected (${distance.toStringAsFixed(0)}m in ${timeDiffSeconds}s) - SKIPPED',
            );
            return;
          }
        }
      }

      // 4. Filter: Skip if timestamp is same as last sent
      if (_lastSentPosition != null &&
          position.timestamp == _lastSentPosition!.timestamp) {
        debugPrint('LocationTracking: Same timestamp - SKIPPED');
        return;
      }

      // 5. Filter: Skip if coordinates are exactly the same
      if (_lastSentPosition != null &&
          position.latitude == _lastSentPosition!.latitude &&
          position.longitude == _lastSentPosition!.longitude) {
        debugPrint('LocationTracking: Same coordinates - SKIPPED');
        return;
      }

      // ===== GPS VALID - SEND TO SERVER =====

      final driverId = AuthService.currentUser?.id;

      // Double check tripId if still null
      if (_tripId == null) {
        final activeRecord = await DriverDcService.getActiveRecord();
        if (activeRecord != null) _tripId = activeRecord.id;
      }

      // Calculate speed manually if device reports 0
      double speedToSend = position.speed;
      if (speedToSend <= 0 && _lastSentPosition != null) {
        final double dist = Geolocator.distanceBetween(
          _lastSentPosition!.latitude,
          _lastSentPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        final int timeDiff = position.timestamp
            .difference(_lastSentPosition!.timestamp)
            .inSeconds;
        if (timeDiff > 0) {
          speedToSend = dist / timeDiff; // m/s
        }
      }

      // Convert m/s to km/h
      speedToSend = speedToSend * 3.6;

      // CRITICAL: Use position.timestamp, NOT DateTime.now()
      final locationId = await DriverLocationService.store(
        driverId: driverId,
        tripId: _tripId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: speedToSend,
        accuracy: position.accuracy,
        capturedAt: position.timestamp, // ← Use GPS timestamp!
      );

      _lastSentPosition = position;
      onLocationSent?.call(position.latitude, position.longitude);

      debugPrint(
        'LocationTracking: ✅ Location sent successfully. ID: $locationId, Accuracy: ${position.accuracy.toStringAsFixed(1)}m, Speed: ${speedToSend.toStringAsFixed(1)} km/h',
      );
    } catch (e) {
      debugPrint('Error sending location: $e');
      onError?.call('Gagal mengirim lokasi: $e');
    }
  }
}
