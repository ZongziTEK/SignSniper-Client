import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/config_service.dart';
import 'pages/splash_page.dart';
import 'pages/mode_select_page.dart';
import 'pages/sender_page.dart';
import 'pages/receiver_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);
  await ConfigService().init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    if (Platform.isWindows) {
      return baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          fontFamily: 'Microsoft Yahei UI',
        ),
      );
    }

    return baseTheme;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignSniper',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/mode-select': (context) => const ModeSelectPage(),
        '/sender': (context) => const SenderPage(),
        '/receiver': (context) => const ReceiverPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
