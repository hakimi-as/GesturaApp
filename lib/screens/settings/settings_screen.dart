import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_settings_screen.dart';
import 'theme_settings_screen.dart';

import '../../providers/theme_provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/haptic_service.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/share/share_progress_card.dart';
import '../../widgets/streak_freeze_widgets.dart';

// --- Phase 2 Integration: Import ---
import '../../widgets/offline_settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  
  Uint8List? _profileImageBytes;
  bool _isLoadingImage = false;
  bool _isUploadingImage = false;

  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedSignLanguage = 'ASL';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    Uint8List? imageBytes;
    final user = authProvider.currentUser;
    
    if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      try {
        final cachedBase64 = prefs.getString('profileImageBase64');
        final cachedUrl = prefs.getString('profileImageUrl');
        
        if (cachedUrl == user.photoUrl && cachedBase64 != null) {
          imageBytes = base64Decode(cachedBase64);
        } else {
          await prefs.setString('profileImageUrl', user.photoUrl!);
        }
      } catch (e) {
        debugPrint('Error loading profile image from URL: $e');
      }
    } else {
      final imageBase64 = prefs.getString('profileImageBase64');
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          imageBytes = base64Decode(imageBase64);
        } catch (e) {
          debugPrint('Error decoding profile image: $e');
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications') ?? true;
        _soundEnabled = prefs.getBool('sound') ?? true;
        _vibrationEnabled = prefs.getBool('vibration') ?? true;
        _selectedLanguage = prefs.getString('language') ?? 'English';
        _selectedSignLanguage = prefs.getString('signLanguage') ?? 'ASL';
        _profileImageBytes = imageBytes;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('sound', _soundEnabled);
    await prefs.setBool('vibration', _vibrationEnabled);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('signLanguage', _selectedSignLanguage);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoadingImage = true);
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        
        setState(() {
          _profileImageBytes = bytes;
          _isUploadingImage = true;
        });

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? photoUrl;
        
        try {
          final result = await CloudinaryService.uploadImage(
            image,
            folder: 'gestura/profiles',
          );
          if (result != null) {
            photoUrl = result.secureUrl;
          }
        } catch (e) {
          debugPrint('Error uploading to Cloudinary: $e');
        }

        if (mounted) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profileImageBase64', base64Encode(bytes));
          
          if (photoUrl != null && authProvider.userId != null) {
            await _firestoreService.updateUser(
              authProvider.userId!,
              {'photoUrl': photoUrl},
            );
            await prefs.setString('profileImageUrl', photoUrl);
            await authProvider.refreshUser();
          }

          setState(() => _isUploadingImage = false);

          HapticService.success();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(photoUrl != null 
                ? '✓ Profile picture saved to cloud' 
                : '✓ Profile picture saved locally'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        setState(() => _isUploadingImage = false);
        HapticService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  void _showImagePickerOptions() {
    HapticService.buttonTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Change Profile Picture',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              _buildImageOption(
                icon: Icons.camera_alt,
                label: 'Take Photo',
                color: const Color(0xFF6366F1),
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),

              _buildImageOption(
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                color: const Color(0xFF10B981),
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              if (_profileImageBytes != null || (Provider.of<AuthProvider>(context, listen: false).currentUser?.photoUrl != null)) ...[
                const SizedBox(height: 12),
                _buildImageOption(
                  icon: Icons.delete_outline,
                  label: 'Remove Photo',
                  color: AppColors.error,
                  onTap: () async {
                    HapticService.buttonTap();
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('profileImageBase64');
                    await prefs.remove('profileImageUrl');
                    
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (authProvider.userId != null) {
                      await _firestoreService.updateUser(
                        authProvider.userId!,
                        {'photoUrl': null},
                      );
                      await authProvider.refreshUser();
                    }
                    
                    if (mounted) {
                      setState(() {
                        _profileImageBytes = null;
                      });
                      HapticService.success();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✓ Profile photo removed'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showBuyConfirmation(BuildContext context, int cost, int userXp) {
    HapticService.buttonTap();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🧊', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Text('Buy Streak Freeze?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protect your streak for one day if you miss a lesson.',
              style: TextStyle(color: context.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cost:'),
                Text(
                  '$cost XP',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('You have:'),
                Text(
                  '$userXp XP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: userXp >= cost ? context.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.pop(ctx, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: userXp >= cost 
              ? () {
                  HapticService.buttonTap();
                  Navigator.pop(ctx, true);
                }
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buy Freeze'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildProfileCard(),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildStreakCard(),
              _buildGeneralSection(),
              _buildPreferencesSection(),

              // --- Phase 2: Offline Settings Section ---
              // Shows cache size, cleared videos, and sync status
              const OfflineSettingsSection(),
              // -----------------------------------------

              _buildAccountSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Icon(
              Icons.settings,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildProfileCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                    ),
                    ClipOval(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: _isLoadingImage
                            ? Container(
                                color: context.bgElevated,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : user?.photoUrl != null
                                ? Image.network(
                                    CloudinaryService.getOptimizedImage(user!.photoUrl!, width: 160, height: 160),
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      if (_profileImageBytes != null) {
                                        return Image.memory(_profileImageBytes!, fit: BoxFit.cover);
                                      }
                                      return Container(
                                        color: context.bgElevated,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      if (_profileImageBytes != null) {
                                        return Image.memory(_profileImageBytes!, fit: BoxFit.cover);
                                      }
                                      return _buildDefaultAvatar(user.initials);
                                    },
                                  )
                                : _profileImageBytes != null
                                    ? Image.memory(
                                        _profileImageBytes!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildDefaultAvatar(user?.initials ?? 'U');
                                        },
                                      )
                                    : _buildDefaultAvatar(user?.initials ?? 'U'),
                      ),
                    ),
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Uploading...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.bgCard, width: 2),
                        ),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 14,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Learner',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'user@gestura.app',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.textMuted,
                          ),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () {
                        HapticService.buttonTap();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildDefaultAvatar(String initials) {
    return Container(
      color: context.bgElevated,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  emoji: '🔥',
                  value: '${user?.currentStreak ?? 0}',
                  label: 'Day Streak',
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  emoji: '⭐',
                  value: _formatNumber(user?.totalXP ?? 0),
                  label: 'Total XP',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  emoji: '🏆',
                  value: '${user?.totalBadges ?? 0}',
                  label: 'Badges',
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms);
      },
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textMuted,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreakFreezeCard(
            freezeCount: user.streakFreezes,
            currentStreak: user.currentStreak,
            onBuyFreeze: () async {
              final confirm = await _showBuyConfirmation(context, 500, user.totalXP);
              if (confirm == true) {
                final result = await _firestoreService.buyStreakFreeze(user.id);
                if (mounted) {
                  if (result['success']) {
                    HapticService.achievement();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✓ Streak freeze purchased!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      )
                    );
                    await authProvider.refreshUser();
                  } else {
                    HapticService.error();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error'] ?? 'Purchase failed'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      )
                    );
                  }
                }
              }
            },
            onLearnMore: () {
              HapticService.buttonTap();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => const StreakFreezeModal(),
              );
            },
          ),
        ).animate().fadeIn(delay: 250.ms);
      },
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('GENERAL'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    HapticService.toggle();
                    setState(() => _notificationsEnabled = value);
                    _saveSettings();
                  },
                  activeTrackColor: AppColors.primary.withAlpha(128),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.tune,
                iconColor: const Color(0xFFF59E0B),
                title: 'Notification Settings',
                trailing: Icon(
                  Icons.chevron_right,
                  color: context.textMuted,
                  size: 20,
                ),
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.volume_up_outlined,
                iconColor: const Color(0xFF10B981),
                title: 'Sound Effects',
                trailing: Switch(
                  value: _soundEnabled,
                  onChanged: (value) {
                    HapticService.toggle();
                    setState(() => _soundEnabled = value);
                    _saveSettings();
                  },
                  activeTrackColor: AppColors.primary.withAlpha(128),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.vibration,
                iconColor: const Color(0xFFEF4444),
                title: 'Vibration',
                trailing: Switch(
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    HapticService.toggle();
                    setState(() => _vibrationEnabled = value);
                    _saveSettings();
                  },
                  activeTrackColor: AppColors.primary.withAlpha(128),
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PREFERENCES'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.language,
                iconColor: const Color(0xFF3B82F6),
                title: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedLanguage,
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: context.textMuted,
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _showLanguageSelector(),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.sign_language,
                iconColor: const Color(0xFFEC4899),
                title: 'Sign Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedSignLanguage,
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: context.textMuted,
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _showSignLanguageSelector(),
              ),
              _buildDivider(),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.currentUser;
                  if (user == null) return const SizedBox.shrink();
                  
                  return _buildSettingsTile(
                    icon: Icons.ac_unit,
                    iconColor: const Color(0xFF0EA5E9),
                    title: 'Auto-use Freeze',
                    trailing: Switch(
                      value: user.autoUseFreeze,
                      onChanged: (value) async {
                        HapticService.toggle();
                        await _firestoreService.setAutoUseFreeze(user.id, value);
                        await authProvider.refreshUser();
                      },
                      activeTrackColor: AppColors.primary.withAlpha(128),
                      activeThumbColor: AppColors.primary,
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Appearance',
                trailing: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeProvider.themeMode == AppThemeMode.dark
                              ? 'Dark'
                              : themeProvider.themeMode == AppThemeMode.light
                                  ? 'Light'
                                  : 'System',
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: context.textMuted,
                          size: 20,
                        ),
                      ],
                    );
                  },
                ),
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final isAdmin = user?.isAdmin ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdmin) ...[
              _buildSectionTitle('ADMIN'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6366F1).withAlpha(100)),
                ),
                child: _buildSettingsTile(
                  icon: Icons.admin_panel_settings,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Admin Panel',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: Color(0xFF6366F1),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    HapticService.buttonTap();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 450.ms),
            ],

            _buildSectionTitle('ACCOUNT'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.share_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'Share Progress',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: context.textMuted,
                      size: 20,
                    ),
                    onTap: () {
                      HapticService.buttonTap();
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.currentUser != null) {
                        showShareProgressSheet(context, authProvider.currentUser!);
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF6366F1),
                    title: 'About',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: context.textMuted,
                      size: 20,
                    ),
                    onTap: () => _showAboutDialog(),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    icon: Icons.logout,
                    iconColor: AppColors.error,
                    title: 'Log Out',
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onTap: () => _showLogoutConfirmation(),
                    textColor: AppColors.error,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          color: context.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? context.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: context.borderColor,
      height: 1,
      indent: 70,
    );
  }

  void _showLanguageSelector() {
    HapticService.buttonTap();
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese'];

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSelectorSheet(
        title: 'Select Language',
        options: languages,
        selectedOption: _selectedLanguage,
        onSelect: (value) {
          HapticService.selectionClick();
          setState(() => _selectedLanguage = value);
          _saveSettings();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSignLanguageSelector() {
    HapticService.buttonTap();
    final languages = ['ASL', 'BSL', 'Auslan', 'ISL', 'JSL', 'MSL'];

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSelectorSheet(
        title: 'Select Sign Language',
        options: languages,
        selectedOption: _selectedSignLanguage,
        onSelect: (value) {
          HapticService.selectionClick();
          setState(() => _selectedSignLanguage = value);
          _saveSettings();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSelectorSheet({
    required String title,
    required List<String> options,
    required String selectedOption,
    required Function(String) onSelect,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ...options.map((option) => ListTile(
                  title: Text(option),
                  trailing: selectedOption == option
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () => onSelect(option),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    HapticService.buttonTap();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🤟', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text('Gestura'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(color: context.textMuted),
            ),
            const SizedBox(height: 12),
            const Text(
              'Gestura is a sign language learning app designed to help you communicate better through sign language.',
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 Gestura Team',
              style: TextStyle(color: context.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    HapticService.buttonTap();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticService.buttonTap();
              Navigator.pop(dialogContext);
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }
}