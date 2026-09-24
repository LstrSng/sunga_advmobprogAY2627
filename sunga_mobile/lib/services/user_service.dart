import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart' as app_user;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http
        .post(
          Uri.parse('$host/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
            'expiresInMins': 60,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  // Lab Activity 5 - Enhancement 2: DummyJSON sign up through /users/add (simulated only).
  /// Register a user on DummyJSON (simulated — DummyJSON does not persist it)
  Future<Map<String, dynamic>> addUser(Map<String, dynamic> userData) async {
    final response = await http
        .post(
          Uri.parse('$host/users/add'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(userData),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  /// Save user data from API response based on User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = app_user.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    // Support generic token key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  // Lab Activity 5 - Enhancement 3: Returns Firebase or DummyJSON user data depending on the loginType.
  /// Retrieve user data based on the saved loginType:
  /// Firebase reads the signed-in FirebaseAuth user (plus signup details saved
  /// locally), DummyJSON reads the login response saved in SharedPreferences.
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = prefs.getString('loginType') ?? 'dummyjson';

    if (loginType == 'firebase') {
      final user = currentUser;
      return {
        'loginType': 'firebase',
        'id': 0,
        'uid': user?.uid ?? '',
        'username': user?.displayName ?? prefs.getString('username') ?? '',
        'email': user?.email ?? prefs.getString('email') ?? '',
        'firstName': prefs.getString('firstName') ?? '',
        'lastName': prefs.getString('lastName') ?? '',
        'age': prefs.getString('age') ?? '',
        'contactNo': prefs.getString('contactNo') ?? '',
        'gender': '',
        'image': user?.photoURL ?? '',
        'accessToken': '',
        'refreshToken': '',
        'token': prefs.getString('token') ?? '',
      };
    }

    return {
      'loginType': 'dummyjson',
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  /// Retrieve User model from SharedPreferences
  Future<app_user.User> getUser() async {
    final userData = await getUserData();
    return app_user.User.fromJson(userData);
  }

  // Lab Activity 5 - Enhancement 2: Checks both the Firebase session and the DummyJSON token.
  /// Check if a user is currently logged in (Firebase session or DummyJSON token)
  Future<bool> isLoggedIn() async {
    // Wait for FirebaseAuth to restore any persisted session on app start.
    final firebaseUser = await firebaseAuth.authStateChanges().first;
    if (firebaseUser != null) return true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // Lab Activity 5 - Enhancement 1: Logout clears the saved session and token.
  /// Logout and clear stored user data
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // Lab Activity 5 - Enhancement 1: Firebase Auth methods for user management.
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Lab Activity 5 - Enhancement 2: Firebase token refresh.
  /// Get the Firebase ID token; forceRefresh fetches a fresh one from Firebase
  /// instead of using the cached token, and saves it like the DummyJSON token.
  Future<String?> getToken({bool forceRefresh = false}) async {
    final token = await currentUser?.getIdToken(forceRefresh);
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    }
    return token;
  }

  // Lab Activity 5 - Enhancement 1: Signs in with email and password using Firebase.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Lab Activity 5 - Enhancement 1: Creates a new Firebase account.
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Lab Activity 5 - Enhancement 1: Signs out the Firebase user.
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  // Lab Activity 5 - Enhancement 1: Updates the Firebase display name (username).
  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  // Lab Activity 5 - Enhancement 1: Re-checks the password, then deletes the Firebase account.
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  // Lab Activity 5 - Enhancement 1: Re-checks the current password, then sets a new one.
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
