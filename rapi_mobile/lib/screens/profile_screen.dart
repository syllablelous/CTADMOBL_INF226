import 'package:flutter/material.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String _loginType = 'mongodb';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      _loginType = _userService.getLoginType();

      // If the user logged in via Firebase login:
      if (_loginType == 'firebase') {
        final firebaseUser = _userService.currentUser;
        final localData = await _userService.getUserData();

        setState(() {
          _userData = {
            'firstName':
                firebaseUser?.displayName?.split(' ').first ??
                localData['firstName'] ??
                '',
            'lastName':
                firebaseUser?.displayName?.split(' ').skip(1).join(' ') ??
                localData['lastName'] ??
                '',
            'email': firebaseUser?.email ?? localData['email'] ?? '',
            'username': firebaseUser?.displayName ?? localData['username'] ?? '',
            'type': 'firebase_user',
            'uid': firebaseUser?.uid ?? '',
            'emailVerified': firebaseUser?.emailVerified ?? false,
          };
          _isLoading = false;
        });
      } else {
        // Else if users logged in via MongoDB:
        final userData = await _userService.getUserData();
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleUpdateUsername() async {
    final TextEditingController usernameController = TextEditingController(
      text: _userData['username'] ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Username'),
        content: TextField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Enter your username',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(usernameController.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        if (_loginType == 'firebase') {
          await _userService.updateUsername(username: result);
        } else {
          // For MongoDB users, update username directly
          final response = await _userService.updateMongoDBUsername(
            email: _userData['email'],
            password: '', // No password needed since user is already logged in
            username: result.trim(),
          );
          
          // Save updated user data to local storage
          await _userService.saveUserData(response);
        }
        // Reload user data
        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update username: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleChangePassword() async {

    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text ==
                      confirmPasswordController.text &&
                  newPasswordController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        if (_loginType == 'firebase') {
          await _userService.resetPasswordFromCurrentPassword(
            currentPassword: currentPasswordController.text,
            newPassword: newPasswordController.text,
            email: _userData['email'],
          );
        } else {
          await _userService.changeMongoDBPassword(
            email: _userData['email'],
            currentPassword: currentPasswordController.text,
            newPassword: newPasswordController.text,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to change password: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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

    if (result == true) {
      // Show password confirmation for both Firebase and MongoDB users
      final TextEditingController passwordController = TextEditingController();

      final passwordResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter your password to confirm',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      );

      if (passwordResult == true) {
        try {
          if (_loginType == 'firebase') {
            await _userService.deleteAccount(
              email: _userData['email'],
              password: passwordController.text,
            );
          } else {
            await _userService.deleteMongoDBAccount(
              email: _userData['email'],
              password: passwordController.text,
            );
          }

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account deleted successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete account: ${e.toString()}'),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.1),
                          Theme.of(context).primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Profile Avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            _userData['firstName']?.isNotEmpty == true
                                ? _userData['firstName'][0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userData['username'] ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _loginType == 'firebase'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _loginType == 'firebase'
                                ? 'FIREBASE USER'
                                : 'MONGODB USER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _loginType == 'firebase'
                                  ? Colors.orange[700]
                                  : Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildInfoCard('Personal Information', [
                    _buildInfoRow(
                      'Full Name',
                      '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}'
                          .trim(),
                    ),
                    _buildInfoRow(
                      'Email',
                      _userData['email'] ?? 'Not provided',
                    ),
                    _buildInfoRow(
                      'Authentication Type',
                      _loginType == 'firebase'
                          ? 'Firebase Auth'
                          : 'MongoDB-Backend API',
                    ),
                    _buildInfoRow(
                      'Username',
                      _userData['username'] ?? 'Not provided',
                    ),
                    if (_loginType == 'mongodb') ...[
                      _buildInfoRow(
                        'User Type',
                        _userData['type'] ?? 'Not provided',
                      ),
                    ],
                  ]),
                  const SizedBox(height: 16),

                  _buildInfoCard('Account Status', [
                    _buildInfoRow('Account Status', 'Active'),
                    _buildInfoRow('Member Since', 'Recently'),
                  ]),
                  const SizedBox(height: 24),

                  _buildInfoCard('Account Management', [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Update Username'),
                      subtitle: const Text('Change your display name'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _handleUpdateUsername,
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your password'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _handleChangePassword,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text('Permanently delete your account'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _handleDeleteAccount,
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Settings Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ), // Added spacing below settings button
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
