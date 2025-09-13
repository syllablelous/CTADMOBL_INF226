import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';
import '../widgets/custom_text.dart';
import './details_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final _svc = ItemService();
  final List<Item> _archivedItems = [];
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadArchivedItems();
  }

  Future<void> _loadArchivedItems() async {
    final res = await _svc.getAllItem();
    final list = (res['items'] ?? res) as dynamic;
    final List data = list is List ? list : (list['data'] ?? []);

    // Filter only inactive items
    final inactiveItems = data
        .where((item) => item['isActive'] == false)
        .toList();

    _archivedItems
      ..clear()
      ..addAll(inactiveItems.map<Item>((e) => Item.fromJson(e)));
  }

  Future<void> _deleteItem(String itemId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to permanently delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _svc.deleteItem(itemId, {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );

          // Reload the archived items
          await _loadArchivedItems();
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete item: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'Failed to load archived items',
                    fontSize: 16.sp,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadFuture = _loadArchivedItems();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_archivedItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'No archived items',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    text: 'Inactive items will appear here',
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadArchivedItems,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _archivedItems.length,
              itemBuilder: (context, index) {
                final item = _archivedItems[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12.h),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.w),
                    leading: CircleAvatar(
                      radius: 24.r,
                      backgroundColor: Colors.grey[300],
                      child: item.photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24.r),
                              child: Image.network(
                                item.photoUrl,
                                width: 48.w,
                                height: 48.h,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    size: 24.sp,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.inventory_2,
                              size: 24.sp,
                              color: Colors.grey[600],
                            ),
                    ),
                    title: CustomText(
                      text: item.name,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),
                        CustomText(
                          text:
                              'Available: ${item.qtyAvailable}/${item.qtyTotal}',
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        if (item.description.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          CustomText(
                            text: item.description.first,
                            fontSize: 12.sp,
                            color: Colors.grey[500],
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(item: item),
                              ),
                            );
                          },
                          icon: Icon(Icons.visibility, size: 20.sp),
                          tooltip: 'View Details',
                        ),
                        IconButton(
                          onPressed: () => _deleteItem(item.id),
                          icon: Icon(
                            Icons.delete_forever,
                            size: 20.sp,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete Permanently',
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(item: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
