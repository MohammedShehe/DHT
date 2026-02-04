import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/account_service.dart';
import '../services/password_setup_service.dart'; // Add this import
import '../utils/api_config.dart';
import 'login_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // User Data
  String fullName = "Loading...";
  String email = "Loading...";
  String profilePic = "";
  
  // Preferences
  ThemeMode _themeMode = ThemeMode.system;
  String _language = "English";
  String _measurementSystem = "Metric";
  bool _biometricLogin = true;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _dataSyncEnabled = true;
  
  // Form controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _deletePasswordController = TextEditingController();
  final TextEditingController _deleteOtpController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _emailOtpController = TextEditingController();

  // UI State
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isChangingPassword = false;
  bool _isLoggingOut = false;
  bool _isSyncingWearable = false;
  bool _isExportingData = false;

  // Health Stats
  final Map<String, dynamic> healthStats = {
    'streak': 0,
    'points': 0,
    'level': 'Bronze',
    'caloriesBurned': 0,
    'steps': 0,
    'sleepHours': 0,
    'waterIntake': 0,
  };

  final List<String> languages = ['English', 'Swahili'];
  final List<String> measurementSystems = ['Metric', 'Imperial'];
  final List<String> themeOptions = ['Light', 'Dark', 'System Default'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    _deleteOtpController.dispose();
    _newEmailController.dispose();
    _emailOtpController.dispose();
    super.dispose();
  }

  // Helper method to show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper method to parse error messages
  String _parseErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('already registered') || lowerMessage.contains('already in use')) {
      return 'This email is already in use. Please use a different email.';
    } else if (lowerMessage.contains('same as current')) {
      return 'This is already your current email. Please enter a new email address.';
    } else if (lowerMessage.contains('invalid email')) {
      return 'Please enter a valid email address.';
    } else if (lowerMessage.contains('incorrect password') || lowerMessage.contains('invalid password')) {
      return 'Incorrect password. Please try again.';
    } else if (lowerMessage.contains('otp') && lowerMessage.contains('invalid')) {
      return 'Invalid or expired OTP. Please try again.';
    } else if (lowerMessage.contains('connection') || lowerMessage.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (lowerMessage.contains('token') || lowerMessage.contains('session') || lowerMessage.contains('unauthorized')) {
      return 'Session expired. Please login again.';
    }
    
    return message;
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await ProfileService.getProfile();
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        final profile = result['profile'];
        setState(() {
          fullName = profile['full_name'] ?? "No Name";
          email = profile['email'] ?? "No Email";
          profilePic = profile['profile_pic'] ?? "";
        });
      } else {
        final message = result['message']?.toString().toLowerCase() ?? '';
        if (message.contains('token') || message.contains('unauthorized') || message.contains('expired')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Logout',
                onPressed: _performLogout,
              ),
            ),
          );
        } else {
          _showErrorDialog('Error', _parseErrorMessage(result['message'] ?? 'Failed to load profile'));
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error', 'Failed to load profile: ${e.toString()}');
    }
    
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _performLogout() async {
    if (!mounted) return;
    
    setState(() => _isLoggingOut = true);
    
    try {
      final result = await AccountService.logout();
      
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      
      if (result['success'] == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        _showErrorDialog('Logout Failed', _parseErrorMessage(result['message'] ?? 'Logout failed'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      _showErrorDialog('Error', 'An error occurred during logout');
    }
  }

  Future<void> _performAccountDeletion(String otp) async {
    if (!mounted) return;
    
    setState(() => _isLoggingOut = true);
    
    try {
      final result = await AccountService.confirmDeleteAccount(otp);
      
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      
      if (result['success'] == true) {
        _deletePasswordController.clear();
        _deleteOtpController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        _showErrorDialog('Deletion Failed', _parseErrorMessage(result['message'] ?? 'Account deletion failed'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      _showErrorDialog('Error', 'An error occurred during account deletion');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    
    if (pickedFile != null && mounted) {
      setState(() {
        _isUploadingImage = true;
      });
      
      try {
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;
        
        // Validate image size (max 5MB)
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            setState(() => _isUploadingImage = false);
            _showErrorDialog('Image Too Large', 'Please select an image smaller than 5MB');
          }
          return;
        }
        
        // Store for UI preview
        if (mounted) {
          setState(() {
            _profileImageBytes = bytes;
            _profileImageName = fileName;
          });
        }
        
        // Upload the image
        final result = await ProfileService.uploadProfilePic(
          imageFile: kIsWeb ? null : File(pickedFile.path),
          fileName: fileName,
          bytes: bytes,
        );
        
        if (!mounted) return;
        setState(() => _isUploadingImage = false);
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Profile picture updated'),
              backgroundColor: const Color(0xFF00C853),
              duration: const Duration(seconds: 3),
            ),
          );
          await _loadProfileData();
        } else {
          _showErrorDialog('Upload Failed', _parseErrorMessage(result['message'] ?? 'Upload failed'));
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isUploadingImage = false);
        _showErrorDialog('Error', 'Failed to upload image: ${e.toString()}');
      }
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themeOptions.map((theme) {
            final isSelected = (theme == 'Light' && _themeMode == ThemeMode.light) ||
                (theme == 'Dark' && _themeMode == ThemeMode.dark) ||
                (theme == 'System Default' && _themeMode == ThemeMode.system);
            
            return ListTile(
              title: Text(theme),
              trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF00C853)) : null,
              onTap: () {
                setState(() {
                  if (theme == 'Light') {
                    _themeMode = ThemeMode.light;
                    _darkMode = false;
                  } else if (theme == 'Dark') {
                    _themeMode = ThemeMode.dark;
                    _darkMode = true;
                  } else {
                    _themeMode = ThemeMode.system;
                    _darkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
                  }
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _exportData(String type) async {
    if (!mounted) return;
    
    setState(() => _isExportingData = true);
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isExportingData = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data exported as $type successfully!'),
        backgroundColor: const Color(0xFF00C853),
      ),
    );
  }

  Future<void> _syncWithWearable() async {
    if (!mounted) return;
    
    setState(() => _isSyncingWearable = true);
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isSyncingWearable = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully synced with wearable devices!'),
        backgroundColor: Color(0xFF00C853),
      ),
    );
  }

  // ✅ UPDATED: Change password with Google user check
  Future<void> _changePassword() async {
    // First check if user has a password (Google users might not)
    final hasPassword = await _checkIfUserHasPassword();
    
    if (!hasPassword) {
      // Google user without password - show setup dialog instead
      _showGoogleUserPasswordSetup();
      return;
    }
    
    // Original validation
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Error', 'Passwords do not match');
      return;
    }
    
    if (_newPasswordController.text.isEmpty ||
        _currentPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog('Error', 'Please fill all password fields');
      return;
    }
    
    if (_newPasswordController.text.length < 6) {
      _showErrorDialog('Error', 'Password must be at least 6 characters long');
      return;
    }
    
    setState(() => _isChangingPassword = true);
    
    try {
      final result = await ProfileService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      
      if (!mounted) return;
      setState(() => _isChangingPassword = false);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showErrorDialog('Password Change Failed', _parseErrorMessage(result['message'] ?? 'Failed to change password'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChangingPassword = false);
      _showErrorDialog('Error', 'Failed to change password');
    }
  }

  // ✅ ADDED: Check if user has password
  Future<bool> _checkIfUserHasPassword() async {
    try {
      final result = await PasswordSetupService.hasPassword();
      if (result['success'] == true) {
        return result['hasPassword'] ?? false;
      }
      return true; // Assume they have password if check fails
    } catch (e) {
      return true; // Assume they have password
    }
  }

  // ✅ ADDED: Show password setup for Google users
  void _showGoogleUserPasswordSetup() {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSettingUp = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Setup Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You don\'t have a password set. Please setup a password to enable password changes.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (isSettingUp)
                const Center(child: CircularProgressIndicator())
              else ...[
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ]
            ],
          ),
          actions: isSettingUp
              ? []
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Validation
                      if (passwordController.text.isEmpty || 
                          confirmPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in both password fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      if (passwordController.text.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password must be at least 8 characters'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      if (passwordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      setState(() => isSettingUp = true);
                      
                      final result = await PasswordSetupService.setupPassword(
                        password: passwordController.text,
                        confirmPassword: confirmPasswordController.text,
                      );
                      
                      if (mounted) {
                        setState(() => isSettingUp = false);
                        
                        if (result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Setup Password'),
                  ),
                ],
        ),
      ),
    );
  }

  Future<void> _updateName() async {
    final nameController = TextEditingController(text: fullName);
    bool isUpdating = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          actions: [
            if (isUpdating)
              const Center(child: CircularProgressIndicator())
            else ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    _showErrorDialog('Error', 'Please enter a name');
                    return;
                  }
                  
                  setState(() => isUpdating = true);
                  
                  final result = await ProfileService.updateName(nameController.text);
                  
                  if (!mounted) return;
                  
                  if (result['success'] == true) {
                    this.setState(() => fullName = nameController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: const Color(0xFF00C853),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    _showErrorDialog('Update Failed', _parseErrorMessage(result['message'] ?? 'Failed to update name'));
                    setState(() => isUpdating = false);
                  }
                },
                child: const Text('Update'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _requestEmailChange() {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    
    showDialog(
      context: context,
      builder: (context) {
        bool isSendingOtp = false;
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Change Email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newEmailController,
                  decoration: const InputDecoration(
                    labelText: 'New Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                const Text(
                  'An OTP will be sent to your new email for verification.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              if (isSendingOtp)
                const Center(child: CircularProgressIndicator())
              else ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_newEmailController.text.isEmpty) {
                      _showErrorDialog('Error', 'Please enter a new email');
                      return;
                    }
                    
                    if (!emailRegex.hasMatch(_newEmailController.text)) {
                      _showErrorDialog('Error', 'Please enter a valid email address');
                      return;
                    }
                    
                    setState(() => isSendingOtp = true);
                    
                    try {
                      final result = await ProfileService.requestEmailChange(_newEmailController.text);
                      
                      if (!mounted) return;
                      setState(() => isSendingOtp = false);
                      
                      if (result['success'] == true) {
                        Navigator.pop(context);
                        _showEmailOtpDialog();
                      } else {
                        _showErrorDialog('Email Change Failed', _parseErrorMessage(result['message'] ?? 'Failed to send OTP'));
                      }
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => isSendingOtp = false);
                      _showErrorDialog('Error', 'Failed to send OTP');
                    }
                  },
                  child: const Text('Send OTP'),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  void _showEmailOtpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        bool isVerifying = false;
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Verify OTP'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailOtpController,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check your new email for the 6-digit OTP',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              if (isVerifying)
                const Center(child: CircularProgressIndicator())
              else ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_emailOtpController.text.isEmpty) {
                      _showErrorDialog('Error', 'Please enter OTP');
                      return;
                    }
                    
                    if (_emailOtpController.text.length != 6) {
                      _showErrorDialog('Error', 'OTP must be 6 digits');
                      return;
                    }
                    
                    setState(() => isVerifying = true);
                    
                    try {
                      final result = await ProfileService.confirmEmailChange(_emailOtpController.text);
                      
                      if (!mounted) return;
                      setState(() => isVerifying = false);
                      
                      if (result['success'] == true) {
                        setState(() => email = _newEmailController.text);
                        _newEmailController.clear();
                        _emailOtpController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            backgroundColor: const Color(0xFF00C853),
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        _showErrorDialog('Verification Failed', _parseErrorMessage(result['message'] ?? 'Failed to verify OTP'));
                      }
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => isVerifying = false);
                      _showErrorDialog('Error', 'Failed to verify OTP');
                    }
                  },
                  child: const Text('Verify'),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Logout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to logout?'),
              if (_isLoggingOut) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ]
            ],
          ),
          actions: _isLoggingOut
              ? []
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _performLogout();
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Logout'),
                  ),
                ],
        ),
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        bool isRequesting = false;
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Delete Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  style: TextStyle(color: Colors.red),
                ),
                if (isRequesting) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ] else ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deletePasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Enter your password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ]
              ],
            ),
            actions: isRequesting
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_deletePasswordController.text.isEmpty) {
                          _showErrorDialog('Error', 'Please enter your password');
                          return;
                        }
                        
                        setState(() => isRequesting = true);
                        
                        try {
                          final result = await AccountService.requestDeleteAccount(_deletePasswordController.text);
                          
                          if (!mounted) return;
                          setState(() => isRequesting = false);
                          
                          if (result['success'] == true) {
                            Navigator.pop(context);
                            _showDeleteOtpDialog();
                          } else {
                            _showErrorDialog('Deletion Failed', _parseErrorMessage(result['message'] ?? 'Failed to request deletion'));
                          }
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => isRequesting = false);
                          _showErrorDialog('Error', 'Failed to request deletion');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Request Deletion'),
                    ),
                  ],
          ),
        );
      },
    );
  }

  void _showDeleteOtpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        bool isConfirming = false;
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Check your email for the OTP to confirm account deletion.',
                  style: TextStyle(color: Colors.red),
                ),
                if (isConfirming) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ] else ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deleteOtpController,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ]
              ],
            ),
            actions: isConfirming
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_deleteOtpController.text.isEmpty) {
                          _showErrorDialog('Error', 'Please enter OTP');
                          return;
                        }
                        
                        if (_deleteOtpController.text.length != 6) {
                          _showErrorDialog('Error', 'OTP must be 6 digits');
                          return;
                        }
                        
                        setState(() => isConfirming = true);
                        await _performAccountDeletion(_deleteOtpController.text);
                        
                        if (!mounted) return;
                        if (!isConfirming) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00C853).withOpacity(0.8),
            const Color(0xFF00E676),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _getProfileImage(),
                backgroundColor: Colors.white,
              ),
              if (_isUploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF00C853)),
                  onPressed: _isUploadingImage ? null : _pickImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Level ${healthStats['level']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getProfileImage() {
    // If we have a newly selected image, show it
    if (_profileImageBytes != null) {
      return MemoryImage(_profileImageBytes!);
    }
    
    // If we have a saved profile picture from server
    if (profilePic.isNotEmpty) {
      String imageUrl = profilePic;
      
      // Check if it's a full URL or relative path
      if (!profilePic.startsWith('http')) {
        // Construct full URL from base URL
        imageUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}/$profilePic';
      }
      
      return NetworkImage(imageUrl) as ImageProvider;
    }
    
    // Default avatar
    return const AssetImage('assets/default_avatar.jpg');
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String subtitle = '',
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF00C853).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF00C853), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _changePassword,
                child: _isChangingPassword
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Changing Password...'),
                        ],
                      )
                    : const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildStatCard('Day Streak', '${healthStats['streak']}', Icons.local_fire_department, Colors.orange),
                  _buildStatCard('Total Points', '${healthStats['points']}', Icons.star, Colors.amber),
                  _buildStatCard('Calories Burned', '${healthStats['caloriesBurned']}', Icons.whatshot, Colors.red),
                  _buildStatCard('Steps', '${healthStats['steps']}', Icons.directions_walk, Colors.blue),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          icon: Icons.person,
                          title: 'Personal Information',
                          subtitle: 'Update your profile details',
                          trailing: IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: _updateName),
                          onTap: _updateName,
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          icon: Icons.email,
                          title: 'Change Email',
                          subtitle: 'Update your email address',
                          trailing: IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: _requestEmailChange),
                          onTap: _requestEmailChange,
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: _language,
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _language,
                              items: languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                              onChanged: (value) => setState(() => _language = value!),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          icon: Icons.palette,
                          title: 'Theme',
                          subtitle: themeOptions[_themeMode == ThemeMode.light ? 0 : _themeMode == ThemeMode.dark ? 1 : 2],
                          trailing: IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: _showThemeDialog),
                          onTap: _showThemeDialog,
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          icon: Icons.science,
                          title: 'Measurement System',
                          subtitle: _measurementSystem,
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _measurementSystem,
                              items: measurementSystems.map((system) => DropdownMenuItem(value: system, child: Text(system))).toList(),
                              onChanged: (value) => setState(() => _measurementSystem = value!),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          icon: Icons.fingerprint,
                          title: 'Biometric Login',
                          subtitle: 'Use fingerprint or face ID',
                          trailing: Switch(
                            value: _biometricLogin,
                            onChanged: (value) => setState(() => _biometricLogin = value),
                            activeColor: const Color(0xFF00C853),
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          subtitle: 'Receive health reminders',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) => setState(() => _notificationsEnabled = value),
                            activeColor: const Color(0xFF00C853),
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          icon: Icons.sync,
                          title: 'Data Sync',
                          subtitle: 'Automatically sync health data',
                          trailing: Switch(
                            value: _dataSyncEnabled,
                            onChanged: (value) => setState(() => _dataSyncEnabled = value),
                            activeColor: const Color(0xFF00C853),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  _buildSecuritySection(),

                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isSyncingWearable
                                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)))
                                : const Icon(Icons.watch, color: Colors.blue),
                          ),
                          title: const Text('Sync with Wearable', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: const Text('Connect to smartwatch/fitness tracker'),
                          trailing: ElevatedButton(
                            onPressed: _isSyncingWearable ? null : _syncWithWearable,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            child: _isSyncingWearable
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Sync'),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isExportingData
                                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)))
                                : const Icon(Icons.download, color: Colors.green),
                          ),
                          title: const Text('Export Health Data', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: const Text('Download your health records'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: _isExportingData
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.picture_as_pdf),
                                onPressed: _isExportingData ? null : () => _exportData('PDF'),
                              ),
                              IconButton(
                                icon: _isExportingData
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.grid_on),
                                onPressed: _isExportingData ? null : () => _exportData('CSV'),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          icon: Icons.delete,
                          title: 'Delete Account',
                          subtitle: 'Permanently remove your account and data',
                          trailing: IconButton(icon: const Icon(Icons.chevron_right), onPressed: _deleteAccount),
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoggingOut ? null : _logout,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      ),
                      icon: _isLoggingOut
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                          : const Icon(Icons.logout, color: Colors.red),
                      label: _isLoggingOut
                          ? const Text('Logging out...', style: TextStyle(color: Colors.red))
                          : const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}