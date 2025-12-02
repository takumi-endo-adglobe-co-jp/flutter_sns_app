import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constant/app_colors.dart';
import '../constant/app_sizes.dart';
import '../constant/app_strings.dart';
import '../ui_core/input_validator.dart';
import '../view_model/home_view_model.dart';

class PostInputField extends ConsumerStatefulWidget {
  const PostInputField({super.key});

  @override
  ConsumerState<PostInputField> createState() => _PostInputFieldState();
}

class _PostInputFieldState extends ConsumerState<PostInputField> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePost() async {
    final content = _controller.text.trim();

    if (!InputValidator.isValidPostContent(content)) {
      return;
    }

    setState(() => _isPosting = true);

    try {
      await ref.read(homeViewModelProvider.notifier).createPost(content);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.createPostError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final isValid = InputValidator.isValidPostContent(text);
    final charCount = InputValidator.getCharacterCount(text);
    final exceedsLimit = InputValidator.exceedsMaxLength(text);

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLines: null,
            maxLength: AppSizes.postMaxLength,
            decoration: InputDecoration(
              hintText: AppStrings.postInputHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                charCount,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: exceedsLimit
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
              ElevatedButton(
                onPressed: _isPosting || !isValid ? null : _handlePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLg,
                    vertical: AppSizes.paddingSm,
                  ),
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(AppStrings.postButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
