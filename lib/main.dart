import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'services/notification_center_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/main/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLISS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationCenterService _notificationCenter = NotificationCenterService();
  StreamSubscription<User?>? _authSubscription;

  bool _isAuthenticated = false;
  bool _showRegistration = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    final currentUser = _firebaseService.getCurrentUser();
    if (currentUser != null) {
      _isAuthenticated = true;
      _isInitializing = false;
      unawaited(_notificationCenter.start(currentUser.uid));
    } else {
      _isInitializing = false;
    }

    _authSubscription = _firebaseService.auth.authStateChanges().listen((user) {
      if (user != null) {
        unawaited(_notificationCenter.start(user.uid));
      } else {
        unawaited(_notificationCenter.stop());
      }

      if (!mounted) return;

      setState(() {
        _isAuthenticated = user != null;
        if (user == null) {
          _showRegistration = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    unawaited(_notificationCenter.stop());
    super.dispose();
  }

  void _handleRegistrationComplete(bool success) {
    if (success) {
      setState(() {
        _isAuthenticated = true;
        _showRegistration = false;
      });
    } else {
      setState(() {
        _showRegistration = false;
      });
    }
  }

  void _handleLoginComplete(bool success) {
    if (success) {
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'BLISS',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return MainScreen();
    }

    if (_showRegistration) {
      return RegistrationScreen(
        onRegistrationComplete: _handleRegistrationComplete,
      );
    }

    return LoginScreen(
      onLoginComplete: _handleLoginComplete,
      onSwitchToRegister: () {
        setState(() {
          _showRegistration = true;
        });
      },
    );
  }
}
