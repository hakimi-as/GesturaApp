import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';

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
  
  bool _isCameraActive = false;
  bool _isTranslating = false;
  String _translationOutput = '';
  String _currentSign = '';
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
                    child: const Icon(
                      Icons.translate,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Translate'),
                ],
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Header (only show if no AppBar)
            if (!canPop) _buildHeader(),

            // Tab Switcher
            _buildTabSwitcher(),

            // Content
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
            child: const Icon(
              Icons.translate,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Translate',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _tabController.index == 0
                      ? const Color(0xFF3B82F6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '👋',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sign → Text',
                      style: TextStyle(
                        color: _tabController.index == 0
                            ? Colors.white
                            : context.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _tabController.index == 1
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '📝',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Text → Sign',
                      style: TextStyle(
                        color: _tabController.index == 1
                            ? Colors.white
                            : context.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ==================== SIGN TO TEXT TAB ====================

  Widget _buildSignToTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Camera Preview Area
          _buildCameraPreview(),
          const SizedBox(height: 20),

          // Translation Output Section
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
        border: Border.all(
          color: AppColors.primary.withAlpha(50),
          width: 1,
        ),
      ),
      child: _isCameraActive
          ? _buildActiveCameraView()
          : _buildCameraPlaceholder(),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildCameraPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Camera Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.camera_alt_outlined,
            color: context.textMuted,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        
        // Instruction Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Point your camera at sign language gestures to translate them in real-time',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Start Camera Button
        GestureDetector(
          onTap: _startCamera,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withAlpha(80),
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
                const Text(
                  'Start Camera',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
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
        // Camera would be here
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam,
                color: AppColors.primary,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera Active',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Show a sign to translate',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Stop Camera Button
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
                    Icon(Icons.stop, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Stop Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRANSLATION OUTPUT',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ASL → English',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Output Text
          Text(
            _translationOutput.isEmpty
                ? 'Waiting for gestures...'
                : _translationOutput,
            style: TextStyle(
              color: _translationOutput.isEmpty
                  ? context.textMuted
                  : context.textPrimary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              _buildOutputActionButton(
                icon: Icons.volume_up,
                label: 'Speak',
                onTap: _speakOutput,
              ),
              const SizedBox(width: 10),
              _buildOutputActionButton(
                icon: Icons.copy,
                label: 'Copy',
                onTap: _copyOutput,
              ),
              const SizedBox(width: 10),
              _buildOutputActionButton(
                icon: Icons.delete_outline,
                label: 'Clear',
                onTap: _clearOutput,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildOutputActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TEXT TO SIGN TAB ====================

  Widget _buildTextToSignTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Text Input Section
          _buildTextInputSection(),
          const SizedBox(height: 20),

          // Sign Animation Preview
          _buildSignPreview(),
          const SizedBox(height: 20),

          // Current Sign Section
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENTER TEXT',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${_textController.text.length}/$_maxCharacters',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Text Field
          TextField(
            controller: _textController,
            maxLength: _maxCharacters,
            maxLines: 3,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Type or speak text to translate into sign language...',
              hintStyle: TextStyle(
                color: context.textMuted,
                fontSize: 14,
              ),
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              _buildInputActionButton(
                icon: Icons.mic,
                label: 'Voice',
                onTap: _startVoiceInput,
              ),
              const SizedBox(width: 10),
              _buildInputActionButton(
                icon: Icons.delete_outline,
                label: 'Clear',
                onTap: () {
                  _textController.clear();
                  setState(() {
                    _currentSign = '';
                  });
                },
              ),
              const Spacer(),
              // Translate Button
              GestureDetector(
                onTap: _translateText,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(80),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🤟', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      const Text(
                        'Translate',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignPreview() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hand Emoji in Circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withAlpha(100),
                  const Color(0xFF8B5CF6).withAlpha(100),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _isTranslating ? '🤟' : '🤟',
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Status Text
          Text(
            _isTranslating ? 'Translating...' : 'Ready to translate',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPreviewControlButton(
                icon: Icons.replay,
                label: 'Replay',
                onTap: _replayAnimation,
              ),
              const SizedBox(width: 12),
              _buildPreviewControlButton(
                icon: Icons.speed,
                label: '1x',
                onTap: _changeSpeed,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildPreviewControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT SIGN',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'English → ASL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current Sign Text
          Text(
            _currentSign.isEmpty
                ? 'Type something to see 3D animation'
                : _currentSign,
            style: TextStyle(
              color: _currentSign.isEmpty
                  ? context.textMuted
                  : context.textPrimary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ==================== ACTIONS ====================

  void _startCamera() {
    setState(() {
      _isCameraActive = true;
    });
    // TODO: Initialize camera
  }

  void _stopCamera() {
    setState(() {
      _isCameraActive = false;
    });
    // TODO: Stop camera
  }

  void _speakOutput() {
    if (_translationOutput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nothing to speak'),
          backgroundColor: context.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    // TODO: Text-to-speech
  }

  void _copyOutput() {
    if (_translationOutput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nothing to copy'),
          backgroundColor: context.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: _translationOutput));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Copied to clipboard'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearOutput() {
    setState(() {
      _translationOutput = '';
    });
  }

  void _startVoiceInput() {
    // TODO: Voice input
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎤 Voice input coming soon'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _translateText() {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter some text to translate'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isTranslating = true;
      _currentSign = _textController.text;
    });

    // Simulate translation
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    });
  }

  void _replayAnimation() {
    if (_currentSign.isEmpty) return;
    setState(() {
      _isTranslating = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    });
  }

  void _changeSpeed() {
    // TODO: Change animation speed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Speed control coming soon'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}