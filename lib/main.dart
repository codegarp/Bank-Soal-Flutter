import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/preference_helper.dart';
import 'providers/settings_provider.dart';
import 'providers/generator_provider.dart';
import 'providers/history_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Initialize SQLite FFI for Web & Desktop testing
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final prefHelper = PreferenceHelper();
  final settings = await prefHelper.loadSettings();
  final hasApiKey = settings.isConfigured;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GeneratorProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: GuruSoalApp(hasApiKey: hasApiKey),
    ),
  );
}

class GuruSoalApp extends StatelessWidget {
  final bool hasApiKey;
  const GuruSoalApp({super.key, required this.hasApiKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuruSoal AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: hasApiKey ? const HomeScreen() : const SetupScreen(isInitialSetup: true),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/setup': (context) => const SetupScreen(isInitialSetup: false),
      },
    );
  }
}
