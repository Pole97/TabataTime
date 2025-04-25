import 'package:flutter/material.dart';
import 'home_screen.dart';

// Ensure bindings are initialized before runApp
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line
  runApp(
    MaterialApp(
      title: 'Tabata Time',
      theme: ThemeData(
        // ... your theme data ...
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.deepPurple.shade50.withValues(
            alpha: 0.5,
          ), // Adjusted opacity
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const TabataHomeScreen(), // Starts with home screen
      debugShowCheckedModeBanner: false,
    ),
  );
}
