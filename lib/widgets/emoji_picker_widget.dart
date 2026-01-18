import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Reusable emoji picker with categories and search
class EmojiPickerWidget extends StatefulWidget {
  final String? selectedEmoji;
  final Function(String emoji) onEmojiSelected;
  final bool showImageOption;
  final Function()? onImageTap;

  const EmojiPickerWidget({
    super.key,
    this.selectedEmoji,
    required this.onEmojiSelected,
    this.showImageOption = false,
    this.onImageTap,
  });

  @override
  State<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  final TextEditingController _emojiController = TextEditingController();
  String _selectedCategory = 'Education';
  bool _isEmojiMode = true;

  static const Map<String, List<String>> emojiCategories = {
    'Education': ['📚', '📖', '📝', '✏️', '🎓', '🧠', '💡', '📕', '📗', '📘', '📙', '📔', '📓', '📒', '🔖', '📑'],
    'Gestures': ['👋', '🤟', '✋', '🖐️', '🖖', '👌', '🤌', '🤏', '✌️', '🤞', '🫰', '🤙', '👈', '👉', '👆', '👇'],
    'Achievements': ['🏆', '🥇', '🥈', '🥉', '🏅', '🎖️', '🎗️', '🏵️', '🎯', '🎪', '🎨', '🎬', '🎤', '🎧', '🎼', '🎹'],
    'Fire & Energy': ['🔥', '⚡', '💥', '✨', '💫', '🌟', '⭐', '🌠', '🌈', '☀️', '🌞', '💯', '🎆', '🎇', '💎', '🔮'],
    'Symbols': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '💔', '❤️‍🔥', '💕', '💞', '💓', '💗', '💖', '💘'],
    'Faces': ['😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '😊', '😇', '🥰', '😍', '🤩', '😘', '😋'],
    'Animals': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🦉'],
    'Objects': ['⌚', '📱', '💻', '⌨️', '🖥️', '🖨️', '📷', '📹', '🎥', '📽️', '🎞️', '📞', '📺', '📻', '🎙️', '⏰'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.selectedEmoji != null) {
      _emojiController.text = widget.selectedEmoji!;
    }
  }

  @override
  void dispose() {
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Type Toggle
        if (widget.showImageOption) ...[
          Text('Icon Type', style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildToggleButton(icon: Icons.emoji_emotions, label: 'Emoji', isSelected: _isEmojiMode, onTap: () => setState(() => _isEmojiMode = true))),
              const SizedBox(width: 12),
              Expanded(child: _buildToggleButton(icon: Icons.image, label: 'Image', isSelected: !_isEmojiMode, onTap: () { setState(() => _isEmojiMode = false); widget.onImageTap?.call(); })),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (_isEmojiMode) ...[
          // Emoji Input Row
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Center(
                  child: Text(
                    _emojiController.text.isNotEmpty ? _emojiController.text : '😀',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _emojiController,
                  decoration: InputDecoration(
                    hintText: 'Type or paste emoji',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check, color: AppColors.primary),
                      onPressed: () {
                        if (_emojiController.text.isNotEmpty) {
                          widget.onEmojiSelected(_emojiController.text);
                        }
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.isNotEmpty) {
                      widget.onEmojiSelected(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Chips - use Wrap instead of horizontal ListView for dialog compatibility
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: emojiCategories.keys.map((category) {
              final isSelected = _selectedCategory == category;
              final firstEmoji = emojiCategories[category]!.first;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : context.bgElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.primary : context.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(firstEmoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : context.textPrimary,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Emoji Grid - using Wrap for better dialog compatibility
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: emojiCategories[_selectedCategory]!.map((emoji) {
                  final isSelected = _emojiController.text == emoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _emojiController.text = emoji;
                      });
                      widget.onEmojiSelected(emoji);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withAlpha(30) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : context.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : context.borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : context.textMuted, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? AppColors.primary : context.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}