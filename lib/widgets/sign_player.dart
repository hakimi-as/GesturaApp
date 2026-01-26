import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import 'skeleton_painter.dart';
import '../config/theme.dart'; 

class SignPlayer extends StatefulWidget {
  final List<String> sentence; 
  final bool autoPlay;
  final bool isAlphabetMode; // NEW: indicates if playing alphabet letters

  const SignPlayer({
    super.key, 
    required this.sentence,
    this.autoPlay = true,
    this.isAlphabetMode = false,
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
    if (oldWidget.sentence.join(' ') != widget.sentence.join(' ') ||
        oldWidget.isAlphabetMode != widget.isAlphabetMode) {
      _loadSentence();
    }
  }

  /// Fetch sign data for a LETTER (e.g., 'a' -> tries 'letter_a' first, then 'a')
  Future<List<Map<String, dynamic>>?> _fetchLetterData(String letter) async {
    final char = letter.toLowerCase();
    
    // Try "letter_x" format first (for Sign Library letters)
    final letterKey = 'letter_$char';
    var frames = await _fetchSignDataByKey(letterKey);
    if (frames != null) return frames;
    
    // Fallback to just the character
    return await _fetchSignDataByKey(char);
  }

  /// Fetch sign data for a WORD (e.g., 'i' -> tries 'i' first, then 'word_i')
  Future<List<Map<String, dynamic>>?> _fetchWordData(String word) async {
    final key = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    
    // Try the word directly first
    var frames = await _fetchSignDataByKey(key);
    if (frames != null) return frames;
    
    // For single characters that are words (like "I"), try "word_x" format
    if (word.length == 1) {
      return await _fetchSignDataByKey('word_$key');
    }
    
    return null;
  }

  /// Low-level fetch by exact key
  Future<List<Map<String, dynamic>>?> _fetchSignDataByKey(String key) async {
    // Try Firestore (using optimized getSignData that loads from sign_animations)
    try {
      final firestoreData = await _firestoreService.getSignData(key);
      if (firestoreData != null && firestoreData['data'] != null) {
        return (firestoreData['data'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('⚠️ Firestore fetch failed for $key: $e');
    }

    // Fallback to local assets
    try {
      final jsonString = await rootBundle.loadString('assets/signs/$key.json');
      final data = json.decode(jsonString);
      if (data['data'] != null) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Asset not found - this is expected for many signs
    }

    return null;
  }

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

      // If in alphabet mode and it's a single character, treat as letter
      if (widget.isAlphabetMode && rawInput.trim().length == 1) {
        final char = rawInput.trim();
        final frames = await _fetchLetterData(char);
        if (frames != null && frames.isNotEmpty) {
          _sequence.add(frames);
          _sequenceLabels.add('Letter ${char.toUpperCase()}');
        }
        continue;
      }

      // Try to fetch as a phrase first
      String phraseKey = rawInput.trim().toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_') 
          .replaceAll(RegExp(r'[^a-z0-9_]'), ''); 

      List<Map<String, dynamic>>? phraseFrames = await _fetchWordData(phraseKey);

      if (phraseFrames != null && phraseFrames.isNotEmpty) {
        _sequence.add(phraseFrames);
        _sequenceLabels.add(rawInput.toUpperCase());
      } else {
        // Split into words
        List<String> words = rawInput.trim().split(RegExp(r'\s+'));

        for (String word in words) {
          String wordKey = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
          if (wordKey.isEmpty) continue;

          // Try to fetch as a word
          List<Map<String, dynamic>>? wordFrames = await _fetchWordData(wordKey);

          if (wordFrames != null && wordFrames.isNotEmpty) {
            _sequence.add(wordFrames);
            _sequenceLabels.add(word.toUpperCase());
          } else {
            // Fingerspell - split into characters (these are LETTERS)
            List<String> characters = wordKey.split('');
            for (String char in characters) {
              if (char == '_') continue;
              
              // Fingerspelling uses LETTER signs
              List<Map<String, dynamic>>? letterFrames = await _fetchLetterData(char);
              
              if (letterFrames != null && letterFrames.isNotEmpty) {
                _sequence.add(letterFrames);
                // Show "Letter X" for fingerspelled characters
                _sequenceLabels.add('Letter ${char.toUpperCase()}');
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
        height: 300,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
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
        // Animation Box
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
                  
                  // Label - shows "Letter X" for letters, "WORD" for words
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
        ),

        const SizedBox(height: 16),

        // Controls Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    "CONTROLS",
                    style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                  Text(
                    "Playing: $currentLabel",
                    style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlBtn(
                    icon: Icons.speed,
                    label: "${_playbackSpeed}x",
                    onTap: _toggleSpeed,
                  ),
                  
                  IconButton(onPressed: _prev, icon: Icon(Icons.skip_previous, color: context.textPrimary)),
                  
                  FloatingActionButton.small(
                    onPressed: _isPlaying ? _pause : _play,
                    backgroundColor: _isPlaying ? Colors.amber : Colors.green,
                    elevation: 0,
                    child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
                  ),
                  
                  IconButton(onPressed: _next, icon: Icon(Icons.skip_next, color: context.textPrimary)),
                  
                  _buildControlBtn(
                    icon: Icons.replay,
                    label: "",
                    onTap: _replay,
                    isIconOnly: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlBtn({required IconData icon, required String label, required VoidCallback onTap, bool isIconOnly = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 10 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).iconTheme.color),
            if (!isIconOnly) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
}