import 'dart:io';
import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../models/app_config.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final config = ConfigService().getConfig();

    if (Platform.isWindows) {
      Navigator.pushReplacementNamed(context, '/receiver');
    } else if (Platform.isAndroid) {
      Navigator.pushReplacementNamed(context, '/mode-select');
    } else {
      Navigator.pushReplacementNamed(context, '/receiver');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 24),
            Text(
              'SignSniper',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              color: colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
