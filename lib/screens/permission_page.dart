import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'setup_page.dart';
import '../services/notification_permission_service.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool _notificationsGranted = false;
  bool _locationGranted = false;
  bool _healthDataAccess = false;
  bool _biometricAccess = false;
  bool _wearableConnected = false;
  bool _cameraAccess = false;
  
  bool _isCheckingNotifications = false;
  String? _notificationError;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    setState(() {
      _isCheckingNotifications = true;
      _notificationError = null;
    });
    
    try {
      final isGranted = await NotificationPermissionService.checkNotificationPermission();
      if (mounted) {
        setState(() {
          _notificationsGranted = isGranted;
          _isCheckingNotifications = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notificationError = e.toString();
          _isCheckingNotifications = false;
        });
      }
    }
  }

  Future<void> _requestNotificationsPermission() async {
    setState(() {
      _isCheckingNotifications = true;
      _notificationError = null;
    });
    
    try {
      final isGranted = await NotificationPermissionService.requestNotificationPermission();
      
      if (mounted) {
        setState(() {
          _notificationsGranted = isGranted;
          _isCheckingNotifications = false;
        });
        
        if (isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications enabled successfully'),
              backgroundColor: Color(0xFF00C853),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _showPermissionDeniedDialog('notifications');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notificationError = e.toString();
          _isCheckingNotifications = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting notification permission: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _requestLocationPermission() async {
    // TODO: Implement real location permission
    setState(() => _locationGranted = true);
  }

  void _requestHealthDataAccess() async {
    // TODO: Implement health data permission (Health Connect/HealthKit)
    setState(() => _healthDataAccess = true);
  }

  void _requestBiometricAccess() async {
    // TODO: Implement biometric/fingerprint permission
    setState(() => _biometricAccess = true);
  }

  void _connectWearable() async {
    // TODO: Implement wearable connection
    setState(() => _wearableConnected = true);
  }

  void _requestCameraAccess() async {
    // TODO: Implement camera permission for food scanning
    setState(() => _cameraAccess = true);
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Denied'),
        content: Text(
          'You have denied $permissionType permission. You can enable it later in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationPermissionService.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
    required VoidCallback onGrant,
    Color? iconColor,
    bool isLoading = false,
    String? error,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: granted ? const Color(0xFF00C853) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF00C853)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading 
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : Icon(icon, color: iconColor ?? const Color(0xFF00C853)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      error,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 50,
                height: 30,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Switch(
                value: granted,
                onChanged: (value) => onGrant(),
                activeColor: const Color(0xFF00C853),
              ),
          ],
        ),
      ),
    );
  }

  int _getGrantedCount() {
    int count = 0;
    if (_notificationsGranted) count++;
    if (_locationGranted) count++;
    if (_healthDataAccess) count++;
    if (_biometricAccess) count++;
    if (_wearableConnected) count++;
    if (_cameraAccess) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final grantedCount = _getGrantedCount();
    final totalCount = 6;
    final progress = grantedCount / totalCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Permissions & Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enable Features for Better Experience',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Grant permissions to unlock full app functionality',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Progress Indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Setup Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$grantedCount/$totalCount completed',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF00C853),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Notifications Permission (REAL IMPLEMENTATION)
              _buildPermissionCard(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                description: _notificationsGranted
                    ? '✓ Enabled - You will receive health reminders and alerts'
                    : 'Get health reminders, medication alerts, and progress updates',
                granted: _notificationsGranted,
                onGrant: _requestNotificationsPermission,
                iconColor: Colors.orange,
                isLoading: _isCheckingNotifications,
                error: _notificationError,
              ),
              const SizedBox(height: 16),

              // Location Permission
              _buildPermissionCard(
                icon: Icons.location_on_outlined,
                title: 'Location Access',
                description: 'Track outdoor activities and environmental health factors',
                granted: _locationGranted,
                onGrant: _requestLocationPermission,
                iconColor: Colors.blue,
              ),
              const SizedBox(height: 16),

              // Health Data Access
              _buildPermissionCard(
                icon: Icons.favorite_border,
                title: 'Health Data Sync',
                description: 'Connect with Apple Health/Google Fit for comprehensive tracking',
                granted: _healthDataAccess,
                onGrant: _requestHealthDataAccess,
                iconColor: Colors.red,
              ),
              const SizedBox(height: 16),

              // Biometric Access
              _buildPermissionCard(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                description: 'Enable fingerprint or face ID for quick and secure access',
                granted: _biometricAccess,
                onGrant: _requestBiometricAccess,
                iconColor: Colors.purple,
              ),
              const SizedBox(height: 16),

              // Wearable Connection
              _buildPermissionCard(
                icon: Icons.watch,
                title: 'Wearable Devices',
                description: 'Sync with smartwatches and fitness trackers',
                granted: _wearableConnected,
                onGrant: _connectWearable,
                iconColor: Colors.teal,
              ),
              const SizedBox(height: 16),

              // Camera Access
              _buildPermissionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Camera Access',
                description: 'Scan food items and medications for logging',
                granted: _cameraAccess,
                onGrant: _requestCameraAccess,
              ),

              const SizedBox(height: 40),

              // Information Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00C853).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF00C853)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You can change these permissions anytime in Settings',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Notifications are required for medication reminders and health alerts',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: grantedCount < 1
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SetupPage()),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Setup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}