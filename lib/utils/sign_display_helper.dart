/// Helper utilities for sign display names
class SignDisplayHelper {
  /// List of category IDs/names that are considered "alphabet" categories
  static const List<String> alphabetCategoryIds = [
    'alphabet',
    'alphabets',
    'letters',
    'fingerspelling',
  ];

  /// Check if a category is an alphabet/letter category
  static bool isAlphabetCategory(String? categoryId) {
    if (categoryId == null) return false;
    final lower = categoryId.toLowerCase();
    return alphabetCategoryIds.any((id) => lower.contains(id));
  }

  /// Get display name for a sign based on its category
  /// Returns "Letter A" for alphabet signs, or just the sign name otherwise
  static String getDisplayName(String signName, {String? categoryId, String? categoryName}) {
    // Check both categoryId and categoryName
    final isAlphabet = isAlphabetCategory(categoryId) || isAlphabetCategory(categoryName);
    
    if (isAlphabet && signName.length == 1) {
      return 'Letter ${signName.toUpperCase()}';
    }
    
    return signName;
  }

  /// For sign player: determine if a single character should be shown as "Letter X"
  /// This is used when we don't have category context (like in SignPlayer)
  static String getLabelForSign(String sign, {bool isFromSpelling = false}) {
    // If it's a single character and came from fingerspelling breakdown
    if (sign.length == 1 && isFromSpelling) {
      return 'Letter ${sign.toUpperCase()}';
    }
    return sign.toUpperCase();
  }
}