import 'package:flutter/material.dart';
import 'settings_screen.dart'; // Import the settings screen

// Main function to run the app
void main() {
  runApp(
    MaterialApp(
      // Use MaterialApp directly
      title: 'Tabata Timer',
      theme: ThemeData(
        // Add a base theme
        primarySwatch: Colors.deepPurple,
        // Use Material 3 design features
        useMaterial3: true,
        // Define brightness and color scheme for Material 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Define styles for input fields globally
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.deepPurple.shade50.withValues(
            alpha: 0.5,
          ), // 0.5 opacity
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
        ),
        // Define styles for elevated buttons globally
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Text color
            backgroundColor: Colors.deepPurple.shade600, // Background color
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
      // Set the settings screen as the initial route
      home: const TabataSettingsScreen(),
      debugShowCheckedModeBanner: false, // Hide the debug banner
    ),
  );
}
