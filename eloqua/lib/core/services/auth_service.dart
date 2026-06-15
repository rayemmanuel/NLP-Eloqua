import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'feed_service.dart';

// ── AuthResult ─────────────────────────────────────────────────────────────────
class AuthResult {
  final bool success;
  final String? errorMessage;
  const AuthResult._({required this.success, this.errorMessage});
  factory AuthResult.ok() => const AuthResult._(success: true);
  factory AuthResult.fail(String msg) =>
      AuthResult._(success: false, errorMessage: msg);
}

// ── AuthService ────────────────────────────────────────────────────────────────
class AuthService extends ChangeNotifier {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final ApiService _api = ApiService.instance;

  String? _token;
  String? _userId;
  String? _name;
  String? _email;
  Uint8List? _profilePhotoBytes; // holds downloaded photo bytes for display

  String? get token => _token;
  String? get userId => _userId;
  String? get name => _name;
  String? get email => _email;
  Uint8List? get profilePhotoBytes => _profilePhotoBytes;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  String get currentUserName => _name ?? 'User_Scan_01';
  String get currentUserEmail => _email ?? '';

  // ── Init (no-op — session lives in memory only) ────────────────────────────
  Future<void> init() async {}

  // ── Register ───────────────────────────────────────────────────────────────
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result =
        await _api.register(name: name, email: email, password: password);
    if (result.success) return AuthResult.ok();
    return AuthResult.fail(result.error!);
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.login(email: email, password: password);
    if (result.success) {
      final data = result.data!;
      _token = data.token;
      _userId = data.userId;
      _name = data.name;
      _email = data.email;
      FeedService.instance.token = data.token;
      notifyListeners();
      return AuthResult.ok();
    }
    return AuthResult.fail(result.error!);
  }

  // ── Fetch fresh profile from backend ──────────────────────────────────────
  Future<void> fetchProfile() async {
    if (_token == null) return;
    final result = await _api.getProfile(_token!);
    if (result.success) {
      final data = result.data!;
      _name = data.name;
      _email = data.email;
      notifyListeners();
    }
  }

  // ── Update name ────────────────────────────────────────────────────────────
  Future<AuthResult> updateName(String newName) async {
    if (_token == null || newName.trim().isEmpty) {
      return AuthResult.fail('Not logged in.');
    }
    final result =
        await _api.updateProfile(token: _token!, name: newName.trim());
    if (result.success) {
      _name = result.data; // backend returns the saved name
      notifyListeners();
      return AuthResult.ok();
    }
    return AuthResult.fail(result.error!);
  }

  // ── Upload profile photo ───────────────────────────────────────────────────
  Future<AuthResult> uploadProfilePhoto(File photo) async {
    if (_token == null) return AuthResult.fail('Not logged in.');
    final result = await _api.uploadProfilePhoto(token: _token!, photo: photo);
    if (result.success) {
      // Read bytes locally so the avatar updates immediately without a round-trip
      _profilePhotoBytes = await photo.readAsBytes();
      notifyListeners();
      return AuthResult.ok();
    }
    return AuthResult.fail(result.error!);
  }

  // ── Forgot password ────────────────────────────────────────────────────────
  Future<AuthResult> sendPasswordReset(String email) async {
    final result = await _api.forgotPassword(email);
    if (result.success) return AuthResult.ok();
    return AuthResult.fail(result.error!);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _token = null;
    _userId = null;
    _name = null;
    _email = null;
    _profilePhotoBytes = null;
    FeedService.instance.token = null;
    notifyListeners();
  }
}
