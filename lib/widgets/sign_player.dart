import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import 'skeleton_painter.dart';

class SignPlayer extends StatefulWidget {
  final List<String> sentence; 
  final bool autoPlay;

  const SignPlayer({
    super.key, 
    required this.sentence,
    this.autoPlay = true,
  });

  @override
  State<SignPlayer> createState() => _SignPlayerState();
}

class _SignPlayerState extends State<SignPlayer> {
  final FirestoreService _firestoreService = FirestoreService();

  // Data
  final List<List<Map<String, dynamic>>> _sequence = [];
  final List<String> _sequenceLabels = []; 
  
  // State
  int _currentWordIndex = 0;
  int _currentFrame = 0;
  Timer? _timer;
  bool _isLoading = true;
  String _statusMessage = "Initializing...";
  bool _isPlaying = false;
  double _playbackSpeed = 1.0; 
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadSentence();
  }

  @override
  void didUpdateWidget(SignPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sentence.join(' ') != widget.sentence.join(' ')) {
      _loadSentence();
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchSignData(String term) async {
    try {
      final firestoreData = await _firestoreService.getSign(term);
      if (firestoreData != null) {
        var rawFrames = firestoreData['data']['data']; 
        if (rawFrames != null) {
           return (rawFrames as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) { /* Ignore */ }

    try {
      final jsonString = await rootBundle.loadString('assets/signs/$term.json');
      final data = json.decode(jsonString);
      return (data['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) { return null; }
  }

  // ... inside _SignPlayerState ...

  Future<void> _loadSentence() async {
    _stop(); 
    setState(() {
      _isLoading = true;
      _sequence.clear();
      _sequenceLabels.clear();
      _statusMessage = "Loading signs...";
    });

    for (String rawInput in widget.sentence) {
      if (rawInput.trim().isEmpty) continue;

      String phraseKey = rawInput.trim().toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_') // Convert spaces to underscores
          .replaceAll(RegExp(r'[^a-z0-9_]'), ''); // Remove special chars

      List<Map<String, dynamic>>? phraseFrames = await _fetchSignData(phraseKey);

      if (phraseFrames != null && phraseFrames.isNotEmpty) {
        _sequence.add(phraseFrames);
        _sequenceLabels.add(rawInput.toUpperCase());
      } else {
        List<String> words = rawInput.trim().split(RegExp(r'\s+'));

        for (String word in words) {
          String wordKey = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
          if (wordKey.isEmpty) continue;

          List<Map<String, dynamic>>? wordFrames = await _fetchSignData(wordKey);

          if (wordFrames != null && wordFrames.isNotEmpty) {
            _sequence.add(wordFrames);
            _sequenceLabels.add(word.toUpperCase());
          } else {
            List<String> characters = wordKey.split('');
            for (String char in characters) {
              if (char == '_') continue; 
              List<Map<String, dynamic>>? letterFrames = await _fetchSignData(char);
              
              if (letterFrames != null && letterFrames.isNotEmpty) {
                _sequence.add(letterFrames);
                _sequenceLabels.add(char.toUpperCase());
              }
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_sequence.isEmpty) {
          _statusMessage = "No signs found.";
        }
      });
      
      if (_sequence.isNotEmpty && widget.autoPlay) {
        _play();
      }
    }
  }

  void _play() {
    if (_sequence.isEmpty) return;
    if (_isFinished) {
      setState(() { _currentWordIndex = 0; _currentFrame = 0; _isFinished = false; });
    }
    setState(() => _isPlaying = true);
    _timer?.cancel();
    int frameDuration = (33 / _playbackSpeed).round();

    _timer = Timer.periodic(Duration(milliseconds: frameDuration), (timer) {
      if (!mounted) return;
      setState(() {
        final currentAnim = _sequence[_currentWordIndex];
        if (_currentFrame < currentAnim.length - 1) {
          _currentFrame++;
        } else {
          if (_currentWordIndex < _sequence.length - 1) {
            _currentWordIndex++;
            _currentFrame = 0;
          } else {
            _stop();
            _isFinished = true; 
          }
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _pause() => _stop();

  void _toggleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) _playbackSpeed = 0.5;
      else if (_playbackSpeed == 0.5) _playbackSpeed = 2.0;
      else _playbackSpeed = 1.0;
    });
    if (_isPlaying) _play(); 
  }

  void _replay() {
    setState(() {
      _currentWordIndex = 0;
      _currentFrame = 0;
      _isFinished = false;
    });
    _play();
  }

  void _next() {
    if (_currentWordIndex < _sequence.length - 1) {
      setState(() {
        _currentWordIndex++;
        _currentFrame = 0;
      });
    }
  }

  void _prev() {
    if (_currentWordIndex > 0) {
      setState(() {
        _currentWordIndex--;
        _currentFrame = 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _sequence.isEmpty) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: _isLoading 
            ? const CircularProgressIndicator()
            : Text(_statusMessage, style: const TextStyle(color: Colors.white70)),
        ),
      );
    }

    String currentLabel = "";
    if (_currentWordIndex < _sequenceLabels.length) {
      currentLabel = _sequenceLabels[_currentWordIndex];
    }

    return Column(
      children: [
        // --- 1. ANIMATION BOX ---
        Expanded(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            child: Stack(
              children: [
                SizedBox.expand(
                  child: CustomPaint(
                    painter: SkeletonPainter(
                      _sequence.isNotEmpty 
                        ? _sequence[_currentWordIndex][_currentFrame] 
                        : {}
                    ),
                  ),
                ),
                
                // Label
                Positioned(
                  top: 20, 
                  left: 0, 
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5))
                      ),
                      child: Text(
                        currentLabel, 
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22
                        ),
                      ),
                    ),
                  ),
                ),

                // Sequence Counter
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${_currentWordIndex + 1}/${_sequence.length}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- 2. CONTROLS BAR ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: const Color(0xFF1E1E1E),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Playing: ${currentLabel.toUpperCase()}",
                style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _toggleSpeed,
                    icon: const Icon(Icons.speed, color: Colors.white70, size: 20),
                    label: Text("${_playbackSpeed}x", style: const TextStyle(color: Colors.white)),
                  ),
                  IconButton(onPressed: _prev, icon: const Icon(Icons.skip_previous, color: Colors.white70)),
                  FloatingActionButton.small(
                    onPressed: _isPlaying ? _pause : _play,
                    backgroundColor: _isPlaying ? Colors.amber : Colors.green,
                    child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
                  ),
                  IconButton(onPressed: _next, icon: const Icon(Icons.skip_next, color: Colors.white70)),
                  IconButton(onPressed: _replay, icon: const Icon(Icons.replay, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}