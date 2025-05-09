import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prepController = TextEditingController();
  final _workController = TextEditingController();
  final _restController = TextEditingController();
  final _setsController = TextEditingController();
  final _roundsController = TextEditingController();
  final _restBetweenSetsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load existing settings when the screen opens
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
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

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prepTime', int.tryParse(_prepController.text) ?? 10);
    await prefs.setInt('workTime', int.tryParse(_workController.text) ?? 30);
    await prefs.setInt('restTime', int.tryParse(_restController.text) ?? 15);
    await prefs.setInt('sets', int.tryParse(_setsController.text) ?? 3);
    await prefs.setInt('rounds', int.tryParse(_roundsController.text) ?? 4);
    await prefs.setInt(
      'restBetweenSets',
      int.tryParse(_restBetweenSetsController.text) ?? 15,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings Saved!')));
      Navigator.pop(context); // Go back after saving
    }
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

  // Helper widget (same as in home_screen.dart)
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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .7),
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
        title: const Text('Modify Defaults'),
        leading: IconButton(
          // Add a back button explicitly
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
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
                      _buildInputField(
                        label: 'Default Preparation Time (sec)',
                        controller: _prepController,
                        icon: Icons.hourglass_empty_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Default Work Time (sec)',
                        controller: _workController,
                        icon: Icons.fitness_center_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Default Rest Time (sec)',
                        controller: _restController,
                        icon: Icons.pause_circle_outline_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Default Rounds per Set',
                        controller: _roundsController,
                        icon: Icons.repeat_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Default Number of Sets',
                        controller: _setsController,
                        icon: Icons.layers_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Default Rest Between Sets (sec)',
                        controller: _restBetweenSetsController,
                        icon: Icons.replay_10_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Defaults'),
                onPressed: _saveSettings, // Call save function
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
