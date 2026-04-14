import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/dtw_service.dart';
import '../../widgets/common/glass_ui.dart';
import '../../widgets/video/sign_player.dart';

enum _RecognitionState { idle, signing, processing }


class TranslateScreen extends StatefulWidget {
  final bool showBackButton;

  const TranslateScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  
  // Voice & TTS
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  
  // ── WebView / MediaPipe live recognition ─────────────────────────────────
  InAppWebViewController? _webViewController;
  InAppLocalhostServer? _localhostServer;
  bool _isCameraActive = false;
  bool _mediaPipeReady = false;

  // Sign-boundary state machine
  _RecognitionState _recognitionState = _RecognitionState.idle;
  // Frames are Map<String,dynamic> matching DtwService format exactly
  final List<Map<String, dynamic>> _frameBuffer = [];
  List<double>? _prevWristPos; // [lw_x, lw_y, rw_x, rw_y]

  // Timer-based sign boundaries — framerate-independent
  Timer? _signEndTimer;
  Timer? _maxSignTimer;
  static const _kSignEndDelay    = Duration(milliseconds: 600);
  static const _kMaxSignDuration = Duration(seconds: 4);
  static const int    _kMinSignFrames  = 5;
  static const double _kMotionThreshold = 0.02;

  // Library loading
  bool _libraryLoaded = false;
  bool _libraryLoading = false;

  // Sign→Text results
  String _translationOutput = '';
  final List<String> _recognizedWords = [];
  List<SignMatch> _lastMatches = [];

  // Text→Sign state
  bool _isTranslating = false;
  List<String> _currentSentence = [];
  List<SignSegment> _signSegments = [];
  final int _maxCharacters = 200;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // NOTE: Do NOT preload the sign library here.
    // TranslateScreen lives inside an IndexedStack and is created at app startup.
    // Loading all sign_animations on startup would block Firestore for every other page.
    // Library is loaded lazily inside _startCamera() instead.
  }

  @override
  void dispose() {
    _signEndTimer?.cancel();
    _maxSignTimer?.cancel();
    _localhostServer?.close();
    _tabController.dispose();
    _textController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _preloadLibrary() async {
    if (DtwService.instance.isLoaded) {
      setState(() { _libraryLoaded = true; });
      return;
    }
    setState(() { _libraryLoading = true; });
    try {
      await DtwService.instance.loadLibrary();
      if (mounted) {
        setState(() {
          _libraryLoaded = true;
          _libraryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _libraryLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = widget.showBackButton || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: canPop
          ? GlassAppBar(
              title: AppLocalizations.of(context).navTranslate,
              showBack: true,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!canPop) _buildHeader(),
            _buildTabSwitcher(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSignToTextTab(),
                  _buildTextToSignTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const TealGradientIcon(icon: Icons.translate, size: 40),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).navTranslate,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildTabBtn(0, Icons.sign_language_outlined, AppLocalizations.of(context).signToTextTab),
          _buildTabBtn(1, Icons.edit_note_rounded, AppLocalizations.of(context).textToSignTab),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTabBtn(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primary : context.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : context.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SIGN TO TEXT TAB ====================

  Widget _buildSignToTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildCameraPreview(),
          const SizedBox(height: 16),
          _buildLiveSentence(),
          const SizedBox(height: 12),
          if (_lastMatches.isNotEmpty) _buildAlternativeMatches(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// The live sentence — words pop in one by one as each sign is recognized.
  Widget _buildLiveSentence() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context).translationOutput,
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context).aslToEnglish,
                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Word chips that build up live
          _recognizedWords.isEmpty
              ? Text(
                  _isCameraActive
                      ? 'Sign a word — it will appear here...'
                      : AppLocalizations.of(context).waitingForGestures,
                  style: TextStyle(color: context.textMuted, fontSize: 15, height: 1.5),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recognizedWords.asMap().entries.map((entry) {
                    final isLatest = entry.key == _recognizedWords.length - 1;
                    return GestureDetector(
                      onLongPress: () {
                        // Long-press a word to remove it
                        setState(() {
                          _recognizedWords.removeAt(entry.key);
                          _translationOutput = _recognizedWords.join(' ');
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isLatest
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : context.bgElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLatest
                                ? AppColors.primary
                                : context.borderColor,
                            width: isLatest ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isLatest
                                ? AppColors.primary
                                : context.textPrimary,
                            fontWeight: isLatest ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ).animate(key: ValueKey('word_${entry.key}')).fadeIn(duration: 300.ms).slideX(begin: 0.2),
                    );
                  }).toList(),
                ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              _buildOutputActionButton(
                icon: Icons.volume_up,
                label: AppLocalizations.of(context).speak,
                onTap: _speakOutput,
              ),
              const SizedBox(width: 10),
              _buildOutputActionButton(
                icon: Icons.copy,
                label: AppLocalizations.of(context).copy,
                onTap: _copyOutput,
              ),
              const SizedBox(width: 10),
              _buildOutputActionButton(
                icon: Icons.delete_outline,
                label: AppLocalizations.of(context).clear,
                onTap: _clearOutput,
              ),
            ],
          ),
          if (_recognizedWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Long-press a word to remove it',
                style: TextStyle(color: context.textMuted, fontSize: 11),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  /// Small "did the wrong word pop?" — alternatives from the last DTW match.
  Widget _buildAlternativeMatches() {
    final alts = _lastMatches.skip(1).toList(); // skip the best (already added)
    if (alts.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOT THE RIGHT WORD? TAP TO REPLACE',
            style: TextStyle(
              color: context.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: alts.map((match) {
              final pct = (match.confidence * 100).toStringAsFixed(0);
              return GestureDetector(
                onTap: () {
                  // Replace the last recognized word with this alternative
                  if (_recognizedWords.isEmpty) return;
                  setState(() {
                    _recognizedWords[_recognizedWords.length - 1] = match.word;
                    _translationOutput = _recognizedWords.join(' ');
                    _lastMatches.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.bgElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    '${match.word}  $pct%',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildCameraPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 380,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
        ),
        child: _isCameraActive ? _buildActiveCameraView() : _buildCameraPlaceholder(),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildCameraPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.camera_alt_outlined, color: context.textMuted, size: 40),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            AppLocalizations.of(context).pointCameraAtSigns,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textMuted, fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _startCamera,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).startCamera, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── MediaPipe Holistic via WebView ────────────────────────────
        // Loaded from localhost so getUserMedia() has a secure context.
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('http://localhost:8765/holistic_camera.html'),
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            controller.addJavaScriptHandler(
              handlerName: 'onLandmarks',
              callback: (args) {
                if (args.isNotEmpty && args[0] is Map) {
                  _onLandmarksReceived(Map<String, dynamic>.from(args[0] as Map));
                }
              },
            );
            controller.addJavaScriptHandler(
              handlerName: 'onReady',
              callback: (_) {
                if (mounted) setState(() => _mediaPipeReady = true);
              },
            );
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            useHybridComposition: true,
            javaScriptEnabled: true,
          ),
        ),

        // ── State overlay (top center) ────────────────────────────────
        Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: Center(child: _buildStateChip()),
        ),

        // ── Library status (top-left) ─────────────────────────────────
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _libraryLoaded ? Icons.check_circle : Icons.hourglass_bottom,
                  color: _libraryLoaded ? Colors.greenAccent : Colors.orange,
                  size: 11,
                ),
                const SizedBox(width: 4),
                Text(
                  _libraryLoaded
                      ? '${DtwService.instance.librarySize} signs'
                      : (_libraryLoading ? 'Loading...' : 'No library'),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // ── Bottom bar: just the Close button ─────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: GestureDetector(
                onTap: _stopCamera,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop_circle_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Stop Camera',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateChip() {
    switch (_recognitionState) {
      case _RecognitionState.idle:
        return _stateChip(
          color: Colors.green,
          icon: Icons.circle,
          label: 'Listening — sign a word',
          pulse: true,
        );
      case _RecognitionState.signing:
        return _stateChip(
          color: Colors.orange,
          icon: Icons.fiber_manual_record,
          label: 'Signing… (${_frameBuffer.length} frames)',
          pulse: true,
        );
      case _RecognitionState.processing:
        return _stateChip(
          color: Colors.blue,
          icon: Icons.hourglass_bottom,
          label: 'Matching…',
        );
    }
  }

  Widget _stateChip({
    required Color color,
    required IconData icon,
    required String label,
    bool pulse = false,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
    return pulse ? chip.animate(onPlay: (c) => c.repeat()).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms) : chip;
  }

  // ==================== TEXT TO SIGN TAB ====================

  Widget _buildTextToSignTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildTextInputSection(),
          const SizedBox(height: 20),
          _buildSignPreview(),
          if (_signSegments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSegmentBreakdown(),
          ],
          const SizedBox(height: 20),
          _buildCurrentSignSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextInputSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).enterText,
                style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
              Text('${_textController.text.length}/$_maxCharacters', style: TextStyle(color: context.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLength: _maxCharacters,
            maxLines: 3,
            style: TextStyle(color: context.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).typeWordSentence,
              hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // UPDATED: Voice Input Button
              _buildInputActionButton(
                icon: _isListening ? Icons.mic_off : Icons.mic,
                label: _isListening ? AppLocalizations.of(context).listening : AppLocalizations.of(context).voice,
                onTap: _startVoiceInput,
                isActive: _isListening,
              ),
              const SizedBox(width: 10),
              _buildInputActionButton(icon: Icons.delete_outline, label: AppLocalizations.of(context).clear, onTap: () {
                _textController.clear();
                setState(() { _currentSentence = []; _signSegments = []; });
              }),
              const Spacer(),
              GestureDetector(
                onTap: _translateText,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sign_language_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).translateBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildInputActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.red.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? Colors.red.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.red : context.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isActive ? Colors.red : context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignPreview() {
    return Container(
      // Increased height to fit Animation + Gap + Controls comfortably
      height: 480, 
      width: double.infinity,
      // REMOVED: The decoration (color/border) is now handled inside SignPlayer components
      child: _currentSentence.isNotEmpty
          ? SignPlayer(
              sentence: _currentSentence,
              key: ValueKey(_currentSentence.join()),
              onLoadComplete: (segments) {
                if (mounted) setState(() => _signSegments = segments);
              },
            )
          : Container(
              // Keep placeholder styling or make it match animation box style
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
              ),
              child: _buildPreviewPlaceholder(),
            ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildPreviewPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6366F1).withValues(alpha: 0.4), const Color(0xFF8B5CF6).withValues(alpha: 0.4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.sign_language_rounded, color: Colors.white, size: 50),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isTranslating ? AppLocalizations.of(context).translating : AppLocalizations.of(context).readyToTranslate,
          style: TextStyle(color: context.textSecondary, fontSize: 16),
        ),
      ],
    );
  }

  // UPDATED: Now includes Speaker Button
  Widget _buildCurrentSignSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).currentSign, style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(AppLocalizations.of(context).englishToMsl, style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // NEW: Row with text and speaker button
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentSentence.isEmpty ? AppLocalizations.of(context).typeSomethingToSee : _currentSentence.join(' ').toUpperCase(),
                  style: TextStyle(
                    color: _currentSentence.isEmpty ? context.textMuted : context.textPrimary,
                    fontSize: 16,
                    fontWeight: _currentSentence.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (_currentSentence.isNotEmpty)
                IconButton(
                  onPressed: _speakCurrentSign,
                  icon: const Icon(Icons.volume_up, color: AppColors.primary),
                  tooltip: AppLocalizations.of(context).speakSign,
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ==================== ACTIONS ====================

  Future<void> _startCamera() async {
    // Serve holistic_camera.html from localhost so getUserMedia works.
    // Android WebView blocks camera access from file:// origins (not a secure context).
    // http://localhost is treated as secure, so camera permission dialogs work.
    if (_localhostServer == null) {
      _localhostServer = InAppLocalhostServer(documentRoot: 'assets', port: 8765);
      await _localhostServer!.start();
    }
    setState(() {
      _isCameraActive = true;
      _mediaPipeReady = false;
      _recognitionState = _RecognitionState.idle;
    });
    // Load sign library in the background while WebView starts
    if (!DtwService.instance.isLoaded) _preloadLibrary();
  }

  /// Receives MediaPipe Holistic landmarks from the WebView JS bridge.
  /// Runs the sign-boundary state machine and buffers frames.
  void _onLandmarksReceived(Map<String, dynamic> data) {
    if (_recognitionState == _RecognitionState.processing) return;

    final pose = data['pose'] as List?;
    if (pose == null || pose.length < 17) return;

    // Build frame in DtwService format (snake_case keys)
    final frame = <String, dynamic>{
      'pose': pose,
      'left_hand': data['leftHand'],
      'right_hand': data['rightHand'],
    };

    // Wrist motion detection
    // MediaPipe pose indices: 11=leftShoulder, 12=rightShoulder, 15=leftWrist, 16=rightWrist
    final lw = pose[15] as Map?;
    final rw = pose[16] as Map?;
    final ls = pose[11] as Map?;
    final rs = pose[12] as Map?;

    if (lw == null && rw == null) return;

    final lwX = lw != null ? (lw['x'] as num).toDouble() : 0.0;
    final lwY = lw != null ? (lw['y'] as num).toDouble() : 0.0;
    final rwX = rw != null ? (rw['x'] as num).toDouble() : 0.0;
    final rwY = rw != null ? (rw['y'] as num).toDouble() : 0.0;

    // Scale by shoulder width; fallback to 0.3 if shoulders not visible
    double sc = 0.3;
    if (ls != null && rs != null) {
      final lsX = (ls['x'] as num).toDouble();
      final lsY = (ls['y'] as num).toDouble();
      final rsX = (rs['x'] as num).toDouble();
      final rsY = (rs['y'] as num).toDouble();
      final sw = sqrt(pow(rsX - lsX, 2) + pow(rsY - lsY, 2));
      if (sw > 0.05) sc = sw;
    }

    double wristMovement = 0;
    if (_prevWristPos != null) {
      final lwDx = (lwX - _prevWristPos![0]) / sc;
      final lwDy = (lwY - _prevWristPos![1]) / sc;
      final rwDx = (rwX - _prevWristPos![2]) / sc;
      final rwDy = (rwY - _prevWristPos![3]) / sc;
      wristMovement = max(
        sqrt(lwDx * lwDx + lwDy * lwDy),
        sqrt(rwDx * rwDx + rwDy * rwDy),
      );
    }
    _prevWristPos = [lwX, lwY, rwX, rwY];

    final isMoving = wristMovement > _kMotionThreshold;

    if (isMoving) {
      _frameBuffer.add(frame);
      _signEndTimer?.cancel();
      _signEndTimer = null;

      if (_recognitionState == _RecognitionState.idle && mounted) {
        setState(() => _recognitionState = _RecognitionState.signing);
        _maxSignTimer?.cancel();
        _maxSignTimer = Timer(_kMaxSignDuration, _runDtw);
      } else if (_recognitionState == _RecognitionState.signing && mounted) {
        setState(() {}); // update frame counter in chip
      }
    } else if (_recognitionState == _RecognitionState.signing) {
      _frameBuffer.add(frame); // trailing still frames
      _signEndTimer ??= Timer(_kSignEndDelay, _runDtw);
    }
  }

  void _runDtw() {
    _signEndTimer?.cancel();
    _signEndTimer = null;
    _maxSignTimer?.cancel();
    _maxSignTimer = null;

    if (_recognitionState == _RecognitionState.processing) return;
    if (mounted) setState(() => _recognitionState = _RecognitionState.processing);

    final buffer = List<Map<String, dynamic>>.from(_frameBuffer);
    _frameBuffer.clear();

    if (buffer.length < _kMinSignFrames || !DtwService.instance.isLoaded) {
      _resetCapture();
      return;
    }

    // DtwService.match() normalises + runs DTW synchronously
    final matches = DtwService.instance.match(buffer);

    if (!mounted) return;
    setState(() {
      if (matches.isNotEmpty && matches.first.confidence > 0.25) {
        _recognizedWords.add(matches.first.word);
        _translationOutput = _recognizedWords.join(' ');
        _lastMatches = matches;
      }
    });
    _resetCapture();
  }

  void _resetCapture() {
    if (mounted) {
      setState(() {
        _recognitionState = _RecognitionState.idle;
        _prevWristPos = null;
      });
    }
  }

  void _stopCamera() {
    _signEndTimer?.cancel();
    _signEndTimer = null;
    _maxSignTimer?.cancel();
    _maxSignTimer = null;
    _webViewController = null;
    _localhostServer?.close();
    _localhostServer = null;

    if (mounted) {
      setState(() {
        _isCameraActive = false;
        _mediaPipeReady = false;
        _recognitionState = _RecognitionState.idle;
        _frameBuffer.clear();
        _prevWristPos = null;
      });
    }
  }

  // Output TTS (Sign -> Text tab)
  void _speakOutput() async {
    if (_translationOutput.isEmpty) return;
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak(_translationOutput);
  }

  // Current Sign TTS (Text -> Sign tab)
  void _speakCurrentSign() async {
    if (_currentSentence.isNotEmpty) {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.speak(_currentSentence.join(" "));
    }
  }

  void _copyOutput() {
    if (_translationOutput.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _translationOutput));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).copiedToClipboard), behavior: SnackBarBehavior.floating),
    );
  }

  void _clearOutput() {
    setState(() {
      _translationOutput = '';
      _recognizedWords.clear();
      _lastMatches.clear();
    });
  }

  // UPDATED: Real Voice Input Logic
  void _startVoiceInput() async {
    if (!_isListening) {
      final messenger = ScaffoldMessenger.of(context);
      final micDeniedMsg = AppLocalizations.of(context).micAccessDenied;
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('onStatus: $status'),
        onError: (errorNotification) => debugPrint('onError: $errorNotification'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
          }),
        );
      } else {
        messenger.showSnackBar(SnackBar(content: Text(micDeniedMsg)));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  

  void _translateText() {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isTranslating = true;
      // CHANGED: Do NOT split by space here. Pass the full string as one item.
      // This allows SignPlayer to check for multi-word signs like "muslim_prayer".
      _currentSentence = [_textController.text.trim()]; 
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isTranslating = false);
    });
  }
  
  Widget _buildSegmentBreakdown() {
    final bimCount = _signSegments.where((s) => s.type == 'bim').length;
    final fsCount = _signSegments.where((s) => s.type == 'fingerspell').length;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'WORD BREAKDOWN',
                style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
              const Spacer(),
              if (bimCount > 0)
                _buildCountBadge('$bimCount BIM', Colors.green),
              if (bimCount > 0 && fsCount > 0) const SizedBox(width: 6),
              if (fsCount > 0)
                _buildCountBadge('$fsCount Fingerspelled', Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _signSegments.map((seg) {
              final isBim = seg.type == 'bim';
              final color = isBim ? Colors.green : Colors.blueAccent;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBim ? Icons.sign_language_rounded : Icons.gesture_rounded,
                      color: color,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      seg.label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildOutputActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}