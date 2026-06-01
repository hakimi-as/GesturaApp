import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/design_system.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/translate_provider.dart';
import '../../services/remote_sign_service.dart';
import '../../services/dtw_service.dart';
import '../../widgets/video/sign_player.dart';

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

  // ── Sign-to-Text state ──────────────────────────────────────────────────
  // _sentenceWords and _translationOutput live in TranslateProvider
  bool _isCameraActive = false;
  bool _isTranslating = false;
  String _currentDetected = '';
  bool _isMatching = false;

  // Frame buffer — rolling window
  final List<Map<String, dynamic>> _frameBuffer = [];
  static const int _minFrames = 12;
  static const int _maxFrames = 30; // ~2 seconds at 15fps
  int _stillFrameCount = 0;
  List<double>? _prevWristPos;
  bool _isReady = false; // true once buffer has enough frames

  // Real-time auto-detection cooldown
  static const int _stillThreshold = 8; // ~0.5s at 15fps
  DateTime? _lastMatchTime;

  // WebView for MediaPipe Holistic
  InAppWebViewController? _webViewController;

  // ── Text-to-Sign state ──────────────────────────────────────────────────
  // _currentSentence and _signSegments live in TranslateProvider
  final int _maxCharacters = 200;

  TranslateProvider get _tp => context.read<TranslateProvider>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _webViewController = null;
    _tabController.dispose();
    _textController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canPop = widget.showBackButton || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: context.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                AppLocalizations.of(context).navTranslate,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: context.textPrimary,
                ),
              ),
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

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Text(
        AppLocalizations.of(context).navTranslate,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.04 * 22,
          color: context.textPrimary,
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  // ── Tab switcher ────────────────────────────────────────────────────────

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          _buildTabBtn(0, Icons.sign_language_outlined, AppLocalizations.of(context).signToTextTab),
          _buildTabBtn(1, Icons.text_fields_outlined, AppLocalizations.of(context).textToSignTab),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTabBtn(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: TapScale(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : context.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textMuted,
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

  // ════════════════════════════════════════════════════════════════════════
  // SIGN-TO-TEXT TAB
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSignToTextTab() {
    return Consumer<TranslateProvider>(
      builder: (context, tp, _) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildCameraSection(),
            const SizedBox(height: 16),
            if (_isCameraActive) _buildCurrentDetectionBadge(),
            if (_isCameraActive) const SizedBox(height: 16),
            _buildTranslationOutput(tp),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Camera section ───────────────────────────────────────────────────────

  Widget _buildCameraSection() {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isCameraActive ? _buildWebCameraView() : _buildCameraPlaceholder(),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildCameraPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, color: context.textMuted, size: 52),
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
        TapScale(
          onTap: _startCamera,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📷', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context).startCamera,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── MediaPipe Holistic WebView ─────────────────────────────────
        InAppWebView(
          initialFile: 'assets/holistic_camera.html',
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            javaScriptEnabled: true,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;

            // Handler: MediaPipe sends landmarks every frame (~15fps)
            controller.addJavaScriptHandler(
              handlerName: 'onLandmarks',
              callback: (args) {
                if (args.isNotEmpty && args[0] is Map) {
                  _onLandmarksFromWeb(args[0] as Map<String, dynamic>);
                }
              },
            );

            // Handler: MediaPipe is ready
            controller.addJavaScriptHandler(
              handlerName: 'onReady',
              callback: (args) {
                debugPrint('MediaPipe Holistic is ready');
              },
            );
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
        ),

        // ── Recording indicator ────────────────────────────────────────
        Positioned(
          top: 14,
          left: 14,
          child: _buildRecordingPill(),
        ),

        // ── Ready indicator ────────────────────────────────────────────
        Positioned(
          top: 14,
          right: 14,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isReady && !_isMatching
                ? Container(
                    key: const ValueKey('ready'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text('Ready', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : Container(
                    key: const ValueKey('loading'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Hold sign… ${_frameBuffer.length}/$_minFrames',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
          ),
        ),

        // ── Bottom controls: Capture + Stop ───────────────────────────
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TapScale(
                onTap: _isMatching ? null : _captureSign,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isMatching
                        ? AppColors.primary.withValues(alpha: 0.7)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isMatching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('👋', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(
                        _isMatching ? 'Matching…' : 'Capture Sign',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TapScale(
                onTap: _stopCamera,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.stop, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingPill() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isMatching
            ? AppColors.primary.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isMatching ? Colors.white : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isMatching ? 'Matching…' : 'Recording',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Current detection badge ──────────────────────────────────────────────

  Widget _buildCurrentDetectionBadge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _currentDetected.isEmpty
          ? Container(
              key: const ValueKey('empty'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Text(
                'Sign a word, then tap Capture Sign',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted, fontSize: 14),
              ),
            )
          : Container(
              key: ValueKey(_currentDetected),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👋', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(
                    _currentDetected,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
    ).animate().fadeIn(duration: 200.ms);
  }

  // ── Translation output box ───────────────────────────────────────────────

  Widget _buildTranslationOutput(TranslateProvider tp) {
    final sentenceWords = tp.sentenceWords;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translationOutput,
                style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
              Row(
                children: [
                  if (sentenceWords.isNotEmpty)
                    TapScale(
                      onTap: () => _tp.undoLastWord(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.bgElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.undo, size: 12, color: context.textMuted),
                            const SizedBox(width: 4),
                            Text('Undo', style: TextStyle(fontSize: 10, color: context.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
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
            ],
          ),
          const SizedBox(height: 16),

          // Word chips — each matched word as a chip
          if (sentenceWords.isEmpty)
            Text(
              AppLocalizations.of(context).waitingForGestures,
              style: TextStyle(color: context.textMuted, fontSize: 16, height: 1.5),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sentenceWords.asMap().entries.map((entry) {
                final isLast = entry.key == sentenceWords.length - 1;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLast
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : context.bgElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLast ? AppColors.primary.withValues(alpha: 0.5) : context.borderColor,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isLast ? AppColors.primary : context.textPrimary,
                      fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),
          Row(
            children: [
              Flexible(
                child: _buildOutputActionButton(
                  icon: Icons.volume_up,
                  label: AppLocalizations.of(context).speak,
                  onTap: () => _speakOutput(sentenceWords),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _buildOutputActionButton(
                  icon: Icons.copy,
                  label: AppLocalizations.of(context).copy,
                  onTap: () => _copyOutput(sentenceWords),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _buildOutputActionButton(
                  icon: Icons.delete_outline,
                  label: AppLocalizations.of(context).clear,
                  onTap: _clearOutput,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ════════════════════════════════════════════════════════════════════════
  // TEXT-TO-SIGN TAB
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildTextToSignTab() {
    return Consumer<TranslateProvider>(
      builder: (context, tp, _) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildTextInputSection(tp),
            const SizedBox(height: 20),
            _buildSignPreview(tp),
            if (tp.signSegments.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSegmentBreakdown(tp),
            ],
            const SizedBox(height: 20),
            _buildCurrentSignSection(tp),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputSection(TranslateProvider tp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(context).copyWith(
        borderRadius: BorderRadius.circular(20),
      ),
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
              Text(
                '${_textController.text.length}/$_maxCharacters',
                style: TextStyle(color: context.textMuted, fontSize: 11),
              ),
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
              _buildInputActionButton(
                icon: _isListening ? Icons.mic_off : Icons.mic,
                label: _isListening ? AppLocalizations.of(context).listening : AppLocalizations.of(context).voice,
                onTap: _startVoiceInput,
                isActive: _isListening,
              ),
              const SizedBox(width: 8),
              _buildInputActionButton(
                icon: Icons.delete_outline,
                label: AppLocalizations.of(context).clear,
                onTap: () {
                  _textController.clear();
                  _tp.clearTextToSign();
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TapScale(
                  onTap: _translateText,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🤟', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context).translateBtn,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSignPreview(TranslateProvider tp) {
    return Container(
      height: 480,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: tp.currentSentence.isNotEmpty
          ? SignPlayer(
              sentence: tp.currentSentence,
              key: ValueKey(tp.currentSentence.join()),
              onLoadComplete: (segments) {
                if (mounted) _tp.setSignSegments(segments);
              },
            )
          : Container(
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
        const Text('🤟', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 20),
        Text(
          _isTranslating
              ? AppLocalizations.of(context).translating
              : AppLocalizations.of(context).readyToTranslate,
          style: TextStyle(color: context.textSecondary, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildCurrentSignSection(TranslateProvider tp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).currentSign,
                style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context).englishToMsl,
                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  tp.currentSentence.isEmpty
                      ? AppLocalizations.of(context).typeSomethingToSee
                      : tp.currentSentence.join(' ').toUpperCase(),
                  style: TextStyle(
                    color: tp.currentSentence.isEmpty ? context.textMuted : context.textPrimary,
                    fontSize: 16,
                    fontWeight: tp.currentSentence.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (tp.currentSentence.isNotEmpty)
                IconButton(
                  onPressed: () => _speakCurrentSign(tp.currentSentence),
                  icon: const Icon(Icons.volume_up, color: Colors.blueAccent),
                  tooltip: AppLocalizations.of(context).speakSign,
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildSegmentBreakdown(TranslateProvider tp) {
    final segments = tp.signSegments;
    final bimCount = segments.where((s) => s.type == 'bim').length;
    final fsCount  = segments.where((s) => s.type == 'fingerspell').length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('WORD BREAKDOWN', style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const Spacer(),
              if (bimCount > 0) _buildCountBadge('$bimCount BIM', Colors.green),
              if (bimCount > 0 && fsCount > 0) const SizedBox(width: 6),
              if (fsCount > 0) _buildCountBadge('$fsCount Fingerspelled', Colors.blueAccent),
              if (segments.any((s) => s.language == 'ASL')) ...[
                const SizedBox(width: 6),
                _buildCountBadge('ASL', Colors.orange),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: segments.map((seg) {
              final Color color;
              final String emoji;
              final String tag;
              if (seg.type == 'fingerspell') {
                color = Colors.blueAccent; emoji = '✍️'; tag = '';
              } else if (seg.language == 'ASL') {
                color = Colors.orange; emoji = '🤟'; tag = ' ASL';
              } else {
                color = Colors.green; emoji = '🤟'; tag = '';
              }
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
                    Text(emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('${seg.label}$tag', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SIGN RECOGNITION LOGIC
  // ════════════════════════════════════════════════════════════════════════

  /// Called for every camera frame with server-ready landmark data.
  void _onFrame(Map<String, dynamic> frame) {
    final pose = frame['pose'] as List?;
    if (pose == null || pose.isEmpty) {
      _onStillFrame();
      return;
    }

    // Track wrist movement for still-frame counting (wrists at indices 15 & 16)
    final lw = pose.length > 15 ? pose[15] as Map? : null;
    final rw = pose.length > 16 ? pose[16] as Map? : null;
    final currentPos = [
      lw != null ? (lw['x'] as num).toDouble() : 0.0,
      lw != null ? (lw['y'] as num).toDouble() : 0.0,
      rw != null ? (rw['x'] as num).toDouble() : 0.0,
      rw != null ? (rw['y'] as num).toDouble() : 0.0,
    ];

    _frameBuffer.add(frame);
    if (_frameBuffer.length > _maxFrames) _frameBuffer.removeAt(0);

    if (_prevWristPos != null) {
      final movement = _wristMovement(currentPos, _prevWristPos!);
      if (movement < 0.015) { _onStillFrame(); } else { _stillFrameCount = 0; }
    }

    _prevWristPos = currentPos;

    final nowReady = _frameBuffer.length >= _minFrames;
    if (nowReady != _isReady && mounted) setState(() => _isReady = nowReady);
  }

  void _onStillFrame() {
    _stillFrameCount++;

    // ── Real-time auto-trigger ──────────────────────────────────────────
    // When the user holds a sign still for ~0.5s and we have enough frames,
    // automatically send to the server for matching.
    // A 2-second cooldown prevents spamming after each detection.
    if (_stillFrameCount >= _stillThreshold &&
        _frameBuffer.length >= _minFrames &&
        !_isMatching) {
      final now = DateTime.now();
      final cooldownOk = _lastMatchTime == null ||
          now.difference(_lastMatchTime!).inMilliseconds > 2000;
      if (cooldownOk) {
        _lastMatchTime = now;
        _triggerMatch();
      }
    }
  }

  void _captureSign() {
    if (_frameBuffer.length < _minFrames) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hold your sign for a moment first'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _triggerMatch();
  }

  Future<void> _triggerMatch() async {
    if (_isMatching || _frameBuffer.length < _minFrames) return;

    final framesToMatch = List<Map<String, dynamic>>.from(_frameBuffer);
    _frameBuffer.clear();
    _stillFrameCount = 0;
    _prevWristPos = null;

    if (mounted) setState(() { _isMatching = true; _isReady = false; });

    try {
      final matches = await RemoteSignService.instance.match(framesToMatch, topK: 3);
      if (!mounted) return;

      if (matches.isNotEmpty && matches.first.confidence > 0.15) {
        final word = _capitalize(matches.first.word);
        _tp.addWord(word);
        setState(() => _currentDetected = word);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _currentDetected = '');
        });
      } else {
        if (mounted) {
          final libSize = DtwService.instance.librarySize;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(matches.isEmpty 
              ? 'No matches found (Library size: $libSize)' 
              : 'Low confidence: ${matches.first.confidence.toStringAsFixed(2)}'),
          ));
        }
      }
    } catch (e) {
      debugPrint('RemoteSignService error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isMatching = false);
    }
  }

  double _wristMovement(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < min(a.length, b.length); i++) {
      sum += (a[i] - b[i]).abs();
    }
    return sum / a.length;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _startCamera() async {
    _frameBuffer.clear();
    _stillFrameCount = 0;
    _prevWristPos = null;
    _currentDetected = '';
    _isReady = false;

    // The InAppWebView in _buildWebCameraView() handles camera + MediaPipe.
    // We just need to set the state to show it.
    setState(() => _isCameraActive = true);
  }

  void _stopCamera() {
    _webViewController = null;
    _frameBuffer.clear();
    setState(() {
      _isCameraActive = false;
      _isMatching = false;
      _isReady = false;
      _currentDetected = '';
    });
  }

  // ── MediaPipe WebView handler ────────────────────────────────────────────

  void _onLandmarksFromWeb(Map<String, dynamic> data) {
    // MediaPipe Holistic sends: { pose: [...], leftHand: [...], rightHand: [...] }
    // Convert to the format expected by _onFrame: { pose, left_hand, right_hand }
    final pose = data['pose'] as List?;
    final leftHand = data['leftHand'] as List?;
    final rightHand = data['rightHand'] as List?;

    _onFrame({
      'pose': pose?.map((lm) => {'x': (lm['x'] as num).toDouble(), 'y': (lm['y'] as num).toDouble()}).toList(),
      'left_hand': leftHand?.map((lm) => {'x': (lm['x'] as num).toDouble(), 'y': (lm['y'] as num).toDouble()}).toList(),
      'right_hand': rightHand?.map((lm) => {'x': (lm['x'] as num).toDouble(), 'y': (lm['y'] as num).toDouble()}).toList(),
    });
  }

  void _speakOutput(List<String> words) async {
    final text = words.join(' ');
    if (text.isEmpty) return;
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak(text);
  }

  void _speakCurrentSign(List<String> sentence) async {
    if (sentence.isNotEmpty) {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.speak(sentence.join(' '));
    }
  }

  void _copyOutput(List<String> words) {
    final text = words.join(' ');
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).copiedToClipboard), behavior: SnackBarBehavior.floating),
    );
  }

  void _clearOutput() {
    _tp.clearSignOutput();
    setState(() {
      _currentDetected = '';
      _frameBuffer.clear();
    });
  }

  void _startVoiceInput() async {
    if (!_isListening) {
      final messenger = ScaffoldMessenger.of(context);
      final micDeniedMsg = AppLocalizations.of(context).micAccessDenied;
      final available = await _speech.initialize(
        onStatus: (s) => debugPrint('STT status: $s'),
        onError: (e) => debugPrint('STT error: $e'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) => setState(() => _textController.text = val.recognizedWords));
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
    _tp.setSentence([_textController.text.trim()]);
    setState(() => _isTranslating = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isTranslating = false);
    });
  }

  // ── Shared widgets ───────────────────────────────────────────────────────

  Widget _buildOutputActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: context.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.textSecondary, size: 18),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputActionButton({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false}) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.red.withValues(alpha: 0.2) : context.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? Colors.red : context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.red : context.textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isActive ? Colors.red : context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
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

}
