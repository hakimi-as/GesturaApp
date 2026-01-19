import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import 'skeleton_painter.dart';

class SignPlayer extends StatefulWidget {
  // Now accepts a list of words for sentence chaining
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

  // Stores the sequence of animations. 
  // Structure: [ [Frames for Word 1], [Frames for Word 2] ]
  final List<List<Map<String, dynamic>>> _sequence = [];
  
  int _currentWordIndex = 0; // Which word are we playing?
  int _currentFrame = 0;     // Which frame of that word?
  Timer? _timer;
  bool _isLoading = true;
  String _statusMessage = "Initializing...";

  @override
  void initState() {
    super.initState();
    _loadSentence();
  }

  @override
  void didUpdateWidget(SignPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if the sentence changes (comparing joined strings is a quick way to check lists)
    if (oldWidget.sentence.join(' ') != widget.sentence.join(' ')) {
      _loadSentence();
    }
  }

  Future<void> _loadSentence() async {
    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _sequence.clear();
      _currentWordIndex = 0;
      _currentFrame = 0;
      _statusMessage = "Loading signs...";
    });

    for (String word in widget.sentence) {
      try {
        List<Map<String, dynamic>>? frames;
        // Clean the word (lowercase, alphanumeric + underscore only)
        final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');

        if (cleanWord.isEmpty) continue;

        // ---------------------------------------------------------
        // STRATEGY: Cloud First -> Local Fallback
        // ---------------------------------------------------------
        
        // 1. Try fetching from Cloud Firestore
        try {
          final firestoreData = await _firestoreService.getSign(cleanWord);
          if (firestoreData != null) {
            // Firestore data structure: { 'word': '...', 'data': { 'word': '...', 'data': [...] } }
            // We need to drill down to the inner 'data' list
            var rawFrames = firestoreData['data']['data']; 
            if (rawFrames != null) {
               frames = (rawFrames as List).cast<Map<String, dynamic>>();
               debugPrint("☁️ Loaded '$cleanWord' from CLOUD");
            }
          }
        } catch (e) {
          // Cloud fetch failed or document didn't exist, silently continue to local
        }

        // 2. If Cloud failed, try Local Assets
        if (frames == null) {
          try {
            final jsonString = await rootBundle.loadString('assets/signs/$cleanWord.json');
            final data = json.decode(jsonString);
            frames = (data['data'] as List).cast<Map<String, dynamic>>();
            debugPrint("📦 Loaded '$cleanWord' from ASSETS");
          } catch (e) {
            debugPrint("⚠️ Word not found in assets: $cleanWord");
          }
        }

        // 3. Add to sequence if we found frames
        if (frames != null && frames.isNotEmpty) {
          _sequence.add(frames);
        }

      } catch (e) {
        debugPrint("Error processing word '$word': $e");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_sequence.isEmpty) {
          _statusMessage = "No signs found for this text.";
        }
      });
      
      if (_sequence.isNotEmpty && widget.autoPlay) {
        _play();
      }
    }
  }

  void _play() {
    _timer?.cancel();
    // 30 FPS = approx 33ms per frame
    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!mounted) return;

      setState(() {
        if (_sequence.isEmpty) return;

        final currentAnim = _sequence[_currentWordIndex];

        if (_currentFrame < currentAnim.length - 1) {
          // Next frame in current word
          _currentFrame++;
        } else {
          // Word finished. Move to next word?
          if (_currentWordIndex < _sequence.length - 1) {
            _currentWordIndex++;
            _currentFrame = 0; // Reset for new word
          } else {
            // Sentence finished. Loop back to start.
            _currentWordIndex = 0;
            _currentFrame = 0;
            
            // Optional: Pause briefly between loops for better readability
            _timer?.cancel();
            Future.delayed(const Duration(seconds: 2), _play);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Error / Empty State
    if (!_isLoading && _sequence.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
            SizedBox(height: 10),
            Text(
              "Translation not available", 
              style: TextStyle(color: Colors.white70)
            ),
          ],
        ),
      );
    }

    // 2. Loading State
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusMessage, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    // 3. Determine current word being played for the UI overlay
    String currentWordPlaying = "";
    // We map the sequence index back to the sentence list roughly
    // Note: If some words were skipped (missing), this might be slightly off, 
    // but for now it assumes valid words map 1:1.
    if (_currentWordIndex < _sequence.length) {
       // We can't map directly to widget.sentence index if we skipped words.
       // However, for visual feedback, usually showing the valid loaded word is enough.
       // A more complex implementation would track the word string alongside the frames in _sequence.
    }

    // 4. Animation Player
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: Stack(
        children: [
          // The Skeleton
          SizedBox.expand(
            child: CustomPaint(
              painter: SkeletonPainter(
                _sequence.isNotEmpty 
                  ? _sequence[_currentWordIndex][_currentFrame] 
                  : {}
              ),
            ),
          ),
          
          // Debug/Info Overlay (Shows which word in the sequence is playing)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24)
              ),
              child: Text(
                "Sequence: ${_currentWordIndex + 1}/${_sequence.length}",
                style: const TextStyle(
                  color: Colors.tealAccent, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 12
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}