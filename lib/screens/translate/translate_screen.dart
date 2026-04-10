import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // NEW
import 'package:flutter_tts/flutter_tts.dart'; // NEW

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
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
  
  bool _isCameraActive = false;
  bool _isTranslating = false;
  String _translationOutput = '';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

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
                icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.translate, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context).navTranslate),
                ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.translate, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).navTranslate,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          _buildTabBtn(0, '👋', AppLocalizations.of(context).signToTextTab),
          _buildTabBtn(1, '📝', AppLocalizations.of(context).textToSignTab),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTabBtn(int index, String icon, String label) {
    bool isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (index == 0 ? const Color(0xFF3B82F6) : AppColors.primary) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
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

  // ==================== SIGN TO TEXT TAB ====================

  Widget _buildSignToTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildCameraPreview(),
          const SizedBox(height: 20),
          _buildTranslationOutput(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: _isCameraActive ? _buildActiveCameraView() : _buildCameraPlaceholder(),
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
                Text(AppLocalizations.of(context).startCamera, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCameraView() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, color: AppColors.primary, size: 60),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).cameraActive, style: TextStyle(color: context.textSecondary, fontSize: 16)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).showSignToTranslate, style: TextStyle(color: context.textMuted, fontSize: 14)),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _stopCamera,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stop, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).stopCamera, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationOutput() {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(AppLocalizations.of(context).aslToEnglish, style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _translationOutput.isEmpty ? AppLocalizations.of(context).waitingForGestures : _translationOutput,
            style: TextStyle(
              color: _translationOutput.isEmpty ? context.textMuted : context.textPrimary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildOutputActionButton(icon: Icons.volume_up, label: AppLocalizations.of(context).speak, onTap: _speakOutput),
              const SizedBox(width: 10),
              _buildOutputActionButton(icon: Icons.copy, label: AppLocalizations.of(context).copy, onTap: _copyOutput),
              const SizedBox(width: 10),
              _buildOutputActionButton(icon: Icons.delete_outline, label: AppLocalizations.of(context).clear, onTap: _clearOutput),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🤟', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).translateBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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
          child: Center(
            child: Text(_isTranslating ? '🤟' : '🤟', style: const TextStyle(fontSize: 50)),
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
                  icon: const Icon(Icons.volume_up, color: Colors.blueAccent),
                  tooltip: AppLocalizations.of(context).speakSign,
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ==================== ACTIONS ====================

  void _startCamera() {
    setState(() => _isCameraActive = true);
  }

  void _stopCamera() {
    setState(() => _isCameraActive = false);
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
    setState(() => _translationOutput = '');
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
                    Text(
                      isBim ? '🤟' : '✍️',
                      style: const TextStyle(fontSize: 12),
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
          color: context.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}