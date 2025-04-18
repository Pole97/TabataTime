import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'timer_screen.dart';
import 'settings_screen.dart'; // Import the settings screen

class TabataHomeScreen extends StatefulWidget {
  const TabataHomeScreen({super.key});

  @override
  State<TabataHomeScreen> createState() => _TabataHomeScreenState();
}

class _TabataHomeScreenState extends State<TabataHomeScreen> {
  // Initialize controllers without default text
  final _prepController = TextEditingController();
  final _workController = TextEditingController();
  final _restController = TextEditingController();
  final _setsController = TextEditingController();
  final _roundsController = TextEditingController();
  final _restBetweenSetsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load saved settings on init
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Use saved values or fall back to original defaults if none are saved
    setState(() {
      _prepController.text = (prefs.getInt('prepTime') ?? 10).toString();
      _workController.text = (prefs.getInt('workTime') ?? 30).toString();
      _restController.text = (prefs.getInt('restTime') ?? 15).toString();
      _setsController.text = (prefs.getInt('sets') ?? 3).toString();
      _roundsController.text = (prefs.getInt('rounds') ?? 4).toString();
      _restBetweenSetsController.text =
          (prefs.getInt('restBetweenSets') ?? 15).toString();
    });
  }

  @override
  void dispose() {
    _prepController.dispose();
    _workController.dispose();
    _restController.dispose();
    _setsController.dispose();
    _roundsController.dispose();
    _restBetweenSetsController.dispose();
    super.dispose();
  }

  // Navigate to Settings Screen and reload settings when returning
  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    // Reload settings when returning from the settings screen
    _loadSettings();
  }

  // _startWorkout remains largely the same, it already uses controller values
  void _startWorkout() {
    final prepTime = int.tryParse(_prepController.text) ?? 10;
    final workTime = int.tryParse(_workController.text) ?? 30;
    final restTime = int.tryParse(_restController.text) ?? 15;
    final sets = int.tryParse(_setsController.text) ?? 3;
    final rounds = int.tryParse(_roundsController.text) ?? 4;
    final restBetweenSets = int.tryParse(_restBetweenSetsController.text) ?? 15;

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

  // _buildInputField remains the same
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: .7), // Use theme color
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabata Workout Setup'), // Changed title slightly
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Add actions for the settings button
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Modify Defaults',
            onPressed: _navigateToSettings, // Navigate to settings
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Input fields remain the same, using the modified _buildInputField
                      _buildInputField(
                        label: 'Preparation Time (sec)',
                        controller: _prepController,
                        icon: Icons.hourglass_empty_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Work Time (sec)',
                        controller: _workController,
                        icon: Icons.fitness_center_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Rest Time (sec)',
                        controller: _restController,
                        icon: Icons.pause_circle_outline_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Rounds per Set',
                        controller: _roundsController,
                        icon: Icons.repeat_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Number of Sets',
                        controller: _setsController,
                        icon: Icons.layers_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Rest Between Sets (sec)',
                        controller: _restBetweenSetsController,
                        icon: Icons.replay_10_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.timer_rounded, size: 24),
                label: const Text('Start Workout'),
                onPressed: _startWorkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
