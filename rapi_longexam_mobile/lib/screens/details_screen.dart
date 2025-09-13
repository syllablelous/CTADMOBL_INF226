import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';

class DetailScreen extends StatefulWidget {
  final Item item;

  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _photoCtrl;
  late TextEditingController _qtyTotalCtrl;
  late TextEditingController _qtyAvailCtrl;
  late bool _isActive;
  bool _isSaving = false;
  final _svc = ItemService();
  late Item _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _nameCtrl = TextEditingController(text: _item.name);
    _descCtrl = TextEditingController(text: _item.description.join('\n'));
    _photoCtrl = TextEditingController(text: _item.photoUrl);
    _qtyTotalCtrl = TextEditingController(text: _item.qtyTotal);
    _qtyAvailCtrl = TextEditingController(text: _item.qtyAvailable);
    _isActive = _item.isActive.toLowerCase() == 'true';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _photoCtrl.dispose();
    _qtyTotalCtrl.dispose();
    _qtyAvailCtrl.dispose();
    super.dispose();
  }

  List<String> _parseDesc(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  int _toInt(TextEditingController c, {int fallback = 0}) {
    final n = int.tryParse(c.text.trim());
    return n != null && n >= 0 ? n : fallback;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final total = _toInt(_qtyTotalCtrl);
    final avail = _toInt(_qtyAvailCtrl);

    if (avail > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Qty Available cannot exceed Qty Total')),
      );
      return;
    }

    final payload = {
      'name': _nameCtrl.text.trim(),
      'description': _parseDesc(_descCtrl.text),
      'photoUrl': _photoCtrl.text.trim(),
      'qtyTotal': total,
      'qtyAvailable': avail,
      'isActive': _isActive,
    };

    try {
      setState(() => _isSaving = true);
      final res = await _svc.updateItem(_item.id, payload);
      final updatedItem = Item.fromJson(Map<String, dynamic>.from(res));
      setState(() => _item = updatedItem);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item updated.')));
        Navigator.pop(context, updatedItem);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isSaving = true);
      await _svc.deleteItem(_item.id, {});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item deleted.')));
        Navigator.pop(context, {'deleted': true, 'id': _item.id});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _imagePreview() {
    final url = _photoCtrl.text.trim();
    if (url.isEmpty) {
      return Container(
        height: 160.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.inventory_2_outlined, size: 48),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 160.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 160.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.broken_image_outlined, size: 48),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_item.name.isEmpty ? 'Item' : _item.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _imagePreview(),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _photoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Photo URL',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Required' : null,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _descCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Description (one per line or comma-separated)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => _parseDesc(v ?? '').isEmpty
                      ? 'Add at least one line'
                      : null,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyTotalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty Total',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < 0 ? 'Invalid' : null;
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextFormField(
                        controller: _qtyAvailCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty Available',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final a = int.tryParse(v ?? '');
                          final t = int.tryParse(_qtyTotalCtrl.text);
                          if (a == null || a < 0) return 'Invalid';
                          if (t != null && a > t) return '> total';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  ),
                ),
                SizedBox(height: 8.h),
                // Only show delete button for inactive items
                if (!_isActive) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Item'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Active items cannot be deleted',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
