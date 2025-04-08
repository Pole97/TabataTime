import 'dart:async';
import 'package:flutter/material.dart';

// Definizione degli stati del timer
enum TimerState { stopped, work, rest, paused, restBetweenSets }

// Widget principale per il timer Tabata
class TabataTimer extends StatefulWidget {
  final int workTimeSeconds;
  final int restTimeSeconds;
  final int restBetweenSetsTimeSeconds;
  final int totalRounds;
  final int totalSets;
  TabataTimer({
    required this.workTimeSeconds,
    required this.restTimeSeconds,
    required this.restBetweenSetsTimeSeconds,
    required this.totalRounds,
    required this.totalSets,
  });
  //const TabataTimer({super.key});

  @override
  State<TabataTimer> createState() => _TabataTimerState();
}

// Widget principale per il timer Tabata
class TabataTimerHome extends StatefulWidget {
  const TabataTimerHome({super.key});

  @override
  State<TabataTimerHome> createState() => _TabataTimerHomeState();
}

class _TabataTimerHomeState extends State<TabataTimerHome> {
  int _workTimeSeconds = 30; // Tempo di lavoro in secondi
  int _restTimeSeconds = 15; // Tempo di riposo in secondi
  int _restBetweenSetsTimeSeconds = 15; // Tempo di riposo in secondi
  int _totalRounds = 4; // Numero totale di round
  int _totalSets = 3; // Numero totale di set

  // Stato corrente del timer
  TimerState _currentState = TimerState.stopped;
  int _currentRound = 0;
  int _currentSet = 0;
  int _currentTimeRemaining = 0; // Tempo rimanente nella fase corrente
  Timer? _timer; // Oggetto Timer per il conto alla rovescia

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Tabata'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Center(
          child: Column(
            children: [
              Text(_workTimeSeconds.toString()),
              TextField(
                onChanged: (value) {
                  if (int.tryParse(value) != null) {
                    _workTimeSeconds = int.parse(value);
                    setState(() {});
                    print(_workTimeSeconds);
                  }
                },
                decoration: InputDecoration(labelText: 'Work time'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to first route when tapped.
                  Navigator.pop(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TabataTimer(
                            workTimeSeconds: _workTimeSeconds,
                            restTimeSeconds: _restTimeSeconds,
                            restBetweenSetsTimeSeconds:
                                _restBetweenSetsTimeSeconds,
                            totalRounds: _totalRounds,
                            totalSets: _totalSets,
                          ),
                    ),
                  );
                },
                child: const Text('Go back!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabataTimerState extends State<TabataTimer> {
  /*// Impostazioni predefinite del timer Tabata
  int _workTimeSeconds = 30; // Tempo di lavoro in secondi
  int _restTimeSeconds = 15; // Tempo di riposo in secondi
  int _restBetweenSetsTimeSeconds = 15; // Tempo di riposo in secondi
  int _totalRounds = 4; // Numero totale di round
  int _totalSets = 3; // Numero totale di set
  */
  // Stato corrente del timer
  TimerState _currentState = TimerState.stopped;
  int _currentRound = 0;
  int _currentSet = 0;
  int _currentTimeRemaining = 0; // Tempo rimanente nella fase corrente
  Timer? _timer; // Oggetto Timer per il conto alla rovescia

  // Funzione per avviare il timer
  void _startTimer() {
    if (_currentState == TimerState.stopped ||
        _currentState == TimerState.paused) {
      // Se è in pausa, riprende semplicemente il timer
      if (_currentState == TimerState.paused) {
        _resumeTimerLoop();
        return;
      }

      // Altrimenti, inizia dal primo round di lavoro
      _currentRound = 1;
      _currentState = TimerState.work;
      _currentTimeRemaining = widget.workTimeSeconds;
      _startTimerLoop();
      setState(() {}); // Aggiorna l'interfaccia utente
    }
  }

  // Funzione per mettere in pausa il timer
  void _pauseTimer() {
    if (_currentState == TimerState.work || _currentState == TimerState.rest) {
      _timer?.cancel(); // Interrompe il timer
      _currentState = TimerState.paused;
      setState(() {}); // Aggiorna l'interfaccia utente
    }
  }

  // Funzione per riprendere il timer dopo la pausa
  void _resumeTimerLoop() {
    if (_currentState == TimerState.paused) {
      // Riprende lo stato precedente (lavoro o riposo)
      // Nota: _currentState viene ripristinato in _startTimerLoop
      _startTimerLoop();
      setState(() {});
    }
  }

  // Funzione per resettare il timer
  void _resetTimer() {
    _timer?.cancel(); // Interrompe il timer se attivo
    _currentState = TimerState.stopped;
    _currentRound = 0;
    _currentTimeRemaining =
        widget.workTimeSeconds; // Reimposta al tempo di lavoro iniziale
    setState(() {}); // Aggiorna l'interfaccia utente
  }

  // Loop principale del timer (gestisce le fasi di lavoro e riposo)
  void _startTimerLoop() {
    // Ripristina lo stato corretto se si riprende dalla pausa
    if (_currentState == TimerState.paused) {
      // Determina se era in pausa durante il lavoro o il riposo
      // Questo è un esempio, potresti voler salvare lo stato esatto prima della pausa
      // Per semplicità, assumiamo che riprenda la fase corrente basata sul tempo rimanente
      // Se il tempo rimanente è maggiore di 0, continua la fase corrente,
      // altrimenti passa alla fase successiva.
      // Una logica più robusta potrebbe salvare lo stato esatto (work/rest) al momento della pausa.
      if (_currentTimeRemaining > 0) {
        // Determina se era lavoro o riposo (logica semplificata)
        // Qui potremmo aver bisogno di una variabile aggiuntiva per sapere se era in work o rest prima della pausa
        // Per ora, assumiamo che riprenda come se fosse lavoro se il round non è completo
        _currentState =
            (_currentRound <= widget.totalRounds)
                ? TimerState.work
                : TimerState.rest;
      } else {
        // Se il tempo era 0, passa alla fase successiva
        _moveToNextPhase();
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTimeRemaining > 1) {
        // Decrementa il tempo rimanente
        setState(() {
          _currentTimeRemaining--;
        });
      } else {
        // Il tempo per la fase corrente è scaduto
        timer.cancel(); // Interrompe il timer corrente
        _moveToNextPhase(); // Passa alla fase successiva
      }
    });
  }

  // Funzione per passare alla fase successiva (lavoro -> riposo o riposo -> lavoro)
  void _moveToNextPhase() {
    if (_currentState == TimerState.work) {
      // Fine fase di lavoro
      if (_currentRound < widget.totalRounds) {
        // Passa alla fase di riposo
        _currentState = TimerState.rest;
        _currentTimeRemaining = widget.restTimeSeconds;
        _startTimerLoop(); // Avvia il timer per il riposo
      } else if (_currentSet < widget.totalSets) {
        // Ci fermiamo prima di passare al prossimo round
        _currentState = TimerState.restBetweenSets;
        _currentTimeRemaining = widget.restBetweenSetsTimeSeconds;
        _startTimerLoop(); // Avvia il timer per il riposo
      } else {
        // Tutti i round completati
        _resetTimer(); // Resetta alla fine
      }
    } else if (_currentState == TimerState.rest) {
      // Fine fase di riposo
      _currentRound++; // Passa al round successivo
      _currentState = TimerState.work;
      _currentTimeRemaining = widget.workTimeSeconds;
      _startTimerLoop(); // Avvia il timer per il lavoro
    } else if (_currentState == TimerState.restBetweenSets) {
      // Fine fase di riposo tra set
      _currentSet++; // Passiamo al set successivo
      _currentRound = 0; // Si azzerano i round
      _currentState = TimerState.work;
      _currentTimeRemaining = widget.workTimeSeconds;
      _startTimerLoop(); // Avvia il timer per il lavoro
    }
    setState(() {}); // Aggiorna l'UI in ogni caso
  }

  // Formatta il tempo in MM:SS
  String _formatTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Colore di sfondo basato sullo stato
  Color _getBackgroundColor() {
    switch (_currentState) {
      case TimerState.work:
        return Colors.green.shade300;
      case TimerState.rest:
        return Colors.blue.shade300;
      case TimerState.paused:
        return Colors.grey.shade400;
      case TimerState.stopped:
        return Colors.white;
      case TimerState.restBetweenSets:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  // Testo dello stato corrente
  String _getStateText() {
    switch (_currentState) {
      case TimerState.work:
        return 'LAVORO';
      case TimerState.rest:
        return 'RIPOSO';
      case TimerState.paused:
        return 'PAUSA';
      case TimerState.stopped:
        return 'PRONTO?';
      case TimerState.restBetweenSets:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // Assicura che il timer sia cancellato quando il widget viene rimosso
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Tabata'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: AnimatedContainer(
        // Aggiunge un'animazione al cambio colore
        duration: const Duration(milliseconds: 500),
        color: _getBackgroundColor(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Indicatore dello stato e del round
              Text(
                _currentState == TimerState.stopped
                    ? 'Premi Start'
                    : '${_getStateText()} - Round $_currentRound/$widget.totalRounds - Set $_currentSet/$widget.totalSets',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color:
                      _currentState == TimerState.stopped
                          ? Colors.black
                          : Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Display del tempo rimanente
              Text(
                _formatTime(
                  _currentTimeRemaining > 0
                      ? _currentTimeRemaining
                      : (_currentState == TimerState.stopped
                          ? widget.workTimeSeconds
                          : 0),
                ), // Mostra tempo lavoro se fermo
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color:
                      _currentState == TimerState.stopped
                          ? Colors.black
                          : Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Pulsanti di controllo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Pulsante Start/Pausa
                  if (_currentState == TimerState.stopped ||
                      _currentState == TimerState.paused)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        _currentState == TimerState.stopped
                            ? 'Start'
                            : 'Riprendi',
                      ),
                      onPressed: _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    )
                  else if (_currentState == TimerState.work ||
                      _currentState == TimerState.rest)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.pause),
                      label: const Text('Pausa'),
                      onPressed: _pauseTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),

                  const SizedBox(width: 20),

                  // Pulsante Reset (visibile solo se il timer non è fermo)
                  if (_currentState != TimerState.stopped)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text('Reset'),
                      onPressed: _resetTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to first route when tapped.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TabataTimerHome(),
                    ),
                  );
                },
                child: const Text('Finish'),
              ),
              // TODO: Aggiungere qui i controlli per modificare workTime, restTime, totalRounds
              // Esempio: Slider o TextField per ogni valore
            ],
          ),
        ),
      ),
    );
  }
}

// Funzione main per eseguire l'app (necessaria per un'app Flutter completa)
void main() {
  runApp(const MaterialApp(home: TabataTimerHome()));
}
