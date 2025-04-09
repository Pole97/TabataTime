import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Per input numerici
import 'timer_screen.dart'; // Importa la schermata del timer per la navigazione

// --- Schermata Impostazioni ---
class TabataSettingsScreen extends StatefulWidget {
  const TabataSettingsScreen({super.key});

  @override
  State<TabataSettingsScreen> createState() => _TabataSettingsScreenState();
}

class _TabataSettingsScreenState extends State<TabataSettingsScreen> {
  // Controller per i TextField
  final _prepController = TextEditingController(
    text: '10',
  ); // Tempo di preparazione
  final _workController = TextEditingController(text: '20');
  final _restController = TextEditingController(text: '10');
  final _setsController = TextEditingController(text: '3');
  final _roundsController = TextEditingController(text: '8');
  final _restBetweenSetsController = TextEditingController(text: '60');

  @override
  void dispose() {
    // Pulisci i controller quando il widget viene rimosso
    _prepController.dispose();
    _workController.dispose();
    _restController.dispose();
    _setsController.dispose();
    _roundsController.dispose();
    _restBetweenSetsController.dispose();
    super.dispose();
  }

  void _startWorkout() {
    // Leggi i valori, con fallback in caso di errore di parsing
    final prepTime = int.tryParse(_prepController.text) ?? 10;
    final workTime = int.tryParse(_workController.text) ?? 20;
    final restTime = int.tryParse(_restController.text) ?? 10;
    final sets = int.tryParse(_setsController.text) ?? 3;
    final rounds = int.tryParse(_roundsController.text) ?? 8;
    final restBetweenSets = int.tryParse(_restBetweenSetsController.text) ?? 60;

    // Naviga alla schermata del timer usando Navigator.push
    // Assicurati che il context sia valido prima di navigare
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => TabataTimerScreen(
                preparationTimeSeconds: prepTime,
                workTimeSeconds: workTime,
                restTimeSeconds: restTime,
                totalSets: sets,
                totalRounds: rounds,
                restBetweenSetsTimeSeconds: restBetweenSets,
              ),
        ),
      );
    }
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // Rimosso padding orizzontale qui
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ), // Padding interno
        ),
        keyboardType: TextInputType.number, // Tastiera numerica
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly, // Accetta solo numeri
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni Tabata'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // Aggiunto padding generale qui invece che sui singoli TextField
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Padding uniforme
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Allarga i campi
            children: [
              const SizedBox(height: 20),
              _buildInputField('Tempo Preparazione (sec)', _prepController),
              const SizedBox(height: 10), // Spazio tra campi
              _buildInputField('Tempo Lavoro (sec)', _workController),
              const SizedBox(height: 10),
              _buildInputField('Tempo Riposo (sec)', _restController),
              const SizedBox(height: 10),
              _buildInputField('Numero Round per Set', _roundsController),
              const SizedBox(height: 10),
              _buildInputField('Numero Set', _setsController),
              const SizedBox(height: 10),
              _buildInputField(
                'Riposo tra Set (sec)',
                _restBetweenSetsController,
              ),
              const SizedBox(height: 40), // Più spazio prima del pulsante
              ElevatedButton.icon(
                icon: const Icon(Icons.timer, size: 24),
                label: const Text('Inizia Allenamento'),
                onPressed: _startWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600, // Tono di verde
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ), // Padding verticale
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
