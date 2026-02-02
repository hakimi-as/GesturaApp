import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import 'friend_profile_screen.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchByCode([String? code]) async {
    final searchCode = code ?? _codeController.text.trim();
    if (searchCode.isEmpty) {
      setState(() => _error = 'Please enter a friend code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(searchCode)
          .get();

      if (!userDoc.exists) {
        if (mounted) {
          setState(() {
            _error = 'User not found. Check the code and try again.';
            _isLoading = false;
          });
        }
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (searchCode == authProvider.userId) {
        if (mounted) {
          setState(() {
            _error = 'You cannot add yourself as a friend!';
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FriendProfileScreen(friendId: searchCode),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _handleQRCodeScanned(String code) {
    // Parse the QR code data
    // Expected format: gestura://add-friend/{userId}
    String? userId;
    
    if (code.startsWith('gestura://add-friend/')) {
      userId = code.replaceFirst('gestura://add-friend/', '');
    } else if (code.length >= 20 && !code.contains(' ')) {
      // Assume it's a raw user ID (Firebase IDs are typically 20+ chars)
      userId = code;
    }

    if (userId != null && userId.isNotEmpty) {
      HapticService.success();
      _searchByCode(userId);
    } else {
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid QR code format'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Friend',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: context.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Scan QR'),
                Tab(text: 'My QR'),
                Tab(text: 'Enter Code'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScanQRTab(),
                _buildMyQRCodeTab(),
                _buildEnterCodeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SCAN QR TAB ====================
  Widget _buildScanQRTab() {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Instructions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withAlpha(50)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Friend\'s QR Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Point your camera at their QR code to add them',
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
        
        const SizedBox(height: 20),
        
        // QR Scanner
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.borderColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Scanner
                  _QRScannerWidget(
                    onScanned: _handleQRCodeScanned,
                  ),
                  
                  // Overlay with scanning frame
                  _buildScannerOverlay(),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
        ),
        
        // Loading indicator
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Finding user...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Dark overlay with transparent center
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ],
              ),
            ),
          ),
          
          // Scanning line animation
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: _ScanningLineAnimation(),
            ),
          ),
          
          // Bottom instruction
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Align QR code within frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: !isTop ? 0 : null,
      left: isLeft ? 0 : null,
      right: !isLeft ? 0 : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ==================== MY QR CODE TAB ====================
  Widget _buildMyQRCodeTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userId = user?.id ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // QR Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.borderColor),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile Info
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                    ),
                    image: user?.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(user!.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user?.photoUrl == null
                      ? Center(
                          child: Text(
                            user?.initials ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Level ${user?.level ?? 1}',
                  style: TextStyle(color: context.textMuted),
                ),
                const SizedBox(height: 24),
                
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(20),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: 'gestura://add-friend/$userId',
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF6366F1),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Let friends scan this code to add you',
                  style: TextStyle(color: context.textMuted),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
          
          const SizedBox(height: 24),
          
          // Friend Code Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tag, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'My Friend Code',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          userId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userId));
                          HapticService.lightTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Friend code copied!'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  // ==================== ENTER CODE TAB ====================
  Widget _buildEnterCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
          
          const SizedBox(height: 24),
          
          Text(
            'Enter Friend Code',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Ask your friend for their code or scan their QR',
            style: TextStyle(color: context.textMuted),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),
          
          const SizedBox(height: 32),
          
          // Input Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'Paste friend code here',
                    hintStyle: TextStyle(color: context.textMuted),
                    prefixIcon: Icon(Icons.tag, color: context.textMuted),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste_rounded, color: AppColors.primary),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _codeController.text = data!.text!;
                          HapticService.lightTap();
                        }
                      },
                    ),
                    filled: true,
                    fillColor: context.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  onSubmitted: (_) => _searchByCode(),
                ),
                
                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 24),
          
          // Search Button
          GestureDetector(
            onTap: _isLoading ? null : () => _searchByCode(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [context.textMuted, context.textMuted]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withAlpha(60),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  else
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Find Friend',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 40),
          
          // Tips
          Container(
            padding: const EdgeInsets.all(16),
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
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Tips',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip('Use the Scan QR tab to scan a friend\'s QR code'),
                _buildTip('Friend codes are case-sensitive'),
                _buildTip('You can also search by name in the Friends tab'),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== QR SCANNER WIDGET ====================

class _QRScannerWidget extends StatefulWidget {
  final Function(String) onScanned;

  const _QRScannerWidget({required this.onScanned});

  @override
  State<_QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<_QRScannerWidget> {
  MobileScannerController? _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      
      if (code != null && code.isNotEmpty) {
        setState(() => _hasScanned = true);
        
        widget.onScanned(code);
        
        // Reset after 2 seconds to allow scanning again
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _hasScanned = false);
          }
        });
        
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return _buildCameraError(error);
          },
        ),
        
        // Flash toggle
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller!,
              builder: (context, state, child) {
                final torchState = state.torchState;
                return IconButton(
                  icon: Icon(
                    torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: () => _controller?.toggleTorch(),
                );
              },
            ),
          ),
        ),
        
        // Camera switch
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
              onPressed: () => _controller?.switchCamera(),
            ),
          ),
        ),
        
        // Scanning success indicator
        if (_hasScanned)
          Container(
            color: Colors.green.withAlpha(100),
            child: const Center(
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 80,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    String message;
    
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = 'Camera permission denied. Please enable it in settings.';
        break;
      case MobileScannerErrorCode.unsupported:
        message = 'Camera not supported on this device.';
        break;
      default:
        message = 'Unable to initialize camera. Please try again.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Camera Access Required',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _controller?.start();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SCANNING LINE ANIMATION ====================

class _ScanningLineAnimation extends StatefulWidget {
  @override
  State<_ScanningLineAnimation> createState() => _ScanningLineAnimationState();
}

class _ScanningLineAnimationState extends State<_ScanningLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Align(
            alignment: Alignment(0, -1 + 2 * _animation.value),
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primary,
                    AppColors.primary,
                    Colors.transparent,
                  ],
                  stops: [0, 0.2, 0.8, 1],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(150),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}