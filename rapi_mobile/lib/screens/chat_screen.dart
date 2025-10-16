import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserEmail;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _searchChatController.addListener(_onSearchChanged);
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await userService.value.getUserData();
    setState(() {
      _currentUserEmail = userData['email'];
    });

    await userService.value.ensureFirebaseUserInFirestore();
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchChatController.text.toLowerCase();
    });
  }

  String _getDisplayName(Map<String, dynamic> user) {
    final firstName = user['firstName']?.toString() ?? '';
    final lastName = user['lastName']?.toString() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else {
      return 'Unknown User';
    }
  }

  @override
  void dispose() {
    _searchChatController.removeListener(_onSearchChanged);
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 23.w),
                child: TextField(
                  controller: _searchChatController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search chat...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchChatController.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.cancel),
                            onPressed: () {
                              setState(() {
                                _searchChatController.clear();
                                _searchText = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: ScreenUtil().screenHeight * 0.6,
                      padding: EdgeInsets.all(16.sp),
                      child: const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      height: ScreenUtil().screenHeight * 0.6,
                      padding: EdgeInsets.all(16.sp),
                      child: Center(
                        child: CustomText(
                          text: 'Error loading users',
                          fontSize: 16.sp,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      height: ScreenUtil().screenHeight * 0.6,
                      padding: EdgeInsets.all(16.sp),
                      child: Center(
                        child: CustomText(
                          text: 'No users found',
                          fontSize: 16.sp,
                        ),
                      ),
                    );
                  }

                  final allUsers = snapshot.data!;

                  final filteredUsers = allUsers.where((user) {
                    if (_currentUserEmail != null &&
                        user['email'] == _currentUserEmail) {
                      return false;
                    }

                    if (_searchText.isNotEmpty) {
                      final firstName = (user['firstName'] ?? '')
                          .toString()
                          .toLowerCase();
                      final lastName = (user['lastName'] ?? '')
                          .toString()
                          .toLowerCase();
                      final email = (user['email'] ?? '')
                          .toString()
                          .toLowerCase();
                      final fullName = '$firstName $lastName'.trim();

                      return firstName.contains(_searchText) ||
                          lastName.contains(_searchText) ||
                          email.contains(_searchText) ||
                          fullName.contains(_searchText);
                    }

                    return true;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Container(
                      height: ScreenUtil().screenHeight * 0.6,
                      padding: EdgeInsets.all(16.sp),
                      child: Center(
                        child: CustomText(
                          text: _searchText.isNotEmpty
                              ? 'No users found matching "$_searchText"'
                              : 'No other users found...',
                          fontSize: 16.sp,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                currentUserEmail: _currentUserEmail!,
                                tappedUser: user,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 4.h),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 24.r,
                              child: CustomText(
                                text:
                                    user['firstName'] != null &&
                                        user['firstName'].toString().isNotEmpty
                                    ? user['firstName'][0].toUpperCase()
                                    : '?',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            title: CustomText(
                              text: _getDisplayName(user),
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            subtitle: CustomText(
                              text: user['email'] ?? 'No email',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
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
    );
  }
}
