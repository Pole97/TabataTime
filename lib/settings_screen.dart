import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For numeric input formatters
import 'timer_screen.dart'; // Import the timer screen for navigation

// --- Settings Screen Widget ---
class TabataSettingsScreen extends StatefulWidget {
  const TabataSettingsScreen({super.key});

  @override
  State<TabataSettingsScreen> createState() => _TabataSettingsScreenState();
}

class _TabataSettingsScreenState extends State<TabataSettingsScreen> {
  // Text Editing Controllers for input fields
  final _prepController = TextEditingController(text: '10');
  final _workController = TextEditingController(text: '20');
  final _restController = TextEditingController(text: '10');
  final _setsController = TextEditingController(text: '3');
  final _roundsController = TextEditingController(text: '8');
  final _restBetweenSetsController = TextEditingController(text: '60');

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _prepController.dispose();
    _workController.dispose();
    _restController.dispose();
    _setsController.dispose();
    _roundsController.dispose();
    _restBetweenSetsController.dispose();
    super.dispose();
  }

  // Function to navigate to the timer screen with the selected settings
  void _startWorkout() {
    // Parse integer values from controllers, providing default values on error
    final prepTime = int.tryParse(_prepController.text) ?? 10;
    final workTime = int.tryParse(_workController.text) ?? 20;
    final restTime = int.tryParse(_restController.text) ?? 10;
    final sets = int.tryParse(_setsController.text) ?? 3;
    final rounds = int.tryParse(_roundsController.text) ?? 8;
    final restBetweenSets = int.tryParse(_restBetweenSetsController.text) ?? 60;

    // Ensure the context is still valid before navigating
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

  // Helper widget to build styled input fields with icons
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon, // Added icon parameter
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: Colors.deepPurple.shade300,
          ), // Use prefix icon
          // Using global theme for border, fill, padding
        ),
        keyboardType: TextInputType.number, // Show numeric keyboard
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly, // Allow only digits
        ],
        style: const TextStyle(fontSize: 16), // Input text style
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabata Settings'),
        // Use theme colors
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        // Add padding around the content
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch children horizontally
            children: [
              const SizedBox(height: 16), // Initial spacing
              // Use Card for better visual grouping (optional)
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
                        label: 'Preparation Time (sec)',
                        controller: _prepController,
                        icon: Icons.hourglass_empty_rounded, // Preparation icon
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Work Time (sec)',
                        controller: _workController,
                        icon: Icons.fitness_center_rounded, // Work icon
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Rest Time (sec)',
                        controller: _restController,
                        icon: Icons.pause_circle_outline_rounded, // Rest icon
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Rounds per Set',
                        controller: _roundsController,
                        icon: Icons.repeat_rounded, // Rounds icon
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Number of Sets',
                        controller: _setsController,
                        icon: Icons.layers_rounded, // Sets icon
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Rest Between Sets (sec)',
                        controller: _restBetweenSetsController,
                        icon: Icons.replay_10_rounded, // Rest between sets icon
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32), // More space before the button
              // Start Workout Button
              ElevatedButton.icon(
                icon: const Icon(Icons.timer_rounded, size: 24),
                label: const Text('Start Workout'),
                onPressed: _startWorkout,
                style: ElevatedButton.styleFrom(
                  // Use theme colors, slightly darker for emphasis
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ), // Taller button
                  // Using global theme for shape and text style
                ),
              ),
              const SizedBox(height: 20), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}
