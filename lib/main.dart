import 'package:flutter/material.dart';
import 'settings_screen.dart'; // Importa la schermata delle impostazioni

// Funzione main per eseguire l'app
void main() {
  runApp(
    MaterialApp(
      // Usa MaterialApp direttamente
      title: 'Tabata Timer',
      theme: ThemeData(
        // Aggiungi un tema base
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Imposta la schermata delle impostazioni come schermata iniziale
      home: const TabataSettingsScreen(),
      debugShowCheckedModeBanner: false, // Nasconde il banner di debug
    ),
  );
}
