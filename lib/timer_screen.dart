import 'dart:async';
import 'package:flutter/material.dart';

// Definizione degli stati del timer
enum TimerState {
  stopped,
  preparing,
  work,
  rest,
  restBetweenSets,
  paused,
  finished,
}

// --- Schermata Timer ---
class TabataTimerScreen extends StatefulWidget {
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

class _TabataTimerScreenState extends State<TabataTimerScreen> {
  TimerState _currentState = TimerState.stopped;
  int _currentRound = 0;
  int _currentSet = 0;
  int _currentTimeRemaining = 0;
  Timer? _timer;
  TimerState? _stateBeforePause;

  @override
  void initState() {
    super.initState();
    // Inizializza il tempo rimanente con il tempo di lavoro per la visualizzazione iniziale
    _currentTimeRemaining = widget.workTimeSeconds;
    // Se il tempo di preparazione è 0, imposta subito i contatori per l'inizio diretto
    if (widget.preparationTimeSeconds <= 0) {
      _currentSet = 1;
      _currentRound = 1;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Logica del Timer ---

  void _startTimer() {
    if (!mounted) return;
    if (_currentState == TimerState.stopped ||
        _currentState == TimerState.paused) {
      if (_currentState == TimerState.paused) {
        _resumeTimerLoop();
        return;
      }

      // Inizia dalla fase di preparazione se il tempo è > 0
      if (widget.preparationTimeSeconds > 0) {
        _currentState = TimerState.preparing;
        _currentTimeRemaining = widget.preparationTimeSeconds;
        _currentSet = 0; // Durante la preparazione, set e round sono 0
        _currentRound = 0;
      } else {
        // Altrimenti salta la preparazione e inizia dal primo set/round
        _currentSet = 1;
        _currentRound = 1;
        _currentState = TimerState.work;
        _currentTimeRemaining = widget.workTimeSeconds;
      }

      _startTimerLoop();
      setState(() {}); // Aggiorna UI
    }
  }

  void _pauseTimer() {
    if (!mounted) return;
    // Permette la pausa in tutti gli stati attivi tranne stopped e finished
    if (_currentState != TimerState.stopped &&
        _currentState != TimerState.paused &&
        _currentState != TimerState.finished) {
      _timer?.cancel();
      _stateBeforePause = _currentState;
      _currentState = TimerState.paused;
      setState(() {}); // Aggiorna UI
    }
  }

  void _resumeTimerLoop() {
    if (!mounted) return;
    if (_currentState == TimerState.paused && _stateBeforePause != null) {
      _currentState = _stateBeforePause!;
      _stateBeforePause = null;
      _startTimerLoop(); // Riavvia il ciclo
      setState(() {}); // Aggiorna UI
    }
  }

  void _resetTimer() {
    if (!mounted) return;
    _timer?.cancel();
    _currentState = TimerState.stopped;
    _currentRound = 0;
    _currentSet = 0;
    _stateBeforePause = null;
    _currentTimeRemaining = widget.workTimeSeconds; // Mostra tempo lavoro
    // Se il tempo di preparazione è 0, reimposta i contatori per l'inizio diretto
    if (widget.preparationTimeSeconds <= 0) {
      _currentSet = 1;
      _currentRound = 1;
    }
    setState(() {}); // Aggiorna UI
  }

  void _startTimerLoop() {
    if (!mounted) return;
    // Se lo stato attuale non richiede un timer, non fare nulla
    if (_currentState == TimerState.finished ||
        _currentState == TimerState.stopped ||
        _currentState == TimerState.paused) {
      _timer?.cancel();
      return;
    }

    _timer?.cancel(); // Cancella timer precedenti

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Controlla di nuovo lo stato (potrebbe essere cambiato)
      if (_currentState == TimerState.paused ||
          _currentState == TimerState.stopped ||
          _currentState == TimerState.finished) {
        timer.cancel();
        return;
      }

      if (_currentTimeRemaining > 1) {
        // Aggiorna solo se montato
        if (mounted) {
          setState(() {
            _currentTimeRemaining--;
          });
        }
      } else {
        // Tempo scaduto
        timer.cancel();
        // Usa microtask per sicurezza
        Future.microtask(() {
          if (mounted) _moveToNextPhase();
        });
      }
    });
  }

  void _moveToNextPhase() {
    if (!mounted) return;

    TimerState nextState = _currentState;
    int nextTime = _currentTimeRemaining;
    bool shouldStartLoop = true; // Di default, avvia il loop per il nuovo stato

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
            shouldStartLoop = false; // Non avviare loop se finito
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
      // Stati da cui non si passa automaticamente alla fase successiva
      case TimerState.stopped:
      case TimerState.paused:
      case TimerState.finished:
        shouldStartLoop = false;
        return; // Esce
    }

    _currentState = nextState;
    _currentTimeRemaining = nextTime;

    if (shouldStartLoop) {
      _startTimerLoop();
    } else {
      _timer?.cancel();
    }

    setState(() {}); // Aggiorna UI
  }

  // --- Funzioni Skip ---

  void _skipNext() {
    if (!mounted) return;
    if (_currentState == TimerState.finished ||
        _currentState == TimerState.stopped) {
      return;
    }

    _timer?.cancel();
    _stateBeforePause = null; // Esci dalla pausa se necessario
    _moveToNextPhase(); // Calcola e imposta la fase successiva
  }

  void _skipPrevious() {
    if (!mounted) return;
    if (_currentState == TimerState.finished ||
        _currentState == TimerState.stopped) {
      return;
    }

    _timer?.cancel();

    // Se siamo in pausa, basiamo la logica sullo stato precedente alla pausa
    TimerState stateToConsider =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;
    _stateBeforePause = null; // Usciamo comunque dalla pausa

    TimerState prevState = stateToConsider;
    int prevTime = _currentTimeRemaining;
    bool needsLoop = true; // Di default, il nuovo stato richiede un timer

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
            return; // Torna a stopped
          }
        } else if (_currentRound == 1 && _currentSet > 1) {
          prevState = TimerState.restBetweenSets;
          prevTime = widget.restBetweenSetsTimeSeconds;
          _currentSet--;
          _currentRound =
              widget.totalRounds; // Mostra l'ultimo round del set precedente
        } else {
          prevState = TimerState.rest;
          prevTime = widget.restTimeSeconds;
          // Round e Set non cambiano quando si torna a Rest dallo stesso Work
        }
      case TimerState.rest:
        prevState = TimerState.work;
        prevTime = widget.workTimeSeconds;
      // Round e Set non cambiano quando si torna a Work dallo stesso Rest
      case TimerState.restBetweenSets:
        prevState = TimerState.work;
        prevTime = widget.workTimeSeconds;
        // Set è già corretto (quello precedente)
        _currentRound =
            widget.totalRounds; // Vai all'ultimo round del set precedente
      case TimerState.preparing:
        _resetTimer();
        return; // Torna a stopped
      // Casi non raggiungibili se la logica iniziale è corretta
      case TimerState.paused: // Già gestito sopra con stateToConsider
      case TimerState.stopped:
      case TimerState.finished:
        needsLoop = false; // Non fare nulla e non avviare loop
        return;
    }

    _currentState = prevState;
    _currentTimeRemaining = prevTime;

    if (needsLoop) {
      _startTimerLoop();
      // ignore: dead_code
    } else {
      _timer?.cancel();
    }

    setState(() {}); // Aggiorna UI
  }

  // --- Funzioni UI Helper ---

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _getBackgroundColor() {
    TimerState stateForColor =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;

    switch (stateForColor) {
      case TimerState.preparing:
        return Colors.lightBlue.shade200;
      case TimerState.work:
        return Colors.green.shade400;
      case TimerState.rest:
        return Colors.blue.shade400;
      case TimerState.restBetweenSets:
        return Colors.purple.shade400;
      case TimerState.paused:
        return Colors.grey.shade500; // Colore specifico per pausa
      case TimerState.finished:
        return Colors.amber.shade400;
      case TimerState.stopped:
        return Colors.grey.shade200;
    }
  }

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
        return 'PAUSA'; // Testo specifico per pausa
      case TimerState.stopped:
        return 'PRONTO?';
      case TimerState.finished:
        return 'FINITO!';
    }
  }

  String _getStatusInfoText() {
    if (_currentState == TimerState.stopped) {
      // Mostra Set/Round 1 se non c'è preparazione, altrimenti "Premi Start"
      return widget.preparationTimeSeconds > 0
          ? 'Premi Start'
          : 'Set 1/${widget.totalSets} - Round 1/${widget.totalRounds}';
    }
    if (_currentState == TimerState.finished) {
      return 'Allenamento Completato!';
    }

    String stateText = _getStateText(); // Es. "LAVORO", "PAUSA"
    TimerState displayState =
        _currentState == TimerState.paused
            ? (_stateBeforePause ?? _currentState)
            : _currentState;

    // Se in pausa, aggiungi indicazione dello stato sottostante
    if (_currentState == TimerState.paused && _stateBeforePause != null) {
      String underlyingStateText = '';
      switch (_stateBeforePause) {
        case TimerState.preparing:
          underlyingStateText = 'PREPARAZIONE';
        case TimerState.work:
          underlyingStateText = 'LAVORO';
        case TimerState.rest:
          underlyingStateText = 'RIPOSO';
        case TimerState.restBetweenSets:
          underlyingStateText = 'RIPOSO TRA SET';
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
        // Mostra il set corrente completato e quello successivo
        return '$stateText - Prossimo Set: ${_currentSet + 1}/${widget.totalSets}';
      case TimerState.work:
      case TimerState.rest:
        return '$stateText - Set $_currentSet/${widget.totalSets} - Round $_currentRound/${widget.totalRounds}';
      default: // Per paused (già gestito), stopped, finished (gestiti all'inizio)
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

    final Color bgColor = _getBackgroundColor();
    final Brightness bgBrightness = ThemeData.estimateBrightnessForColor(
      bgColor,
    );
    final Color textColor =
        bgBrightness == Brightness.dark ? Colors.white : Colors.black;

    // Determina il tempo da visualizzare quando fermo
    int timeToShowWhenStopped =
        widget.preparationTimeSeconds > 0
            ? widget.preparationTimeSeconds
            : widget.workTimeSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Allenamento'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: bgColor,
        child: SafeArea(
          // Assicura che il contenuto non vada sotto notch/barre di sistema
          child: Center(
            child: Padding(
              // Padding generale per il contenuto
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Indicatore di stato, set e round
                  Text(
                    _getStatusInfoText(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Display tempo rimanente
                  FittedBox(
                    // Adatta la dimensione del font se necessario
                    fit: BoxFit.scaleDown,
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
                        fontSize: 100, // Font ancora più grande
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Pulsanti di controllo
                  if (!isFinished)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        // Skip Previous
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 36,
                          color:
                              canSkip
                                  ? textColor.withValues(alpha: .8)
                                  : Colors.grey.withValues(alpha: .5),
                          tooltip: 'Salta Indietro',
                          onPressed: canSkip ? _skipPrevious : null,
                        ),

                        // Start/Resume o Pause
                        if (isStopped || isPaused)
                          ElevatedButton(
                            // Pulsante circolare per Start/Resume
                            onPressed: _startTimer,
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(20),
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: Icon(
                              isStopped ? Icons.play_arrow : Icons.play_arrow,
                              size: 35,
                            ),
                          )
                        else // Pulsante circolare per Pause
                          ElevatedButton(
                            onPressed: _pauseTimer,
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(20),
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Icon(Icons.pause, size: 35),
                          ),

                        // Reset
                        IconButton(
                          icon: const Icon(Icons.stop),
                          iconSize: 36,
                          color:
                              isStopped
                                  ? Colors.grey.withValues(alpha: .5)
                                  : textColor.withValues(
                                    alpha: 0.8,
                                  ), // Disabilita visivamente se stopped
                          tooltip: 'Reset',
                          onPressed:
                              isStopped
                                  ? null
                                  : _resetTimer, // Disabilita se stopped
                        ),

                        // Skip Next
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          iconSize: 36,
                          color:
                              canSkip
                                  ? textColor.withValues(alpha: 0.8)
                                  : Colors.grey.withValues(alpha: 0.5),
                          tooltip: 'Salta Avanti',
                          onPressed: canSkip ? _skipNext : null,
                        ),
                      ],
                    )
                  else // Pulsante "Nuovo Allenamento"
                    ElevatedButton.icon(
                      icon: const Icon(Icons.settings),
                      label: const Text('Nuovo Allenamento'),
                      onPressed: () {
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                  const SizedBox(height: 50), // Spazio in fondo
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
