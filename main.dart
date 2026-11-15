import 'package:flutter/material.dart';

import 'screens/conferencias_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StrataConferenciaApp());
}

class StrataConferenciaApp extends StatelessWidget {
  const StrataConferenciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strata Conferência',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003D7C),
          primary: const Color(0xFF003D7C),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003D7C),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF003D7C),
          foregroundColor: Colors.white,
        ),
      ),
      home: const ConferenciasListScreen(),
    );
  }
}