import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    Response response = await post(
      Uri.parse('$host/api/users/login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> userData,
  ) async {
    Response response = await post(
      Uri.parse('$host/api/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      data = jsonDecode(response.body);
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Registration failed');
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', userData['firstName'] ?? '');
    await prefs.setString('lastName', userData['lastName'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('token', userData['token'] ?? '');
    await prefs.setString('type', userData['type'] ?? '');
    await prefs.setString('username', userData['username'] ?? '');
  }

  // Save Firebase user data to local storage
  Future<void> saveFirebaseUserData(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', user.displayName?.split(' ').first ?? '');
    await prefs.setString('lastName', user.displayName?.split(' ').skip(1).join(' ') ?? '');
    await prefs.setString('email', user.email ?? '');
    await prefs.setString('token', user.uid); // Use Firebase UID as token
    await prefs.setString('type', 'firebase_user');
    await prefs.setString('username', user.displayName ?? ''); // Store username as displayName
    
    // Also store user data in Firestore for chat functionality
    await _storeFirebaseUserInFirestore(user);
  }

  Future<void> _storeFirebaseUserInFirestore(User user) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userData = {
        'uid': user.uid,
        'firstName': user.displayName?.split(' ').first ?? '',
        'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
        'email': user.email ?? '',
        'username': user.displayName ?? '',
        'type': 'firebase_user',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await firestore.collection('Users').doc(user.uid).set(userData);
    } catch (e) {
      print('Error storing Firebase user in Firestore: $e');
    }
  }

  Future<void> storeCompleteFirebaseUserData(
    User user, {
    required String firstName,
    required String lastName,
    required String username,
    required String age,
    required String gender,
    required String contactNumber,
    required String address,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userData = {
        'uid': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': user.email ?? '',
        'username': username,
        'age': age,
        'gender': gender,
        'contactNumber': contactNumber,
        'address': address,
        'type': 'firebase_user',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await firestore.collection('Users').doc(user.uid).set(userData);
    } catch (e) {
      print('Error storing complete Firebase user data in Firestore: $e');
    }
  }

  // Method to ensure Firebase user exists in Firestore (for existing users)
  Future<void> ensureFirebaseUserInFirestore() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('Users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // User doesn't exist in Firestore, create a basic entry
        final userData = {
          'uid': user.uid,
          'firstName': user.displayName?.split(' ').first ?? 'User',
          'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
          'email': user.email ?? '',
          'username': user.displayName ?? user.email ?? 'Unknown',
          'type': 'firebase_user',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await firestore.collection('Users').doc(user.uid).set(userData);
        print('Created Firestore entry for existing Firebase user: ${user.email}');
      }
    } catch (e) {
      print('Error ensuring Firebase user in Firestore: $e');
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'email': prefs.getString('email') ?? '',
      'token': prefs.getString('token') ?? '',
      'type': prefs.getString('type') ?? '',
      'username': prefs.getString('username') ?? '',
    };
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  // Check if user is logged in via Firebase
  bool get isFirebaseLoggedIn => currentUser != null;

  // Determine login type based on stored data
  String getLoginType() {
    if (isFirebaseLoggedIn) {
      return 'firebase';
    }
    return 'mongodb';
  }

  // Update MongoDB user data (placeholder for future backend integration)
  Future<void> updateMongoDBUserData(Map<String, dynamic> userData) async {
    // This would typically make an API call to your backend
    // For now, we'll just update local storage
    await saveUserData(userData);
  }

  Future<bool> logout() async {
    try {
      // Clear Firebase authentication
      await firebaseAuth.signOut();
      
      // Clear local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      return true;
    } catch (e) {
      // If Firebase logout fails, still clear local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return false;
    }
  }

  // FIREBASE
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('Users')
          .doc(currentUser!.uid)
          .update({'username': username});
    } catch (e) {
      print('Error updating username in Firestore: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
    } catch (e) {
      print('Error updating username in local storage: $e');
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    final String uid = currentUser!.uid;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('Users').doc(uid).delete();
    } catch (e) {
      print('Error deleting Firestore user document: $e');
    }
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

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

  // MONGODB PASSWORD CHANGE
  Future<void> changeMongoDBPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    Response response = await post(
      Uri.parse('$host/api/users/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      // Password changed successfully
      return;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Password change failed');
    }
  }

  // MONGODB ACCOUNT DELETION
  Future<void> deleteMongoDBAccount({
    required String email,
    required String password,
  }) async {
    Response response = await post(
      Uri.parse('$host/api/users/delete-account'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      // Account deleted successfully
      return;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Account deletion failed');
    }
  }

  // MONGODB USERNAME UPDATE
  Future<Map<String, dynamic>> updateMongoDBUsername({
    required String email,
    required String password,
    required String username,
  }) async {
    Response response = await post(
      Uri.parse('$host/api/users/update-username'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Username update failed');
    }
  }
}
