import '../constant/app_sizes.dart';
import '../constant/app_strings.dart';

class InputValidator {
  InputValidator._();

  /// Validate post content
  /// Returns error message if invalid, null if valid
  static String? validatePostContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emptyPostError;
    }

    if (value.length > AppSizes.postMaxLength) {
      return AppStrings.maxLengthError;
    }

    return null;
  }

  /// Check if post content is valid (returns bool)
  static bool isValidPostContent(String? value) {
    return validatePostContent(value) == null;
  }

  /// Get character count for display
  static String getCharacterCount(String text) {
    return '${text.length}/${AppSizes.postMaxLength}';
  }

  /// Check if character count exceeds limit
  static bool exceedsMaxLength(String text) {
    return text.length > AppSizes.postMaxLength;
  }

  /// Check if text is empty or whitespace only
  static bool isEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }
}
