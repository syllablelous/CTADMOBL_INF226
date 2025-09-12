import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rapi_advmobprog/widgets/search_bar_widget.dart';

import '../models/article_model.dart';
import '../services/article_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/article_dialog.dart';
import 'details_screen.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  Future<List<Article>>? _futureArticles;
  final TextEditingController _searchController = TextEditingController();
  String query = "";
  List<Article> _allArticles = [];
  List<Article> _filteredArticles = [];
  bool _isInitialized = false;
  bool _isRefreshing = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles() {
    if (!_isInitialized) {
      _futureArticles = _getAllArticles();
      _isInitialized = true;
    }
  }

  Future<void> _refreshArticles() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      _futureArticles = _getAllArticles();
      await _futureArticles;
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<List<Article>> _getAllArticles() async {
    try {
      final response = await ArticleService().getAllArticles();

      // Convert List<dynamic> to List<Article>
      final List<Article> articles = response.map<Article>((item) {
        return Article.fromJson(item as Map<String, dynamic>);
      }).toList();

      setState(() {
        _allArticles = articles;
        _filterArticles();
      });

      return articles;
    } catch (e) {
      return <Article>[];
    }
  }

  void _filterArticles() {
    if (query.isEmpty) {
      _filteredArticles = List.from(_allArticles);
      _isSearching = false;
    } else {
      setState(() {
        _isSearching = true;
      });

      // Simulate a small delay for search feedback (optional)
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _filteredArticles = _allArticles.where((article) {
              return article.title.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  article.name.toLowerCase().contains(query.toLowerCase()) ||
                  article.content.any(
                    (content) =>
                        content.toLowerCase().contains(query.toLowerCase()),
                  );
            }).toList();
            _isSearching = false;
          });
        }
      });
    }
  }

  Future<void> _openAddArticleDialog() async {
    await ArticleDialogHelper.show(
      context: context,
      onArticleAdded: (newArticle) {
        setState(() {
          _allArticles.insert(0, newArticle);
          _filterArticles();
        });
      },
    );
  }

  Widget _statusChip(bool active) {
    return Chip(
      label: Text(active ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: active ? Colors.green : Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddArticleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshArticles,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // Search text field
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        SearchBarWidget(
                          hintText: 'Search for...',
                          textController: _searchController,
                          onChanged: (value) {
                            setState(() {
                              query = value;
                              _filterArticles();
                            });
                          },
                        ),
                        if (_isSearching) ...[
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              CustomText(text: 'Searching...', fontSize: 12.sp),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),

                  FutureBuilder<List<Article>>(
                    future: _futureArticles,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return SizedBox(
                          height: ScreenUtil().screenHeight * 0.6,
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CustomText(
                                text: 'No equipment article to display...',
                              ),
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: ScreenUtil().screenHeight * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircularProgressIndicator.adaptive(
                                  strokeWidth: 3.sp,
                                ),
                                SizedBox(height: 10.h),
                                const CustomText(
                                  text:
                                      'Waiting for the equipment articles to display...',
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final articles = snapshot.data ?? [];
                      if (articles.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(top: 20.h),
                          child: const Center(
                            child: CustomText(
                              text: 'No equipment article to display...',
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        shrinkWrap: true,
                        itemCount: _filteredArticles.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final article = _filteredArticles[index];
                          final preview = article.content.isNotEmpty
                              ? article.content.first
                              : '';
                          return Card(
                            elevation: 1,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ArticleDetailsScreen(article: article),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ScreenUtil().setWidth(15),
                                  vertical: ScreenUtil().setHeight(15),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: CustomText(
                                                  text: article.title.isEmpty
                                                      ? 'Untitled'
                                                      : article.title,
                                                  fontSize: 24.sp,
                                                  fontWeight: FontWeight.bold,
                                                  maxLines: 2,
                                                ),
                                              ),
                                              _statusChip(article.isActive),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          CustomText(
                                            text: article.name,
                                            fontSize: 13.sp,
                                          ),
                                          if (preview.isNotEmpty) ...[
                                            SizedBox(height: 6.h),
                                            CustomText(
                                              text: preview,
                                              fontSize: 12.sp,
                                              maxLines: 2,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay for refresh
          if (_isRefreshing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
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
                      CustomText(
                        text: 'Refreshing articles...',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
