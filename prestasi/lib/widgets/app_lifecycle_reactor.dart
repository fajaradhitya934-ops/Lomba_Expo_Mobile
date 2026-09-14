import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prestasi/utility/SessionManager.dart';
import 'package:prestasi/services/auth_service.dart';
import 'package:prestasi/main.dart';
import 'package:prestasi/screens/login_screen.dart';

class AppLifecycleReactor extends StatefulWidget {
  final Widget child;
  const AppLifecycleReactor({super.key, required this.child});

  @override
  State<AppLifecycleReactor> createState() => _AppLifecycleReactorState();
}

class _AppLifecycleReactorState extends State<AppLifecycleReactor>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await SessionManager.saveLastActive();
    } else if (state == AppLifecycleState.resumed) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;

      if (isLoggedIn && await SessionManager.isSessionExpired()) {
        await _authService.signOutTotal();
        await SessionManager.clearLastActive();

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text(
                  "Sesi Anda berakhir karena tidak aktif lebih dari 3 jam."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}