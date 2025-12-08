import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constant/app_colors.dart';
import '../constant/app_sizes.dart';
import '../constant/app_strings.dart';
import '../core/extensions/date_time_extension.dart';
import '../model/post.dart';
import '../ui_core/input_validator.dart';
import '../view_model/home_view_model.dart';
import 'confirmation_dialog.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isEditing = false;
  bool _isLiked = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _editController.text = widget.post.content;
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.post.content;
    });
  }

  Future<void> _saveEdit() async {
    final content = _editController.text.trim();

    if (!InputValidator.isValidPostContent(content)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.emptyPostError)),
      );
      return;
    }

    try {
      await ref.read(homeViewModelProvider.notifier).updatePost(
            widget.post.id,
            content,
          );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿を更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.updatePostError)),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    await ConfirmationDialog.showDeleteConfirmation(
      context: context,
      onConfirm: () async {
        try {
          await ref.read(homeViewModelProvider.notifier).deletePost(
                widget.post.id,
              );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('投稿を削除しました')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.deletePostError)),
            );
          }
        }
      },
    );
  }

  void _handleLike() {
    // Toggle like state optimistically
    setState(() => _isLiked = !_isLiked);

    // Update in backend
    ref.read(homeViewModelProvider.notifier).toggleLike(
          widget.post.id,
          _isLiked,
          widget.post.likesCount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final charCount = InputValidator.getCharacterCount(_editController.text);
    final isValidEdit =
        InputValidator.isValidPostContent(_editController.text);
    final exceedsLimit = InputValidator.exceedsMaxLength(_editController.text);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(
          color: AppColors.border,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content (Display or Edit mode)
            if (_isEditing) ...[
              TextField(
                controller: _editController,
                maxLines: null,
                maxLength: AppSizes.postMaxLength,
                decoration: InputDecoration(
                  hintText: AppStrings.postInputHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              Row(
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
                ],
              ),
            ] else ...[
              Text(
                widget.post.content,
                style: const TextStyle(
                  fontSize: AppSizes.fontMd,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.spaceMd),

            // Timestamp
            Text(
              widget.post.createdAt.toRelativeTimeString(),
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.spaceMd),

            // Actions
            if (_isEditing) ...[
              // Edit mode actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text(AppStrings.cancel),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  ElevatedButton(
                    onPressed: isValidEdit ? _saveEdit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(AppStrings.save),
                  ),
                ],
              ),
            ] else ...[
              // Display mode actions
              Row(
                children: [
                  // Like button
                  InkWell(
                    onTap: _handleLike,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingSm),
                      child: Row(
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: AppSizes.iconSm,
                            color: _isLiked
                                ? AppColors.like
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSizes.spaceXs),
                          Text(
                            '${widget.post.likesCount}',
                            style: TextStyle(
                              fontSize: AppSizes.fontSm,
                              color: _isLiked
                                  ? AppColors.like
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Edit button
                  IconButton(
                    onPressed: _toggleEditMode,
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: AppSizes.iconSm,
                    color: AppColors.textSecondary,
                    tooltip: AppStrings.edit,
                  ),
                  // Delete button
                  IconButton(
                    onPressed: _handleDelete,
                    icon: const Icon(Icons.delete_outline),
                    iconSize: AppSizes.iconSm,
                    color: AppColors.error,
                    tooltip: AppStrings.delete,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
