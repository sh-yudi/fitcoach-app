import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    late http.Response res;
    try {
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          res = await http
              .post(uri, headers: _headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          res = await http
              .put(uri, headers: _headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw ApiException('Unsupported method $method');
      }
    } on TimeoutException {
      throw ApiException('Server took too long to respond. Check your connection.');
    } on http.ClientException catch (e) {
      debugPrint('Network error: $e');
      throw ApiException('Cannot reach the server. Is it running?');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? {} : jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode == 401) {
      String message = _token != null
          ? 'Session expired. Please log in again.'
          : 'Invalid email or password.';
      try {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        if (j['error'] != null) message = j['error'] as String;
        if (j['errors'] != null) message = (j['errors'] as List).join(', ');
      } catch (_) {}
      _token = null;
      throw ApiException(message, 401);
    }
    String message = 'Request failed (${res.statusCode})';
    try {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['error'] != null) message = j['error'] as String;
      if (j['errors'] != null) message = (j['errors'] as List).join(', ');
    } catch (_) {}
    throw ApiException(message, res.statusCode);
  }

  // ---- Auth ----
  Future<({String token, String? rememberToken, User user})> register(
    Map<String, dynamic> data, {
    bool remember = false,
  }) async {
    final j = await _request('POST', '/api/auth/register', body: {...data, 'remember': remember});
    return (
      token: j['token'] as String,
      rememberToken: j['rememberToken'] as String?,
      user: User.fromJson(j['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, String? rememberToken, User user})> login(
    String email,
    String password, {
    bool remember = false,
  }) async {
    final j = await _request('POST', '/api/auth/login', body: {
      'email': email,
      'password': password,
      'remember': remember,
    });
    return (
      token: j['token'] as String,
      rememberToken: j['rememberToken'] as String?,
      user: User.fromJson(j['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, User user})> oneTapLogin(String rememberToken) async {
    final j = await _request('POST', '/api/auth/one-tap-login', body: {'rememberToken': rememberToken});
    return (token: j['token'] as String, user: User.fromJson(j['user'] as Map<String, dynamic>));
  }

  Future<({String rememberToken, User user})> enableOneTap() async {
    final j = await _request('POST', '/api/auth/enable-one-tap');
    return (
      rememberToken: j['rememberToken'] as String,
      user: User.fromJson(j['user'] as Map<String, dynamic>),
    );
  }

  Future<void> disableOneTap() async {
    await _request('POST', '/api/auth/disable-one-tap');
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/api/auth/logout');
    } catch (_) {}
    _token = null;
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _request(
      'POST',
      '/api/auth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  // ---- Profile ----
  Future<User> getProfile() async {
    final j = await _request('GET', '/api/profile');
    return User.fromJson(j['user'] as Map<String, dynamic>);
  }

  Future<User> updateProfile(Map<String, dynamic> body) async {
    final j = await _request('PUT', '/api/profile', body: body);
    return User.fromJson(j['user'] as Map<String, dynamic>);
  }

  Future<Assessment> updateGoal(String goal) async {
    await _request('PUT', '/api/profile', body: {'goal': goal});
    return getAssessment();
  }

  // ---- Plans ----
  Future<Assessment> getAssessment() async {
    final j = await _request('GET', '/api/plans/assessment');
    return Assessment.fromJson(j['assessment'] as Map<String, dynamic>);
  }

  Future<({Assessment assessment, DietPlan diet, bool gymToday})> getDiet() async {
    final j = await _request('GET', '/api/plans/diet');
    return (
      assessment: Assessment.fromJson(j['assessment'] as Map<String, dynamic>),
      diet: DietPlan.fromJson(j['diet'] as Map<String, dynamic>),
      gymToday: j['gymToday'] as bool? ?? true,
    );
  }

  Future<({Assessment assessment, WorkoutPlan workout, Map<String, dynamic> ticks})> getWorkout() async {
    final j = await _request('GET', '/api/plans/workout');
    return (
      assessment: Assessment.fromJson(j['assessment'] as Map<String, dynamic>),
      workout: WorkoutPlan.fromJson(j['workout'] as Map<String, dynamic>),
      ticks: (j['ticks'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<void> completeWorkout(int day) async {
    await _request('POST', '/api/plans/workout/complete', body: {'day': day});
  }

  Future<void> saveWorkoutTicks(int day, List<String> names) async {
    await _request('POST', '/api/plans/workout/ticks', body: {'day': day, 'names': names});
  }

  Future<MealSchedule> getSchedule() async {
    final j = await _request('GET', '/api/plans/schedule');
    return MealSchedule.fromJson(j);
  }

  // ---- Developer info (global constant) ----
  Future<DeveloperInfo> getDeveloperInfo() async {
    final j = await _request('GET', '/api/developer');
    return DeveloperInfo.fromJson(j['developer'] as Map<String, dynamic>);
  }

  // ---- Gym calendar ----
  Future<User> setGymPlan(String date, bool going) async {
    final j = await _request('PUT', '/api/gym', body: {'date': date, 'going': going});
    return User.fromJson(j['user'] as Map<String, dynamic>);
  }

  Future<User> setGymAttendance(String date, bool attended) async {
    final j = await _request('PUT', '/api/gym/attendance', body: {'date': date, 'attended': attended});
    return User.fromJson(j['user'] as Map<String, dynamic>);
  }

  Future<({Map<String, bool> gymPlans, Map<String, bool> attendance})> getGymCalendar() async {
    final j = await _request('GET', '/api/gym');
    Map<String, bool> toBool(dynamic v) {
      if (v is! Map) return <String, bool>{};
      return v.map((k, val) => MapEntry(k.toString(), val == true));
    }
    return (
      gymPlans: toBool(j['gymPlans']),
      attendance: toBool(j['attendance']),
    );
  }
}
