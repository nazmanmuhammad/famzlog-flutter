import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? warehouseId;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.warehouseId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      warehouseId: json['warehouse_id'] as int?,
    );
  }
}

class AuthResponse {
  final String token;
  final String tokenType;
  final AuthUser user;

  AuthResponse({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      tokenType: json['token_type'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.46:8000/api';
    }
    return 'http://192.168.1.46:8000/api';
  }
  static const String _tokenKey = 'auth_token';
  static const String _driverIdKey = 'auth_driver_id';

  static String? _token;
  static AuthUser? _currentUser;

  static String? get token => _token;
  static AuthUser? get currentUser => _currentUser;

  static Future<AuthResponse> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/login');
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
            },
            body: {
              'email': email,
              'password': password,
            },
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw AuthException('Koneksi timeout, periksa jaringan Anda');
    } catch (_) {
      throw AuthException('Tidak dapat terhubung ke server');
    }

    if (response.statusCode != 200) {
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['message'] is String) {
          throw AuthException(body['message'] as String);
        }
      } catch (_) {}
      throw AuthException(
          response.statusCode == 401 ? 'Email atau password salah' : 'Login gagal, periksa email dan password Anda');
    }

    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final auth = AuthResponse.fromJson(data);
    _token = auth.token;
    _currentUser = auth.user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setInt(_driverIdKey, _currentUser!.id);
    return auth;
  }

  static Future<AuthUser> fetchMe() async {
    if (_token == null) {
      throw AuthException('Belum login');
    }

    final uri = Uri.parse('$_baseUrl/me');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw AuthException('Gagal mengambil data pengguna');
    }

    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    _currentUser = user;
    
    // Ensure driver_id is saved for background service
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_driverIdKey, user.id);
    
    return user;
  }

  static Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null || savedToken.isEmpty) {
      return false;
    }
    _token = savedToken;
    try {
      final user = await fetchMe();
      _currentUser = user;
      return true;
    } on AuthException {
      await logout();
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_driverIdKey);
  }
}
