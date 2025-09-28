import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    getIsLogin();
    super.initState();
  }

  Future<void> getIsLogin() async {
    final userService = UserService();
    
    // Check both Firebase authentication and local storage
    final userData = await userService.getUserData();
    final isFirebaseLoggedIn = userService.isFirebaseLoggedIn;
    final hasLocalToken = userData['token'] != null && userData['token'] != '';
    
    if (isFirebaseLoggedIn || hasLocalToken) {
      // User is logged in (either via Firebase or local storage)
      Timer(
        const Duration(seconds: 4),
        () => Navigator.popAndPushNamed(context, '/home'),
      );
    } else {
      // User is not logged in
      Timer(
        const Duration(seconds: 4),
        () => Navigator.popAndPushNamed(context, '/login'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        height: ScreenUtil().screenHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhancement
            Image.asset(
              'assets/images/StreetFeedLogo.png',
            ),
            SizedBox(
              height: ScreenUtil().setHeight(120),
            ),
            // Enhancement
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}