import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
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
          .doc(code)
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
      if (code == authProvider.userId) {
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
            builder: (_) => FriendProfileScreen(friendId: code),
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
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: context.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              padding: const EdgeInsets.all(4),
              tabs: const [Tab(text: 'My QR Code'), Tab(text: 'Enter Code')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMyQRCodeTab(), _buildEnterCodeTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyQRCodeTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userId = user?.id ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                    image: user?.photoUrl != null
                        ? DecorationImage(image: NetworkImage(user!.photoUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: user?.photoUrl == null
                      ? Center(
                          child: Text(
                            user?.initials ?? 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(user?.fullName ?? 'User', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('Level ${user?.level ?? 1}', style: TextStyle(color: context.textMuted)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: QrImageView(
                    data: 'gestura://add-friend/$userId',
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF6366F1)),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF6366F1)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Scan this code to add me', style: TextStyle(color: context.textMuted)),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 24),
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
                      decoration: BoxDecoration(color: AppColors.primary.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.tag, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('My Friend Code', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: context.bgElevated, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          userId,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userId));
                          HapticService.lightTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Friend code copied!'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.primary.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('Copy', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
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

  Widget _buildEnterCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(26), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.person_search_rounded, color: AppColors.primary, size: 40),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 24),
          Text('Enter Friend Code', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text('Ask your friend for their code or scan their QR code', style: TextStyle(color: context.textMuted), textAlign: TextAlign.center).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: context.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.borderColor)),
            child: Column(
              children: [
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'Paste friend code here',
                    hintStyle: TextStyle(color: context.textMuted),
                    prefixIcon: Icon(Icons.tag, color: context.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.paste_rounded, color: AppColors.primary),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  onSubmitted: (_) => _searchByCode(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.error.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _isLoading ? null : _searchByCode,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _isLoading ? [context.textMuted, context.textMuted] : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  else
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Find Friend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Tips', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip('Ask your friend to share their QR code'),
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
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: context.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}