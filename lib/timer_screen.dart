import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math'; // For max function

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
  int _currentTimeRemaining = 0; // Time remaining for the current phase
  Timer? _timer; // The periodic timer object
  TimerState? _stateBeforePause; // To store state when pausing

  // State variables for total progress
  int _totalWorkoutDuration = 0; // Total duration calculated once
  int _totalTimeRemaining = 0; // Total time left, decremented each second

  // Animation controller for FAB animation (optional but nice)
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Calculate total duration
    _totalWorkoutDuration = _calculateTotalWorkoutDuration();
    // Initialize total time remaining
    _totalTimeRemaining = _totalWorkoutDuration;
    // Initialize phase time remaining based on whether there's prep time
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

    // Reset state properly if no prep time (sets initial counters)
    _resetTimer(initialize: true);
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer if active
    _fabAnimationController.dispose(); // Dispose animation controller
    super.dispose();
  }

  // --- Timer Logic --- (Calculation and state management methods remain the same)

  // Calculates the total duration of the workout in seconds
  int _calculateTotalWorkoutDuration() {
    if (widget.totalSets <= 0 || widget.totalRounds <= 0) {
      return widget.preparationTimeSeconds; // Only prep time if no sets/rounds
    }
    int workPerSet = widget.totalRounds * widget.workTimeSeconds;
    int restPerSet = max(0, widget.totalRounds - 1) * widget.restTimeSeconds;
    int durationOfOneSet = workPerSet + restPerSet;
    int totalSetsDuration = widget.totalSets * durationOfOneSet;
    int totalRestBetweenSets =
        max(0, widget.totalSets - 1) * widget.restBetweenSetsTimeSeconds;
    return widget.preparationTimeSeconds +
        totalSetsDuration +
        totalRestBetweenSets;
  }

  void _startTimer() {
    if (!mounted) return;
    if (_currentState == TimerState.stopped ||
        _currentState == TimerState.paused) {
      _fabAnimationController.forward().then(
        (_) => _fabAnimationController.reverse(),
      );
      if (_currentState == TimerState.paused) {
        _resumeTimerLoop();
        return;
      }
      _totalTimeRemaining = _totalWorkoutDuration;
      if (widget.preparationTimeSeconds > 0) {
        _currentState = TimerState.preparing;
        _currentTimeRemaining = widget.preparationTimeSeconds;
        _currentSet = 0;
        _currentRound = 0;
      } else {
        _currentSet = 1;
        _currentRound = 1;
        _currentState = TimerState.work;
        _currentTimeRemaining = widget.workTimeSeconds;
      }
      _startTimerLoop();
      if (mounted) setState(() {});
    }
  }

  void _pauseTimer() {
    if (!mounted) return;
    if (_currentState != TimerState.stopped &&
        _currentState != TimerState.paused &&
        _currentState != TimerState.finished) {
      _fabAnimationController.forward().then(
        (_) => _fabAnimationController.reverse(),
      );
      _timer?.cancel();
      _stateBeforePause = _currentState;
      _currentState = TimerState.paused;
      if (mounted) setState(() {});
    }
  }

  void _resumeTimerLoop() {
    if (!mounted) return;
    if (_currentState == TimerState.paused && _stateBeforePause != null) {
      _currentState = _stateBeforePause!;
      _stateBeforePause = null;
      _startTimerLoop();
      if (mounted) setState(() {});
    }
  }

  void _resetTimer({bool initialize = false}) {
    if (!mounted) return;
    _timer?.cancel();
    _currentState = TimerState.stopped;
    _currentRound = 0;
    _currentSet = 0;
    _stateBeforePause = null;
    _totalTimeRemaining = _totalWorkoutDuration;
    _currentTimeRemaining =
        widget.preparationTimeSeconds > 0
            ? widget.preparationTimeSeconds
            : widget.workTimeSeconds;
    if (widget.preparationTimeSeconds <= 0) {
      _currentSet = 1;
      _currentRound = 1;
    }
    if (!initialize) {
      if (mounted) setState(() {});
    }
  }

  void _startTimerLoop() {
    if (!mounted) return;
    if (_currentState == TimerState.finished ||
        _currentState == TimerState.stopped ||
        _currentState == TimerState.paused) {
      _timer?.cancel();
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentState == TimerState.paused ||
          _currentState == TimerState.stopped ||
          _currentState == TimerState.finished) {
        timer.cancel();
        return;
      }
      bool totalTimeChanged = false;
      if (_totalTimeRemaining > 0) {
        _totalTimeRemaining--;
        totalTimeChanged = true;
      }
      if (_currentTimeRemaining > 1) {
        if (mounted) {
          setState(() {
            _currentTimeRemaining--;
          });
        }
      } else {
        timer.cancel();
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _currentTimeRemaining = 0;
              if (!totalTimeChanged && _totalTimeRemaining > 0) {
                _totalTimeRemaining--;
              }
            });
            _moveToNextPhase();
          }
        });
      }
    });
  }

  void _moveToNextPhase() {
    if (!mounted) return;
    TimerState nextState = _currentState;
    int nextTime = 0;
    bool shouldStartLoop = true;
    switch (_currentState) {
      case TimerState.preparing:
        _currentSet = 1;
        _currentRound = 1;
        nextState = TimerState.work;
        nextTime = widget.workTimeSeconds;
      case TimerState.work:
        if (_currentRound < widget.totalRounds) {
          nextState = TimerState.rest;
          nextTime = widget.restTimeSeconds;
        } else {
          if (_currentSet < widget.totalSets) {
            nextState = TimerState.restBetweenSets;
            nextTime = widget.restBetweenSetsTimeSeconds;
          } else {
            nextState = TimerState.finished;
            nextTime = 0;
            shouldStartLoop = false;
          }
        }
      case TimerState.rest:
        _currentRound++;
        nextState = TimerState.work;
        nextTime = widget.workTimeSeconds;
      case TimerState.restBetweenSets:
        _currentSet++;
        _currentRound = 1;
        nextState = TimerState.work;
        nextTime = widget.workTimeSeconds;
      case TimerState.stopped:
      case TimerState.paused:
      case TimerState.finished:
        shouldStartLoop = false;
        if (_currentState == TimerState.finished) _totalTimeRemaining = 0;
        if (_currentState == TimerState.stopped) {
          _totalTimeRemaining = _totalWorkoutDuration;
        }
        if (mounted) setState(() {});
        return;
    }
    _currentState = nextState;
    _currentTimeRemaining = nextTime;
    if (shouldStartLoop) {
      _startTimerLoop();
    } else {
      _timer?.cancel();
      if (_currentState == TimerState.finished) _totalTimeRemaining = 0;
    }
    if (mounted) setState(() {});
  }

  void _skipNext() {
    if (!mounted) return;
    if (_currentState == TimerState.finished ||
        _currentState == TimerState.stopped) {
      return;
    }
    int timeSkipped = _currentTimeRemaining;
    _totalTimeRemaining = max(0, _totalTimeRemaining - timeSkipped);
    _timer?.cancel();
    _stateBeforePause = null;
    _moveToNextPhase();
  }

  void _skipPrevious() {
    if (!mounted) return;
    if (_currentState == TimerState.finished ||
        _currentState == TimerState.stopped) {
      return;
    }
    int initialPhaseDuration = 0;
    TimerState stateToConsider =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;
    switch (stateToConsider) {
      case TimerState.preparing:
        initialPhaseDuration = widget.preparationTimeSeconds;
      case TimerState.work:
        initialPhaseDuration = widget.workTimeSeconds;
      case TimerState.rest:
        initialPhaseDuration = widget.restTimeSeconds;
      case TimerState.restBetweenSets:
        initialPhaseDuration = widget.restBetweenSetsTimeSeconds;
      default:
        break;
    }
    int timeElapsed = max(0, initialPhaseDuration - _currentTimeRemaining);
    _timer?.cancel();
    _stateBeforePause = null;
    TimerState prevState = stateToConsider;
    int prevTime = 0;
    bool needsLoop = true;
    switch (stateToConsider) {
      case TimerState.work:
        if (_currentRound == 1 && _currentSet == 1) {
          if (widget.preparationTimeSeconds > 0) {
            prevState = TimerState.preparing;
            prevTime = widget.preparationTimeSeconds;
            _currentRound = 0;
            _currentSet = 0;
          } else {
            _resetTimer();
            return;
          }
        } else if (_currentRound == 1 && _currentSet > 1) {
          prevState = TimerState.restBetweenSets;
          prevTime = widget.restBetweenSetsTimeSeconds;
          _currentSet--;
          _currentRound = widget.totalRounds;
        } else {
          prevState = TimerState.rest;
          prevTime = widget.restTimeSeconds;
        }
      case TimerState.rest:
        prevState = TimerState.work;
        prevTime = widget.workTimeSeconds;
      case TimerState.restBetweenSets:
        prevState = TimerState.work;
        prevTime = widget.workTimeSeconds;
        _currentRound = widget.totalRounds;
      case TimerState.preparing:
        _resetTimer();
        return;
      case TimerState.paused:
      case TimerState.stopped:
      case TimerState.finished:
        needsLoop = false;
        return;
    }
    _currentState = prevState;
    _currentTimeRemaining = prevTime;
    _totalTimeRemaining = min(
      _totalWorkoutDuration,
      _totalTimeRemaining + timeElapsed + prevTime,
    );
    if (needsLoop) {
      _startTimerLoop();
    } else {
      _timer?.cancel();
    }
    if (mounted) setState(() {});
  }

  // --- UI Helper Functions ---

  // Formats total seconds into MM:SS string
  String _formatTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final duration = Duration(seconds: totalSeconds);
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Determines background color based on the current state (using more saturated colors)
  Color _getBackgroundColor(BuildContext context) {
    TimerState stateForColor =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;
    // Using more saturated colors
    switch (stateForColor) {
      case TimerState.preparing:
        return Colors.teal.shade300; // More saturated teal/blue
      case TimerState.work:
        return Colors.orange.shade400; // Vibrant orange/yellow
      case TimerState.rest:
        return Colors.blue.shade500; // Stronger blue
      case TimerState.restBetweenSets:
        return Colors.deepPurple.shade400; // Richer purple
      case TimerState.paused:
        return Colors.grey.shade500; // Slightly darker grey
      case TimerState.finished:
        return Colors.green.shade500; // Stronger green
      case TimerState.stopped:
      default:
        return Colors.grey.shade100; // Light grey for stopped
    }
  }

  // Gets the primary text description for the current state
  String _getStateText() {
    TimerState stateForText =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;
    switch (stateForText) {
      case TimerState.preparing:
        return 'PREPARAZIONE';
      case TimerState.work:
        return 'LAVORO';
      case TimerState.rest:
        return 'RIPOSO';
      case TimerState.restBetweenSets:
        return 'RIPOSO TRA SET';
      case TimerState.paused:
        return 'PAUSA';
      case TimerState.stopped:
        return 'PRONTO?';
      case TimerState.finished:
        return 'FINITO!';
      default:
        return '';
    }
  }

  // Generates the detailed status info string (including sets/rounds)
  String _getStatusInfoText() {
    if (_currentState == TimerState.stopped) {
      return widget.preparationTimeSeconds > 0
          ? 'Premi Start'
          : 'Set 1/${widget.totalSets} - Round 1/${widget.totalRounds}';
    }
    if (_currentState == TimerState.finished) {
      return 'Allenamento Completato!';
    }
    String stateText = _getStateText();
    TimerState displayState =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;
    if (_currentState == TimerState.paused && _stateBeforePause != null) {
      String underlyingStateText = '';
      switch (_stateBeforePause) {
        case TimerState.preparing:
          underlyingStateText = 'PREP';
        case TimerState.work:
          underlyingStateText = 'LAVORO';
        case TimerState.rest:
          underlyingStateText = 'RIPOSO';
        case TimerState.restBetweenSets:
          underlyingStateText = 'SET REST';
        default:
          break;
      }
      if (underlyingStateText.isNotEmpty) {
        stateText = 'PAUSA ($underlyingStateText)';
      }
    }
    switch (displayState) {
      case TimerState.preparing:
        return stateText;
      case TimerState.restBetweenSets:
        return '$stateText - Prossimo Set: ${_currentSet + 1}/${widget.totalSets}';
      case TimerState.work:
      case TimerState.rest:
        return '$stateText - Set $_currentSet/${widget.totalSets} - Round $_currentRound/${widget.totalRounds}';
      default:
        return stateText;
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final bool isStopped = _currentState == TimerState.stopped;
    final bool isPaused = _currentState == TimerState.paused;
    final bool isFinished = _currentState == TimerState.finished;
    final bool canSkip = !isStopped && !isFinished;

    final Color bgColor = _getBackgroundColor(context);
    final Brightness bgBrightness = ThemeData.estimateBrightnessForColor(
      bgColor,
    );
    final Color textColor =
        bgBrightness == Brightness.dark ? Colors.white : Colors.black87;
    final Color iconColor =
        bgBrightness == Brightness.dark ? Colors.white70 : Colors.black54;
    final Color disabledIconColor = Colors.grey.shade400.withValues(alpha: 0.5);

    // Calculate progress for the LinearProgressIndicator
    final double totalProgress =
        (_totalWorkoutDuration > 0)
            ? _totalTimeRemaining / _totalWorkoutDuration
            : 0.0;

    int timeToShowWhenStopped =
        widget.preparationTimeSeconds > 0
            ? widget.preparationTimeSeconds
            : widget.workTimeSeconds;

    // Style for the total time text
    final totalTimeStyle = TextStyle(
      fontSize: 22,
      color: textColor.withValues(alpha: 0.8),
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      appBar: AppBar(
        // Reset title to simple text
        title: const Text('Timer Allenamento'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back to Home',
          onPressed: () {
            if (mounted) Navigator.pop(context);
          },
        ),
        elevation: 2, // Reduced elevation slightly
        // Remove the bottom property
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        color: bgColor,
        child: SafeArea(
          child: Center(
            child: Column(
              // MainAxisAlignment changed to start to place new elements at top
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                // --- NEW: Total Progress Bar and Time ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 0.0,
                  ), // Add padding around this section
                  child: Column(
                    children: [
                      // Thicker Progress Bar
                      LinearProgressIndicator(
                        value: totalProgress,
                        backgroundColor: Colors.black.withValues(
                          alpha: 0.1,
                        ), // Darker background for contrast
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.secondary,
                        ),
                        minHeight: 20.0, // Keep it thick
                      ),

                      const SizedBox(height: 8), // Space between bar and text
                      // Total Time Remaining Text (conditionally visible)
                      if (!isStopped && !isFinished)
                        Text(
                          'Totale: ${_formatTime(_totalTimeRemaining)}',
                          style: totalTimeStyle,
                        )
                      else // Placeholder to maintain space when stopped/finished
                        SizedBox(
                          height:
                              DefaultTextStyle.of(context).style.fontSize! *
                              (totalTimeStyle.height ?? 1.3),
                        ),
                    ],
                  ),
                ),
                // --- END NEW SECTION ---

                // Spacer to push timer and controls down if needed, or use Expanded
                const Spacer(flex: 1),

                // Status Info Text
                Text(
                  _getStatusInfoText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Middle Section: Timer Display
                FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    _formatTime(
                      isFinished
                          ? 0
                          : (_currentState != TimerState.stopped &&
                              _currentTimeRemaining >= 0)
                          ? _currentTimeRemaining
                          : timeToShowWhenStopped,
                    ),
                    style: TextStyle(
                      fontSize: 110,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Spacer to push controls down
                const Spacer(flex: 2),

                // Bottom Section: Controls
                if (!isFinished)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _buildSkipButton(
                        icon: Icons.skip_previous_rounded,
                        tooltip: 'Salta Indietro',
                        onPressed: canSkip ? _skipPrevious : null,
                        color:
                            canSkip
                                ? iconColor.withValues(alpha: 0.8)
                                : disabledIconColor,
                      ),
                      ScaleTransition(
                        scale: _fabScaleAnimation,
                        child: FloatingActionButton.large(
                          onPressed:
                              (isStopped || isPaused)
                                  ? _startTimer
                                  : _pauseTimer,
                          backgroundColor:
                              (isStopped || isPaused)
                                  ? Colors.green.shade600
                                  : Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          tooltip: (isStopped || isPaused) ? 'Start' : 'Pause',
                          child: Icon(
                            (isStopped || isPaused)
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            size: 45,
                          ),
                        ),
                      ),
                      _buildSkipButton(
                        icon: Icons.skip_next_rounded,
                        tooltip: 'Salta Avanti',
                        onPressed: canSkip ? _skipNext : null,
                        color:
                            canSkip
                                ? iconColor.withValues(alpha: 0.8)
                                : disabledIconColor,
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('Nuovo Allenamento'),
                    onPressed: () {
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),

                // Reset Button
                if (!isFinished && !isStopped)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TextButton.icon(
                      icon: Icon(
                        Icons.stop_circle_outlined,
                        color: iconColor.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      label: Text(
                        'Reset',
                        style: TextStyle(
                          color: iconColor.withValues(alpha: 0.8),
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
                else
                  const SizedBox(height: 48), // Placeholder

                const SizedBox(height: 10),
              ],
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
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 40,
      color: color,
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(12),
      splashRadius: 30,
    );
  }
}
