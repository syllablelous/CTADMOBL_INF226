import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/article_model.dart';
import '../services/article_service.dart';

class ArticleDialog extends StatefulWidget {
  final Function(Article)? onArticleAdded;
  final String? title;

  const ArticleDialog({super.key, this.onArticleAdded, this.title});

  @override
  State<ArticleDialog> createState() => _ArticleDialogState();
}

class _ArticleDialogState extends State<ArticleDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isActive = true;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  List<String> _toList(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final payload = {
        'title': _titleController.text.trim(),
        'name': _authorController.text.trim(),
        'content': _toList(_contentController.text),
        'isActive': _isActive,
      };

      final Map response = await ArticleService().createArticle(payload);

      // Adjust depending on your API's response shape
      final created = (response['article'] ?? response);
      final newArticle = Article.fromJson(created);

      if (widget.onArticleAdded != null) {
        widget.onArticleAdded!(newArticle);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Article added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save article: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AlertDialog(
          title: Text(widget.title ?? 'Add Article'),
          contentPadding: EdgeInsets.all(24.w),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _authorController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Author / Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Author is required'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _contentController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText:
                            'Content (one item per line or comma-separated)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        final items = value == null
                            ? []
                            : value
                                  .trim()
                                  .split(RegExp(r'[\n,]'))
                                  .where((s) => s.trim().isNotEmpty)
                                  .toList();
                        return items.isEmpty
                            ? 'At least one content item is required'
                            : null;
                      },
                    ),
                    SizedBox(height: 8.h),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      subtitle: const Text('Whether this article is active'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),

        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator.adaptive(strokeWidth: 3.sp),
                    SizedBox(height: 16.h),
                    Text(
                      'Adding article...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Static method to show the ArticleDialog
class ArticleDialogHelper {
  static Future<void> show({
    required BuildContext context,
    Function(Article)? onArticleAdded,
    String? title,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          ArticleDialog(onArticleAdded: onArticleAdded, title: title),
    );
  }
}
