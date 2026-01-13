import 'package:flutter/material.dart';

class PostInput extends StatefulWidget {
  final void Function(String content) onSubmit;

  const PostInput({
    super.key,
    required this.onSubmit,
  });

  @override
  State<PostInput> createState() => _PostInputState();
}

class _PostInputState extends State<PostInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    widget.onSubmit(content);
    _controller.clear();

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _controller,
              maxLength: 512,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: '今何してる?',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _controller.text.trim().isEmpty || _isSubmitting
                  ? null
                  : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('投稿'),
            ),
          ],
        ),
      ),
    );
  }
}
