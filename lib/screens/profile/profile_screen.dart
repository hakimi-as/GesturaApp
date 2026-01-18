import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  String _selectedSignLanguage = 'ASL';
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
      debugPrint('Error loading profile image: $e');
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _nameController.text = user.fullName;
      _selectedSignLanguage = user.preferredSignLanguage;
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
              content: const Text('Profile updated successfully!'),
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
          SnackBar(
            content: Text('Error: $e'),
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
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
            return const Center(child: Text('No user data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildAvatarSection(context, user.initials),
                  const SizedBox(height: 32),
                  _buildUserInfoCard(context, user),
                  const SizedBox(height: 24),
                  _buildStatsCard(context, user, progressProvider),
                  const SizedBox(height: 24),
                  _buildPreferencesCard(context),
                  const SizedBox(height: 24),
                  if (_isEditing) _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, String initials) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final hasPhotoUrl = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;
    
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: (_profileImageBytes == null && !hasPhotoUrl) 
                    ? AppColors.primaryGradient 
                    : null,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: hasPhotoUrl
                    ? Image.network(
                        CloudinaryService.getOptimizedImage(user!.photoUrl!, width: 240, height: 240),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          if (_profileImageBytes != null) {
                            return Image.memory(_profileImageBytes!, fit: BoxFit.cover);
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          if (_profileImageBytes != null) {
                            return Image.memory(_profileImageBytes!, fit: BoxFit.cover);
                          }
                          return _buildInitialsAvatar(initials);
                        },
                      )
                    : _profileImageBytes != null
                        ? Image.memory(
                            _profileImageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildInitialsAvatar(initials);
                            },
                          )
                        : _buildInitialsAvatar(initials),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.bgPrimary, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, user) {
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
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _buildInfoField(
            context,
            label: 'Full Name',
            icon: Icons.person_outline,
            child: _isEditing
                ? TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  )
                : Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
          ),
          const Divider(height: 32),

          _buildInfoField(
            context,
            label: 'Email',
            icon: Icons.email_outlined,
            child: Text(
              user.email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.textMuted,
              ),
            ),
          ),
          const Divider(height: 32),

          _buildInfoField(
            context,
            label: 'I am a',
            icon: Icons.diversity_3_outlined,
            child: _isEditing
                ? _buildUserTypeSelector()
                : Text(
                    _getUserTypeDisplay(_selectedUserType),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildInfoField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.bgElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: context.textMuted, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedUserType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : context.bgElevated,
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
          Text(
            'My Stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  emoji: '⭐',
                  value: '${user.totalXP}',
                  label: 'Total XP',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  emoji: '🏆',
                  value: 'Lv ${user.level}',
                  label: 'Level',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  emoji: '🔥',
                  value: '${user.currentStreak}',
                  label: 'Streak',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  emoji: '📚',
                  value: '${progressProvider.userStats.totalSignsLearned}',
                  label: 'Signs',
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String emoji,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard(BuildContext context) {
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
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _buildInfoField(
            context,
            label: 'Preferred Sign Language',
            icon: Icons.sign_language,
            child: _isEditing
                ? _buildSignLanguageSelector()
                : Text(
                    _getSignLanguageDisplay(_selectedSignLanguage),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildSignLanguageSelector() {
    return Wrap(
      spacing: 8,
      children: AppConstants.supportedSignLanguages.map((lang) {
        final isSelected = _selectedSignLanguage == lang['code'];
        return GestureDetector(
          onTap: () => setState(() => _selectedSignLanguage = lang['code']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.15) : context.bgElevated,
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
            : const Text(
                'Save Changes',
                style: TextStyle(
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