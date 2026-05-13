import 'package:flutter/foundation.dart';

import '../widgets/video/sign_player.dart';

/// Holds persistent translate-screen state so it survives tab switches
/// and app backgrounding. Camera/frame-buffer stay in the widget (hardware).
class TranslateProvider extends ChangeNotifier {
  // ── Sign-to-Text ────────────────────────────────────────────────────────
  List<String> _sentenceWords = [];
  String _translationOutput = '';

  List<String> get sentenceWords => List.unmodifiable(_sentenceWords);
  String get translationOutput => _translationOutput;

  void addWord(String word) {
    _sentenceWords.add(word);
    _translationOutput = _sentenceWords.join(' ');
    notifyListeners();
  }

  void undoLastWord() {
    if (_sentenceWords.isEmpty) return;
    _sentenceWords.removeLast();
    _translationOutput = _sentenceWords.join(' ');
    notifyListeners();
  }

  void clearSignOutput() {
    _sentenceWords.clear();
    _translationOutput = '';
    notifyListeners();
  }

  // ── Text-to-Sign ─────────────────────────────────────────────────────────
  List<String> _currentSentence = [];
  List<SignSegment> _signSegments = [];

  List<String> get currentSentence => List.unmodifiable(_currentSentence);
  List<SignSegment> get signSegments => List.unmodifiable(_signSegments);

  void setSentence(List<String> sentence) {
    _currentSentence = List<String>.from(sentence);
    notifyListeners();
  }

  void setSignSegments(List<SignSegment> segments) {
    _signSegments = List<SignSegment>.from(segments);
    notifyListeners();
  }

  void clearTextToSign() {
    _currentSentence = [];
    _signSegments = [];
    notifyListeners();
  }

  // ── Global reset ─────────────────────────────────────────────────────────
  void reset() {
    _sentenceWords.clear();
    _translationOutput = '';
    _currentSentence.clear();
    _signSegments.clear();
    notifyListeners();
  }
}
