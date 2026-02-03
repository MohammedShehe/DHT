import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/account_service.dart';
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
  
  // Password fields
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Account deletion fields
  final TextEditingController _deletePasswordController = TextEditingController();
  final TextEditingController _deleteOtpController = TextEditingController();
  
  // Email change fields
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _emailOtpController = TextEditingController();

  // Profile Image
  File? _profileImage;
  bool _isLoading = true;

  // Loading states for various actions
  bool _isUploadingImage = false;
  bool _isChangingPassword = false;
  bool _isUpdatingName = false;
  bool _isChangingEmail = false;
  bool _isVerifyingEmailOtp = false;
  bool _isLoggingOut = false;
  bool _isRequestingAccountDeletion = false;
  bool _isConfirmingAccountDeletion = false;
  bool _isSyncingWearable = false;
  bool _isExportingData = false;

  // Health Stats
  Map<String, dynamic> healthStats = {
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

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
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
      // Check if it's an auth error
      final message = result['message']?.toString().toLowerCase() ?? '';
      if (message.contains('token') || 
          message.contains('unauthorized') ||
          message.contains('expired')) {
        // Token expired or invalid - show message but don't auto-navigate
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session expired. Please logout and login again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Logout',
              onPressed: () {
                _performLogout();
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _performLogout() async {
    if (!mounted) return;
    
    setState(() {
      _isLoggingOut = true;
    });
    
    try {
      final result = await AccountService.logout();
      
      if (!mounted) return;
      
      setState(() {
        _isLoggingOut = false;
      });
      
      if (result['success'] == true) {
        // Clear all navigation history and go to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Logout failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoggingOut = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('An error occurred during logout'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _performAccountDeletion(String otp) async {
    if (!mounted) return;
    
    setState(() {
      _isConfirmingAccountDeletion = true;
    });
    
    try {
      final result = await AccountService.confirmDeleteAccount(otp);
      
      if (!mounted) return;
      
      setState(() {
        _isConfirmingAccountDeletion = false;
      });
      
      if (result['success'] == true) {
        _deletePasswordController.clear();
        _deleteOtpController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted successfully'),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
        
        // Navigate to login screen after successful deletion
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (!mounted) return;
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Account deletion failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isConfirmingAccountDeletion = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during account deletion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null && mounted) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _isUploadingImage = true;
      });
      
      // Upload to server
      final result = await ProfileService.uploadProfilePic(_profileImage!);
      if (!mounted) return;
      
      setState(() {
        _isUploadingImage = false;
      });
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
        // Reload profile to get updated image path
        await _loadProfileData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: themeOptions.map((theme) {
              return ListTile(
                title: Text(theme),
                trailing: _themeMode == ThemeMode.light && theme == 'Light' ||
                        _themeMode == ThemeMode.dark && theme == 'Dark' ||
                        _themeMode == ThemeMode.system && theme == 'System Default'
                    ? const Icon(Icons.check, color: Color(0xFF00C853))
                    : null,
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
        );
      },
    );
  }

  Future<void> _exportData(String type) async {
    if (!mounted) return;
    
    setState(() {
      _isExportingData = true;
    });
    
    // TODO: Implement real export logic
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    if (!mounted) return;
    
    setState(() {
      _isExportingData = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data exported as $type successfully!'),
        backgroundColor: const Color(0xFF00C853),
      ),
    );
  }

  Future<void> _syncWithWearable() async {
    if (!mounted) return;
    
    setState(() {
      _isSyncingWearable = true;
    });
    
    // TODO: Implement wearable sync
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    if (!mounted) return;
    
    setState(() {
      _isSyncingWearable = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully synced with wearable devices!'),
        backgroundColor: Color(0xFF00C853),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_newPasswordController.text.isEmpty ||
        _currentPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all password fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isChangingPassword = true;
    });
    
    final result = await ProfileService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    
    if (!mounted) return;
    
    setState(() {
      _isChangingPassword = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] == true ? const Color(0xFF00C853) : Colors.red,
      ),
    );
    
    if (result['success'] == true) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  Future<void> _updateName() async {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(text: fullName);
        bool isUpdating = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Name'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a name'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      setState(() {
                        isUpdating = true;
                      });
                      
                      final result = await ProfileService.updateName(nameController.text);
                      
                      if (!mounted) return;
                      
                      if (result['success'] == true) {
                        this.setState(() {
                          fullName = nameController.text;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            backgroundColor: const Color(0xFF00C853),
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
                        setState(() {
                          isUpdating = false;
                        });
                      }
                    },
                    child: const Text('Update'),
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }

  void _requestEmailChange() {
    showDialog(
      context: context,
      builder: (context) {
        bool isSendingOtp = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _newEmailController,
                    decoration: const InputDecoration(
                      labelText: 'New Email',
                      border: OutlineInputBorder(),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a new email'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      setState(() {
                        isSendingOtp = true;
                      });
                      
                      final result = await ProfileService.requestEmailChange(_newEmailController.text);
                      
                      if (!mounted) return;
                      
                      setState(() {
                        isSendingOtp = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: result['success'] == true ? const Color(0xFF00C853) : Colors.red,
                        ),
                      );
                      
                      if (result['success'] == true) {
                        Navigator.pop(context);
                        _showEmailOtpDialog();
                      }
                    },
                    child: const Text('Send OTP'),
                  ),
                ]
              ],
            );
          },
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
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Verify OTP'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailOtpController,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check your new email for the OTP',
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter OTP'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      setState(() {
                        isVerifying = true;
                      });
                      
                      final result = await ProfileService.confirmEmailChange(_emailOtpController.text);
                      
                      if (!mounted) return;
                      
                      setState(() {
                        isVerifying = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: result['success'] == true ? const Color(0xFF00C853) : Colors.red,
                        ),
                      );
                      
                      if (result['success'] == true) {
                        setState(() {
                          email = _newEmailController.text;
                        });
                        _newEmailController.clear();
                        _emailOtpController.clear();
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Verify'),
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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
                        Navigator.pop(context); // Close the dialog
                        await _performLogout();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
          );
        },
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        bool isRequesting = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your password'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          setState(() {
                            isRequesting = true;
                          });
                          
                          final result = await AccountService.requestDeleteAccount(_deletePasswordController.text);
                          
                          if (!mounted) return;
                          
                          setState(() {
                            isRequesting = false;
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: result['success'] == true ? const Color(0xFF00C853) : Colors.red,
                            ),
                          );
                          
                          if (result['success'] == true) {
                            Navigator.pop(context);
                            _showDeleteOtpDialog();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Request Deletion'),
                      ),
                    ],
            );
          },
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
          builder: (context, setState) {
            return AlertDialog(
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
                      ),
                      keyboardType: TextInputType.number,
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter OTP'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          setState(() {
                            isConfirming = true;
                          });
                          
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
            );
          },
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
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!) as ImageProvider
                    : (profilePic.isNotEmpty
                        ? NetworkImage('${ApiConfig.baseUrl.replaceAll('/api', '')}/$profilePic') as ImageProvider
                        : const AssetImage('default_avatar.jpg')),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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

  Widget _buildSettingItem(IconData icon, String title, String subtitle, Widget trailing, {VoidCallback? onTap}) {
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
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00C853),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
            
            // Health Stats Grid
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
                  _buildStatCard(
                    'Day Streak',
                    '${healthStats['streak']}',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Total Points',
                    '${healthStats['points']}',
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildStatCard(
                    'Calories Burned',
                    '${healthStats['caloriesBurned']}',
                    Icons.whatshot,
                    Colors.red,
                  ),
                  _buildStatCard(
                    'Steps',
                    '${healthStats['steps']}',
                    Icons.directions_walk,
                    Colors.blue,
                  ),
                ],
              ),
            ),

            // Settings Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          Icons.person,
                          'Personal Information',
                          'Update your profile details',
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: _updateName,
                          ),
                          onTap: _updateName,
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          Icons.email,
                          'Change Email',
                          'Update your email address',
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: _requestEmailChange,
                          ),
                          onTap: _requestEmailChange,
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          Icons.language,
                          'Language',
                          _language,
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _language,
                              items: languages.map((lang) {
                                return DropdownMenuItem(
                                  value: lang,
                                  child: Text(lang),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _language = value!);
                              },
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          Icons.palette,
                          'Theme',
                          themeOptions[_themeMode == ThemeMode.light ? 0 : _themeMode == ThemeMode.dark ? 1 : 2],
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: _showThemeDialog,
                          ),
                          onTap: _showThemeDialog,
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          Icons.science,
                          'Measurement System',
                          _measurementSystem,
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _measurementSystem,
                              items: measurementSystems.map((system) {
                                return DropdownMenuItem(
                                  value: system,
                                  child: Text(system),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _measurementSystem = value!);
                              },
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          Icons.fingerprint,
                          'Biometric Login',
                          'Use fingerprint or face ID',
                          Switch(
                            value: _biometricLogin,
                            onChanged: (value) {
                              setState(() => _biometricLogin = value);
                            },
                            activeColor: const Color(0xFF00C853),
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          Icons.notifications,
                          'Notifications',
                          'Receive health reminders',
                          Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                            },
                            activeColor: const Color(0xFF00C853),
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingItem(
                          Icons.sync,
                          'Data Sync',
                          'Automatically sync health data',
                          Switch(
                            value: _dataSyncEnabled,
                            onChanged: (value) {
                              setState(() => _dataSyncEnabled = value);
                            },
                            activeColor: const Color(0xFF00C853),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Section
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Security',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
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
                  ),

                  const SizedBox(height: 24),

                  // Data Management Section
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Data Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.watch, color: Colors.blue),
                          ),
                          title: const Text(
                            'Sync with Wearable',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text('Connect to smartwatch/fitness tracker'),
                          trailing: ElevatedButton(
                            onPressed: _isSyncingWearable ? null : _syncWithWearable,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: _isSyncingWearable
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
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
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.green,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.download, color: Colors.green),
                          ),
                          title: const Text(
                            'Export Health Data',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text('Download your health records'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: _isExportingData
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf),
                                onPressed: _isExportingData ? null : () => _exportData('PDF'),
                              ),
                              IconButton(
                                icon: _isExportingData
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.grid_on),
                                onPressed: _isExportingData ? null : () => _exportData('CSV'),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          title: const Text(
                            'Delete Account',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text('Permanently remove your account and data'),
                          trailing: IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _deleteAccount,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoggingOut ? null : _logout,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      ),
                      icon: _isLoggingOut
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                          : const Icon(Icons.logout, color: Colors.red),
                      label: _isLoggingOut
                          ? const Text(
                              'Logging out...',
                              style: TextStyle(color: Colors.red),
                            )
                          : const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
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