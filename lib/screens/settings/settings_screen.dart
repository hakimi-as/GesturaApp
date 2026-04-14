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
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/haptic_service.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/share/share_progress_card.dart';
import '../../widgets/gamification/streak_freeze_widgets.dart';
import '../../widgets/common/glass_ui.dart';

// --- Phase 2 Integration: Import ---
import '../../widgets/offline/offline_settings_widgets.dart';

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
                ? AppLocalizations.of(context).profileSavedCloud
                : AppLocalizations.of(context).profileSavedLocally),
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
      isScrollControlled: true,
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
                AppLocalizations.of(context).changeProfilePicture,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              _buildImageOption(
                icon: Icons.camera_alt,
                label: AppLocalizations.of(context).takePhoto,
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
                label: AppLocalizations.of(context).chooseFromGallery,
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
                  label: AppLocalizations.of(context).removePhoto,
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
                          content: Text(AppLocalizations.of(context).profilePhotoRemoved),
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
        title: Row(
          children: [
            const Icon(Icons.ac_unit, color: Color(0xFF0EA5E9), size: 24),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(ctx).buyStreakFreeze),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(ctx).streakFreezeDesc,
              style: TextStyle(color: context.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(ctx).cost),
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
                Text(AppLocalizations.of(ctx).youHave),
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
            child: Text(AppLocalizations.of(ctx).cancel),
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
            child: Text(AppLocalizations.of(ctx).buyFreeze),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          GlassIconButton(
            icon: Icons.settings,
            iconColor: AppColors.primary,
            size: 44,
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context).settingsTitle,
            style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 28,
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
          child: GlassCard(
          padding: const EdgeInsets.all(20),
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
                          width: 2.5,
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
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context).uploading,
                                  style: const TextStyle(
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
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'user@gestura.app',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 14,
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
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: kGlassRadius,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).editProfile,
                          style: const TextStyle(
                            color: AppColors.primary,
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
                  icon: Icons.local_fire_department_rounded,
                  value: '${user?.currentStreak ?? 0}',
                  label: AppLocalizations.of(context).dayStreakLabel,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rounded,
                  value: _formatNumber(user?.totalXP ?? 0),
                  label: AppLocalizations.of(context).totalXP,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events_rounded,
                  value: '${user?.totalBadges ?? 0}',
                  label: AppLocalizations.of(context).badgesLabel,
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
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: context.glassCardDecoration(),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: kGlassRadius,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
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
                        content: Text(AppLocalizations.of(context).streakFreezePurchased),
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
                        content: Text(result['error'] ?? AppLocalizations.of(context).purchaseFailed),
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
        _buildSectionTitle(AppLocalizations.of(context).general),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              GlassTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(30),
                    borderRadius: kGlassRadius,
                  ),
                  child: const Icon(Icons.notifications_outlined, color: Color(0xFF6366F1), size: 20),
                ),
                title: Text(AppLocalizations.of(context).notifications),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    HapticService.toggle();
                    setState(() => _notificationsEnabled = value);
                    _saveSettings();
                  },
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withAlpha(128),
                ),
              ),
              const SizedBox(height: 8),
              GlassTile(
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(30),
                    borderRadius: kGlassRadius,
                  ),
                  child: const Icon(Icons.tune, color: Color(0xFFF59E0B), size: 20),
                ),
                title: Text(AppLocalizations.of(context).notificationSettings),
                trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 20),
              ),
              const SizedBox(height: 8),
              GlassTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(30),
                    borderRadius: kGlassRadius,
                  ),
                  child: const Icon(Icons.volume_up_outlined, color: Color(0xFF10B981), size: 20),
                ),
                title: Text(AppLocalizations.of(context).soundEffects),
                trailing: Switch(
                  value: _soundEnabled,
                  onChanged: (value) {
                    HapticService.toggle();
                    setState(() => _soundEnabled = value);
                    _saveSettings();
                  },
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withAlpha(128),
                ),
              ),
              const SizedBox(height: 8),
              GlassTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(30),
                    borderRadius: kGlassRadius,
                  ),
                  child: const Icon(Icons.vibration, color: Color(0xFFEF4444), size: 20),
                ),
                title: Text(AppLocalizations.of(context).vibration),
                trailing: Switch(
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    HapticService.toggle();
                    setState(() => _vibrationEnabled = value);
                    _saveSettings();
                  },
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withAlpha(128),
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
        _buildSectionTitle(AppLocalizations.of(context).preferences),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) => GlassTile(
                  onTap: () => _showLanguageSelector(),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withAlpha(30),
                      borderRadius: kGlassRadius,
                    ),
                    child: const Icon(Icons.language, color: Color(0xFF3B82F6), size: 20),
                  ),
                  title: Text(AppLocalizations.of(context).language),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localeProvider.displayName,
                        style: TextStyle(color: context.textMuted, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, color: context.textMuted, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GlassTile(
                onTap: () => _showSignLanguageSelector(),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withAlpha(30),
                    borderRadius: kGlassRadius,
                  ),
                  child: const Icon(Icons.sign_language, color: Color(0xFFEC4899), size: 20),
                ),
                title: Text(AppLocalizations.of(context).signLanguage),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedSignLanguage,
                      style: TextStyle(color: context.textMuted, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: context.textMuted, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.currentUser;
                  if (user == null) return const SizedBox.shrink();
                  return GlassTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withAlpha(30),
                        borderRadius: kGlassRadius,
                      ),
                      child: const Icon(Icons.ac_unit, color: Color(0xFF0EA5E9), size: 20),
                    ),
                    title: Text(AppLocalizations.of(context).autoUseFreeze),
                    trailing: Switch(
                      value: user.autoUseFreeze,
                      onChanged: (value) async {
                        HapticService.toggle();
                        await _firestoreService.setAutoUseFreeze(user.id, value);
                        await authProvider.refreshUser();
                      },
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withAlpha(128),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              GlassTile(
                onTap: () {
                  HapticService.buttonTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                  );
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(30),
                    borderRadius: kGlassRadius,
                  ),
                  child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF8B5CF6), size: 20),
                ),
                title: Text(AppLocalizations.of(context).appearance),
                trailing: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final l10n = AppLocalizations.of(context);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeProvider.themeMode == AppThemeMode.dark
                              ? l10n.dark
                              : themeProvider.themeMode == AppThemeMode.light
                                  ? l10n.light
                                  : l10n.system,
                          style: TextStyle(color: context.textMuted, fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: context.textMuted, size: 20),
                      ],
                    );
                  },
                ),
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
              _buildSectionTitle(AppLocalizations.of(context).adminSection),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassTile(
                  onTap: () {
                    HapticService.buttonTap();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(30),
                      borderRadius: kGlassRadius,
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Color(0xFF6366F1), size: 20),
                  ),
                  title: Text(AppLocalizations.of(context).adminPanel),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(30),
                      borderRadius: kGlassRadius,
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
                        Icon(Icons.chevron_right, color: Color(0xFF6366F1), size: 18),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),
            ],

            _buildSectionTitle(AppLocalizations.of(context).accountSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GlassTile(
                    onTap: () {
                      HapticService.buttonTap();
                      final ap = Provider.of<AuthProvider>(context, listen: false);
                      if (ap.currentUser != null) {
                        showShareProgressSheet(context, ap.currentUser!);
                      }
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(30),
                        borderRadius: kGlassRadius,
                      ),
                      child: const Icon(Icons.share_outlined, color: Color(0xFF10B981), size: 20),
                    ),
                    title: Text(AppLocalizations.of(context).shareProgress),
                    trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 20),
                  ),
                  const SizedBox(height: 8),
                  GlassTile(
                    onTap: () => _showAboutDialog(),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(30),
                        borderRadius: kGlassRadius,
                      ),
                      child: const Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 20),
                    ),
                    title: Text(AppLocalizations.of(context).about),
                    trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 20),
                  ),
                  const SizedBox(height: 8),
                  // Sign out — custom outlined tile with error border
                  GestureDetector(
                    onTap: () => _showLogoutConfirmation(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: kGlassRadius,
                        border: Border.all(color: AppColors.error, width: 1.5),
                        color: AppColors.error.withAlpha(15),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(30),
                              borderRadius: kGlassRadius,
                            ),
                            child: const Icon(Icons.logout, color: AppColors.error, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).logOut,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.error, size: 20),
                        ],
                      ),
                    ),
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
      child: GlassSectionHeader(title: title),
    );
  }

  void _showLanguageSelector() {
    HapticService.buttonTap();
    final l10n = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languages = LocaleProvider.supportedLanguages;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                l10n.selectLanguage,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ...languages.map((lang) {
              final isSelected = localeProvider.languageCode == lang['code'];
              return ListTile(
                leading: Text(
                  lang['code'] == 'ms' ? '🇲🇾' : '🇬🇧',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(lang['name']!),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  HapticService.selectionClick();
                  localeProvider.setLocaleByCode(lang['code']!);
                  setState(() => _selectedLanguage = lang['name']!);
                  _saveSettings();
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSignLanguageSelector() {
    HapticService.buttonTap();
    final languages = ['ASL', 'BSL', 'Auslan', 'ISL', 'JSL', 'MSL'];

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSelectorSheet(
        title: AppLocalizations.of(context).selectSignLanguage,
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
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
            Icon(Icons.sign_language, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Text('Gestura'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).aboutVersion,
              style: TextStyle(color: context.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).aboutDescription,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).aboutCopyright,
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
            child: Text(AppLocalizations.of(context).close),
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
        title: Text(AppLocalizations.of(context).logOutQuestion),
        content: Text(AppLocalizations.of(context).logOutMessage),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.pop(dialogContext);
            },
            child: Text(AppLocalizations.of(context).cancel),
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
            child: Text(AppLocalizations.of(context).logOut),
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