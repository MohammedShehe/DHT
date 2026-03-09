import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    setState(() => _isCheckingNotifications = true);
    final isGranted = await NotificationPermissionService.checkNotificationPermission();
    if (mounted) {
      setState(() {
        _notificationsGranted = isGranted;
        _isCheckingNotifications = false;
      });
    }
  }

  Future<void> _requestNotificationsPermission() async {
    setState(() => _isCheckingNotifications = true);
    final isGranted = await NotificationPermissionService.requestNotificationPermission();
    if (mounted) {
      setState(() {
        _notificationsGranted = isGranted;
        _isCheckingNotifications = false;
      });
    }
  }

  void _requestLocationPermission() {
    setState(() => _locationGranted = true);
  }

  void _requestHealthDataAccess() {
    setState(() => _healthDataAccess = true);
  }

  void _requestBiometricAccess() {
    setState(() => _biometricAccess = true);
  }

  void _connectWearable() {
    setState(() => _wearableConnected = true);
  }

  void _requestCameraAccess() {
    setState(() => _cameraAccess = true);
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
    required VoidCallback onGrant,
    Color? iconColor,
    bool isLoading = false,
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(width: 50, height: 30, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions & Settings', style: TextStyle(fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enable Features for Better Experience',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text('Grant permissions to unlock full app functionality',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 32),

              _buildPermissionCard(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                description: 'Get health reminders, medication alerts, and progress updates',
                granted: _notificationsGranted,
                onGrant: _requestNotificationsPermission,
                iconColor: Colors.orange,
                isLoading: _isCheckingNotifications,
              ),
              const SizedBox(height: 16),

              _buildPermissionCard(
                icon: Icons.location_on_outlined,
                title: 'Location Access',
                description: 'Track outdoor activities and environmental health factors',
                granted: _locationGranted,
                onGrant: _requestLocationPermission,
                iconColor: Colors.blue,
              ),
              const SizedBox(height: 16),

              _buildPermissionCard(
                icon: Icons.favorite_border,
                title: 'Health Data Sync',
                description: 'Connect with Apple Health/Google Fit for comprehensive tracking',
                granted: _healthDataAccess,
                onGrant: _requestHealthDataAccess,
                iconColor: Colors.red,
              ),
              const SizedBox(height: 16),

              _buildPermissionCard(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                description: 'Enable fingerprint or face ID for quick and secure access',
                granted: _biometricAccess,
                onGrant: _requestBiometricAccess,
                iconColor: Colors.purple,
              ),
              const SizedBox(height: 16),

              _buildPermissionCard(
                icon: Icons.watch,
                title: 'Wearable Devices',
                description: 'Sync with smartwatches and fitness trackers',
                granted: _wearableConnected,
                onGrant: _connectWearable,
                iconColor: Colors.teal,
              ),
              const SizedBox(height: 16),

              _buildPermissionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Camera Access',
                description: 'Scan food items and medications for logging',
                granted: _cameraAccess,
                onGrant: _requestCameraAccess,
              ),

              const SizedBox(height: 40),

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
                      child: Text('You can change these permissions anytime in Settings',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue to Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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