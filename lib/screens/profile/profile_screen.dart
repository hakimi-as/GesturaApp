import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/design_system.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  String _selectedSignLanguage = 'BIM';
  String _selectedUserType = AppConstants.userTypeLearner;
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Profile image bytes
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imageBase64 = prefs.getString('profileImageBase64');
      
      if (imageBase64 != null && imageBase64.isNotEmpty && mounted) {
        setState(() {
          _profileImageBytes = base64Decode(imageBase64);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading profile image: $e');
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _nameController.text = user.fullName;
      _selectedSignLanguage = user.preferredSignLanguage ?? 'BIM';
      _selectedUserType = user.userType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.userId != null) {
        await _firestoreService.updateUser(authProvider.userId!, {
          'fullName': _nameController.text.trim(),
          'preferredSignLanguage': _selectedSignLanguage,
          'userType': _selectedUserType,
        });

        // Reload user data
        await authProvider.refreshUser();

        if (mounted) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).profileUpdated),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save profile. Please check your connection and try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(AppLocalizations.of(context).myProfile),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(Icons.settings_outlined, color: context.textMuted),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => setState(() => _isEditing = true),
            ),
          ] else
            IconButton(
              icon: Icon(Icons.close, color: context.textMuted),
              onPressed: () {
                setState(() => _isEditing = false);
                _loadUserData();
              },
            ),
        ],
      ),
      body: Consumer2<AuthProvider, ProgressProvider>(
        builder: (context, authProvider, progressProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return Center(child: Text(AppLocalizations.of(context).noUserData));
          }

          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero: centered avatar + name + pills
                  _buildAvatarSection(context, user),
                  const SizedBox(height: 16),
                  // 3-col stats grid
                  _buildStatsCard(context, user, progressProvider),
                  const SizedBox(height: 20),
                  // Profile section label
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Text(
                      'PROFILE',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: context.textMuted,
                      ),
                    ),
                  ),
                  _buildUserInfoCard(context, user),
                  const SizedBox(height: 20),
                  // Preferences section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Text(
                      'PREFERENCES',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: context.textMuted,
                      ),
                    ),
                  ),
                  _buildPreferencesCard(context),
                  const SizedBox(height: 20),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSaveButton(),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, user) {
    final hasPhotoUrl = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;
    final initials = user?.initials ?? 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.5),
                ),
                child: ClipOval(
                  child: hasPhotoUrl
                      ? Image.network(
                          CloudinaryService.getOptimizedImage(user.photoUrl!, width: 144, height: 144),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            if (_profileImageBytes != null) {
                              return Image.memory(_profileImageBytes!, fit: BoxFit.cover);
                            }
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          },
                          errorBuilder: (context, error, stackTrace) {
                            if (_profileImageBytes != null) {
                              return Image.memory(_profileImageBytes!, fit: BoxFit.cover);
                            }
                            return _buildInitialsAvatar(initials);
                          },
                        )
                      : _profileImageBytes != null
                          ? Image.memory(_profileImageBytes!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildInitialsAvatar(initials))
                          : _buildInitialsAvatar(initials),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.bgPrimary, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Name
          Text(
            user?.fullName ?? '',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: context.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          // Pills: Level + Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProfilePill('🔥 ${user?.currentStreak ?? 0} Streak', AppColors.success, AppColors.success),
              const SizedBox(width: 6),
              _buildProfilePill('Lv ${user?.level ?? 1}', AppColors.primary, AppColors.primary),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildProfilePill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06 * 9,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          _buildProfileFieldRow(
            context,
            icon: '👤',
            label: AppLocalizations.of(context).fullName,
            valueWidget: _isEditing
                ? TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context).pleaseEnterName;
                      }
                      return null;
                    },
                  )
                : Text(
                    user.fullName,
                    style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                  ),
            showChevron: !_isEditing,
            showDivider: true,
          ),
          _buildProfileFieldRow(
            context,
            icon: '✉️',
            label: AppLocalizations.of(context).email,
            valueWidget: Text(
              user.email,
              style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w600, color: context.textMuted),
            ),
            showChevron: false,
            showDivider: true,
          ),
          _buildProfileFieldRow(
            context,
            icon: '🧑‍🤝‍🧑',
            label: AppLocalizations.of(context).iAmA,
            valueWidget: _isEditing
                ? _buildUserTypeSelector()
                : Text(
                    _getUserTypeDisplay(_selectedUserType),
                    style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                  ),
            showChevron: !_isEditing,
            showDivider: false,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildProfileFieldRow(
    BuildContext context, {
    required String icon,
    required String label,
    required Widget valueWidget,
    required bool showChevron,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 9, color: context.textMuted, height: 1.2)),
                    const SizedBox(height: 1),
                    valueWidget,
                  ],
                ),
              ),
              if (showChevron)
                Text('›', style: TextStyle(fontSize: 16, color: context.textMuted)),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: context.borderColor),
      ],
    );
  }

  Widget _buildUserTypeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildTypeChip('Learner', AppConstants.userTypeLearner),
        _buildTypeChip('Deaf/HoH', AppConstants.userTypeDeaf),
        _buildTypeChip('Educator', AppConstants.userTypeEducator),
      ],
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _selectedUserType == value;
    return TapScale(
      onTap: () => setState(() => _selectedUserType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : context.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : context.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, user, ProgressProvider progressProvider) {
    final totalXp = user?.totalXP ?? 0;
    final lessons = user?.lessonsCompleted ?? 0;
    final streak = user?.currentStreak ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildStatCell(context, value: '$totalXp', label: 'Total XP')),
            VerticalDivider(color: context.borderColor, width: 1, thickness: 1),
            Expanded(child: _buildStatCell(context, value: '$lessons', label: 'Lessons')),
            VerticalDivider(color: context.borderColor, width: 1, thickness: 1),
            Expanded(child: _buildStatCell(context, value: '$streak', label: 'Streak')),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatCell(BuildContext context, {required String value, required String label}) {
    return Container(
      color: context.bgCard,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.04 * 22,
              color: context.textPrimary,
              height: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 8, color: context.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: _buildProfileFieldRow(
        context,
        icon: '🤟',
        label: AppLocalizations.of(context).preferredSignLanguage,
        valueWidget: _isEditing
            ? _buildSignLanguageSelector()
            : Text(
                _getSignLanguageDisplay(_selectedSignLanguage),
                style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
        showChevron: !_isEditing,
        showDivider: false,
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSignLanguageSelector() {
    return Wrap(
      spacing: 8,
      children: AppConstants.supportedSignLanguages.map((lang) {
        final isSelected = _selectedSignLanguage == lang['code'];
        return TapScale(
          onTap: () => setState(() => _selectedSignLanguage = lang['code']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : context.bgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Text(
              lang['code']!,
              style: TextStyle(
                color: isSelected ? AppColors.primary : context.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                AppLocalizations.of(context).save,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  String _getUserTypeDisplay(String type) {
    switch (type) {
      case 'learner':
        return 'Learner';
      case 'deaf':
        return 'Deaf/Hard of Hearing';
      case 'educator':
        return 'Educator';
      default:
        return type;
    }
  }

  String _getSignLanguageDisplay(String code) {
    final lang = AppConstants.supportedSignLanguages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'name': code},
    );
    return lang['name'] ?? code;
  }
}
