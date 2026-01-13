import 'package:flutter/material.dart';
import '../models/post.dart';

class EditPostCard extends StatefulWidget {
  final Post post;
  final void Function(String content) onSave;
  final VoidCallback onCancel;

  const EditPostCard({
    super.key,
    required this.post,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<EditPostCard> createState() => _EditPostCardState();
}

class _EditPostCardState extends State<EditPostCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿内容は1文字以上である必要があります')),
      );
      return;
    }
    widget.onSave(content);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLength: 512,
              maxLines: null,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '投稿内容を編集',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleSave,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
