import 'dart:async';
import 'package:flutter/material.dart';
// For FontFeature

// Enum defining the possible states of the timer
enum TimerState {
  stopped,
  preparing,
  work,
  rest,
  restBetweenSets,
  paused,
  finished,
}

// --- Timer Screen Widget ---
class TabataTimerScreen extends StatefulWidget {
  // Input parameters for the timer configuration
  final int preparationTimeSeconds;
  final int workTimeSeconds;
  final int restTimeSeconds;
  final int restBetweenSetsTimeSeconds;
  final int totalRounds;
  final int totalSets;

  const TabataTimerScreen({
    super.key,
    required this.preparationTimeSeconds,
    required this.workTimeSeconds,
    required this.restTimeSeconds,
    required this.restBetweenSetsTimeSeconds,
    required this.totalRounds,
    required this.totalSets,
  });

  @override
  State<TabataTimerScreen> createState() => _TabataTimerScreenState();
}

class _TabataTimerScreenState extends State<TabataTimerScreen>
    with SingleTickerProviderStateMixin {
  // State variables
  TimerState _currentState = TimerState.stopped;
  int _currentRound = 0;
  int _currentSet = 0;
  int _currentTimeRemaining = 0;
  Timer? _timer; // The periodic timer object
  TimerState? _stateBeforePause; // To store state when pausing

  // Animation controller for FAB animation (optional but nice)
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize remaining time based on whether there's prep time
    _currentTimeRemaining =
        widget.preparationTimeSeconds > 0
            ? widget.preparationTimeSeconds
            : widget.workTimeSeconds;

    // Initialize animation controller
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );

    // Reset state properly if no prep time
    _resetTimer(initialize: true);
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer if active
    _fabAnimationController.dispose(); // Dispose animation controller
    super.dispose();
  }

  // --- Timer Logic ---

  void _startTimer() {
    if (!mounted) return;
    if (_currentState == TimerState.stopped ||
        _currentState == TimerState.paused) {
      _fabAnimationController.forward().then(
        (_) => _fabAnimationController.reverse(),
      ); // FAB press animation

      if (_currentState == TimerState.paused) {
        _resumeTimerLoop();
        return;
      }

      // Start with preparation if time > 0
      if (widget.preparationTimeSeconds > 0) {
        _currentState = TimerState.preparing;
        _currentTimeRemaining = widget.preparationTimeSeconds;
        _currentSet = 0;
        _currentRound = 0;
      } else {
        // Otherwise, skip preparation
        _currentSet = 1;
        _currentRound = 1;
        _currentState = TimerState.work;
        _currentTimeRemaining = widget.workTimeSeconds;
      }

      _startTimerLoop();
      if (mounted) setState(() {}); // Update UI
    }
  }

  void _pauseTimer() {
    if (!mounted) return;
    // Allow pausing in any active state
    if (_currentState != TimerState.stopped &&
        _currentState != TimerState.paused &&
        _currentState != TimerState.finished) {
      _fabAnimationController.forward().then(
        (_) => _fabAnimationController.reverse(),
      ); // FAB press animation
      _timer?.cancel();
      _stateBeforePause = _currentState; // Store state before pausing
      _currentState = TimerState.paused;
      if (mounted) setState(() {}); // Update UI
    }
  }

  void _resumeTimerLoop() {
    if (!mounted) return;
    if (_currentState == TimerState.paused && _stateBeforePause != null) {
      _currentState = _stateBeforePause!; // Restore state
      _stateBeforePause = null;
      _startTimerLoop(); // Restart the timer loop
      if (mounted) setState(() {}); // Update UI
    }
  }

  void _resetTimer({bool initialize = false}) {
    if (!mounted) return;
    _timer?.cancel();
    _currentState = TimerState.stopped;
    _currentRound = 0;
    _currentSet = 0;
    _stateBeforePause = null;
    // Set initial time based on prep time
    _currentTimeRemaining =
        widget.preparationTimeSeconds > 0
            ? widget.preparationTimeSeconds
            : widget.workTimeSeconds;
    // If no prep time, set counters for immediate start display
    if (widget.preparationTimeSeconds <= 0) {
      _currentSet = 1;
      _currentRound = 1;
    }
    // Avoid calling setState during initState
    if (!initialize) {
      if (mounted) setState(() {}); // Update UI
    }
  }

  void _startTimerLoop() {
    if (!mounted) return;
    // Do nothing if timer shouldn't be running
    if (_currentState == TimerState.finished ||
        _currentState == TimerState.stopped ||
        _currentState == TimerState.paused) {
      _timer?.cancel();
      return;
    }

    _timer?.cancel(); // Ensure only one timer runs

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Check state again in case it changed (e.g., paused immediately)
      if (_currentState == TimerState.paused ||
          _currentState == TimerState.stopped ||
          _currentState == TimerState.finished) {
        timer.cancel();
        return;
      }

      if (_currentTimeRemaining > 1) {
        if (mounted) {
          setState(() {
            _currentTimeRemaining--;
          });
        }
      } else {
        // Time's up for the current phase
        timer.cancel();
        // Use microtask to avoid setState errors during build
        Future.microtask(() {
          if (mounted) _moveToNextPhase();
        });
      }
    });
  }

  // Transitions to the next logical state in the Tabata sequence
  void _moveToNextPhase() {
    if (!mounted) return;

    TimerState nextState = _currentState;
    int nextTime = _currentTimeRemaining;
    bool shouldStartLoop = true; // Assume the next state needs a timer

    switch (_currentState) {
      case TimerState.preparing:
        _currentSet = 1;
        _currentRound = 1;
        nextState = TimerState.work;
        nextTime = widget.workTimeSeconds;
      case TimerState.work:
        if (_currentRound < widget.totalRounds) {
          // More rounds in this set
          nextState = TimerState.rest;
          nextTime = widget.restTimeSeconds;
        } else {
          // Last round of the set
          if (_currentSet < widget.totalSets) {
            // More sets remaining
            nextState = TimerState.restBetweenSets;
            nextTime = widget.restBetweenSetsTimeSeconds;
          } else {
            // Last round of last set
            nextState = TimerState.finished;
            nextTime = 0;
            shouldStartLoop = false; // Timer stops
          }
        }
      case TimerState.rest:
        _currentRound++;
        nextState = TimerState.work;
        nextTime = widget.workTimeSeconds;
      case TimerState.restBetweenSets:
        _currentSet++;
        _currentRound = 1; // Start next set from round 1
        nextState = TimerState.work;
        nextTime = widget.workTimeSeconds;
      // No automatic transition from these states
      case TimerState.stopped:
      case TimerState.paused:
      case TimerState.finished:
        shouldStartLoop = false;
        return;
    }

    // Update state and time
    _currentState = nextState;
    _currentTimeRemaining = nextTime;

    // Start the timer loop for the new state if needed
    if (shouldStartLoop) {
      _startTimerLoop();
    } else {
      _timer?.cancel();
    }

    if (mounted) setState(() {}); // Update UI
  }

  // --- Skip Functions ---

  void _skipNext() {
    if (!mounted) return;
    if (_currentState == TimerState.finished ||
        _currentState == TimerState.stopped) {
      return;
    }

    _timer?.cancel();
    _stateBeforePause = null; // Exit pause state if skipping
    _moveToNextPhase(); // Calculate and move to the next phase
  }

  void _skipPrevious() {
    if (!mounted) return;
    if (_currentState == TimerState.finished ||
        _currentState == TimerState.stopped) {
      return;
    }

    _timer?.cancel();

    // Determine the state to revert from (consider pause state)
    TimerState stateToConsider =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;
    _stateBeforePause = null; // Exit pause state

    TimerState prevState = stateToConsider;
    int prevTime = _currentTimeRemaining;
    bool needsLoop = true; // Assume the previous state needs a timer

    // Logic to determine the actual previous state and time
    switch (stateToConsider) {
      case TimerState.work:
        if (_currentRound == 1 && _currentSet == 1) {
          // From first work phase
          if (widget.preparationTimeSeconds > 0) {
            // Go back to prep if exists
            prevState = TimerState.preparing;
            prevTime = widget.preparationTimeSeconds;
            _currentRound = 0;
            _currentSet = 0;
          } else {
            // Otherwise, stop
            _resetTimer();
            return;
          }
        } else if (_currentRound == 1 && _currentSet > 1) {
          // From first work of set > 1
          prevState =
              TimerState.restBetweenSets; // Go back to rest between sets
          prevTime = widget.restBetweenSetsTimeSeconds;
          _currentSet--; // Decrement set
          _currentRound = widget.totalRounds; // Show last round of prev set
        } else {
          // From work (not first round)
          prevState = TimerState.rest; // Go back to rest of the same round
          prevTime = widget.restTimeSeconds;
          // Round and Set remain the same
        }
      case TimerState.rest: // From rest
        prevState = TimerState.work; // Go back to work of the same round
        prevTime = widget.workTimeSeconds;
      // Round and Set remain the same
      case TimerState.restBetweenSets: // From rest between sets
        prevState =
            TimerState.work; // Go back to work of the last round of prev set
        prevTime = widget.workTimeSeconds;
        // Set is already correct (decremented when moving forward)
        _currentRound = widget.totalRounds; // Set round to the last one
      case TimerState.preparing: // From preparation
        _resetTimer();
        return; // Go back to stopped state
      // These states should not trigger skip previous directly
      case TimerState.paused: // Handled by stateToConsider logic
      case TimerState.stopped:
      case TimerState.finished:
        needsLoop = false;
        return;
    }

    // Apply the determined previous state and time
    _currentState = prevState;
    _currentTimeRemaining = prevTime;

    // Start the timer loop if the previous state requires it
    if (needsLoop) {
      _startTimerLoop();
    } else {
      _timer?.cancel();
    }

    if (mounted) setState(() {}); // Update UI
  }

  // --- UI Helper Functions ---

  // Formats total seconds into MM:SS string
  String _formatTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0; // Safety check
    final duration = Duration(seconds: totalSeconds);
    // Use String manipulation for padding
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Determines background color based on the current state (or state before pause)
  Color _getBackgroundColor(BuildContext context) {
    // Determine the state to base the color on (handles pause)
    TimerState stateForColor =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;
    // Use theme colors for consistency
    final colorScheme = Theme.of(context).colorScheme;

    switch (stateForColor) {
      case TimerState.preparing:
        return Colors.blue.shade100;
      case TimerState.work:
        return Colors.green.shade200;
      case TimerState.rest:
        return Colors.lightBlue.shade200;
      case TimerState.restBetweenSets:
        return Colors.purple.shade100;
      case TimerState.paused:
        return Colors.grey.shade400; // Specific pause color
      case TimerState.finished:
        return Colors.amber.shade200;
      case TimerState.stopped:
      default:
        return colorScheme.surface; // Default background
    }
  }

  // Gets the primary text description for the current state
  String _getStateText() {
    // Determine the state to base the text on (handles pause)
    TimerState stateForText =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;

    switch (stateForText) {
      case TimerState.preparing:
        return 'PREPARATION';
      case TimerState.work:
        return 'WORK';
      case TimerState.rest:
        return 'REST';
      case TimerState.restBetweenSets:
        return 'SET REST';
      case TimerState.paused:
        return 'PAUSED'; // Specific pause text
      case TimerState.stopped:
        return 'READY?';
      case TimerState.finished:
        return 'FINISHED!';
      default:
        return '';
    }
  }

  // Generates the detailed status info string (including sets/rounds)
  String _getStatusInfoText() {
    if (_currentState == TimerState.stopped) {
      // Show Set/Round 1 if no prep, otherwise "Press Start"
      return widget.preparationTimeSeconds > 0
          ? 'Press Start'
          : 'Set 1/${widget.totalSets} - Round 1/${widget.totalRounds}';
    }
    if (_currentState == TimerState.finished) {
      return 'Workout Complete!';
    }

    String stateText = _getStateText(); // e.g., "WORK", "PAUSED"
    // Determine the underlying state for detail display (handles pause)
    TimerState displayState =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;

    // Add underlying state info if paused
    if (_currentState == TimerState.paused && _stateBeforePause != null) {
      String underlyingStateText = '';
      switch (_stateBeforePause) {
        case TimerState.preparing:
          underlyingStateText = 'PREP';
        case TimerState.work:
          underlyingStateText = 'WORK';
        case TimerState.rest:
          underlyingStateText = 'REST';
        case TimerState.restBetweenSets:
          underlyingStateText = 'SET REST';
        default:
          break;
      }
      if (underlyingStateText.isNotEmpty) {
        stateText = 'PAUSED ($underlyingStateText)';
      }
    }

    // Add Set/Round details based on the underlying state
    switch (displayState) {
      case TimerState.preparing:
        return stateText; // Just "PREPARATION" or "PAUSED (PREP)"
      case TimerState.restBetweenSets:
        // Show completed set and next set number
        return '$stateText - Next Set: ${_currentSet + 1}/${widget.totalSets}';
      case TimerState.work:
      case TimerState.rest:
        // Show current set and round
        return '$stateText - Set $_currentSet/${widget.totalSets} - Round $_currentRound/${widget.totalRounds}';
      default: // For paused (handled above), stopped, finished (handled at start)
        return stateText;
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    // Determine boolean states for UI logic
    final bool isStopped = _currentState == TimerState.stopped;
    final bool isPaused = _currentState == TimerState.paused;
    final bool isFinished = _currentState == TimerState.finished;
    // Can skip if timer is running or paused, but not stopped or finished
    final bool canSkip = !isStopped && !isFinished;

    // Determine background and text colors dynamically
    final Color bgColor = _getBackgroundColor(context);
    // Estimate brightness for text contrast
    final Brightness bgBrightness = ThemeData.estimateBrightnessForColor(
      bgColor,
    );
    // Choose text color based on background brightness
    final Color textColor =
        bgBrightness == Brightness.dark ? Colors.white : Colors.black87;
    // Choose icon color based on background brightness
    final Color iconColor =
        bgBrightness == Brightness.dark ? Colors.white70 : Colors.black54;
    // Color for disabled icons
    final Color disabledIconColor = Colors.grey.shade400.withValues(
      alpha: 0.5,
    ); // Use withOpacity here for disabled state

    // Determine the time to display when stopped
    int timeToShowWhenStopped =
        widget.preparationTimeSeconds > 0
            ? widget.preparationTimeSeconds
            : widget.workTimeSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Timer'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ), // Use iOS style back arrow
          tooltip: 'Back to Settings',
          onPressed: () {
            if (mounted) Navigator.pop(context);
          },
        ),
        elevation: 4, // Add shadow to AppBar
      ),
      // Use AnimatedContainer for smooth background color transitions
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400), // Animation duration
        curve: Curves.easeInOut, // Animation curve
        color: bgColor,
        // Use SafeArea to avoid system UI overlaps
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0), // Overall padding
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Space elements vertically
                children: <Widget>[
                  // Top Section: Status Info
                  Column(
                    children: [
                      const SizedBox(height: 20), // Top spacing
                      Text(
                        _getStatusInfoText(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24, // Slightly smaller status text
                          fontWeight: FontWeight.bold,
                          color: textColor.withValues(
                            alpha: 0.9,
                          ), // Slightly transparent
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Middle Section: Timer Display
                  FittedBox(
                    fit: BoxFit.contain, // Ensure timer fits
                    child: Text(
                      _formatTime(
                        isFinished
                            ? 0
                            : (_currentState != TimerState.stopped &&
                                _currentTimeRemaining > 0)
                            ? _currentTimeRemaining
                            : timeToShowWhenStopped,
                      ),
                      style: TextStyle(
                        fontSize: 110, // Larger timer font
                        fontWeight: FontWeight.w700, // Bold timer
                        color: textColor,
                        // Use tabular figures for consistent number spacing
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: [
                          // Subtle shadow for depth
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black.withValues(alpha: .1),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Section: Controls
                  if (!isFinished)
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceAround, // Space controls evenly
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // Skip Previous Button
                        _buildSkipButton(
                          icon: Icons.skip_previous_rounded,
                          tooltip: 'Skip Back',
                          onPressed: canSkip ? _skipPrevious : null,
                          // Use iconColor for enabled, disabledIconColor for disabled
                          color:
                              canSkip
                                  ? iconColor.withValues(alpha: .8)
                                  : disabledIconColor,
                        ),

                        // Central Play/Pause FAB
                        ScaleTransition(
                          // Add scale animation to FAB
                          scale: _fabScaleAnimation,
                          child: FloatingActionButton.large(
                            // Larger FAB
                            onPressed:
                                (isStopped || isPaused)
                                    ? _startTimer
                                    : _pauseTimer,
                            backgroundColor:
                                (isStopped || isPaused)
                                    ? Colors
                                        .green
                                        .shade600 // Start/Resume color
                                    : Colors.orange.shade700, // Pause color
                            foregroundColor: Colors.white,
                            elevation: 6,
                            tooltip:
                                (isStopped || isPaused) ? 'Start' : 'Pause',
                            child: Icon(
                              (isStopped || isPaused)
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              size: 45, // Larger icon in FAB
                            ),
                          ),
                        ),

                        // Skip Next Button
                        _buildSkipButton(
                          icon: Icons.skip_next_rounded,
                          tooltip: 'Skip Forward',
                          onPressed: canSkip ? _skipNext : null,
                          // Use iconColor for enabled, disabledIconColor for disabled
                          color:
                              canSkip
                                  ? iconColor.withValues(alpha: .8)
                                  : disabledIconColor,
                        ),
                      ],
                    )
                  else // Show "New Workout" button when finished
                    ElevatedButton.icon(
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('New Workout'),
                      onPressed: () {
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        // Use theme colors
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),

                  // Reset Button (placed separately below controls)
                  // Show only when running or paused
                  if (!isFinished && !isStopped)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 20.0,
                      ), // Space above reset
                      child: TextButton.icon(
                        icon: Icon(
                          Icons.stop_circle_outlined,
                          color: iconColor.withValues(alpha: .8),
                          size: 20,
                        ),
                        label: Text(
                          'Reset',
                          style: TextStyle(
                            color: iconColor.withValues(alpha: .8),
                            fontSize: 16,
                          ),
                        ),
                        onPressed: _resetTimer,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  else // Placeholder to maintain layout when reset is hidden
                    const SizedBox(height: 48), // Approx height of TextButton

                  const SizedBox(height: 10), // Bottom spacing
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for creating styled skip buttons
  Widget _buildSkipButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed, // Nullable for disabled state
    required Color color, // Pass the calculated color (handles disabled state)
  }) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 40, // Larger skip icons
      color: color, // Use the passed color directly
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(12), // Add padding for larger tap area
      splashRadius: 30, // Define splash radius
    );
  }
}
