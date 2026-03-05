import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_dialog.dart';
import '../models/notification_models.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Set up message callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.onShowMessage = (String message, {bool isError = false}) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.red : Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      };
    });
  }

  @override
  void dispose() {
    try {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.disposeCallbacks();
    } catch (e) {
      // Provider might not be available
    }
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateNotificationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationDialog(
        onNotificationCreated: (preference) {
          // Refresh the list
          final provider = Provider.of<NotificationProvider>(context, listen: false);
          provider.loadPreferences();
        },
      ),
    );
  }

  void _showEditNotificationDialog(NotificationPreference preference) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationDialog(
        existingPreference: preference,
        onNotificationCreated: (updated) {
          final provider = Provider.of<NotificationProvider>(context, listen: false);
          provider.loadPreferences();
        },
      ),
    );
  }

  void _showDeleteConfirmation(NotificationPreference preference) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${preference.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (preference.id != null) {
                final provider = Provider.of<NotificationProvider>(context, listen: false);
                await provider.deletePreference(preference.id!);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('This will reset all notifications to default settings. Custom notifications will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<NotificationProvider>(context, listen: false);
              await provider.resetToDefaults();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.amber),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'Reminders'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.devices), text: 'Devices'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<NotificationProvider>(context, listen: false);
              provider.loadPreferences();
              provider.loadHistory();
              provider.loadTokens();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshed'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Reset to Defaults'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'reset') {
                _showResetConfirmation();
              }
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.preferences.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRemindersTab(provider),
              _buildHistoryTab(provider),
              _buildDevicesTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateNotificationDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRemindersTab(NotificationProvider provider) {
    if (provider.preferences.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No reminders set',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to create your first reminder',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.preferences.length,
      itemBuilder: (context, index) {
        final pref = provider.preferences[index];
        return _buildReminderCard(context, pref, provider);
      },
    );
  }

  Widget _buildReminderCard(BuildContext context, NotificationPreference pref, NotificationProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: pref.isEnabled ? null : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: pref.isEnabled 
                        ? pref.actionColor.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    pref.actionIcon,
                    color: pref.isEnabled ? pref.actionColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pref.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: pref.isEnabled ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pref.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: pref.isEnabled ? Colors.grey[600] : Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: pref.isEnabled,
                  onChanged: (value) {
                    if (pref.id != null) {
                      provider.togglePreference(pref.id!, value);
                    }
                  },
                  activeColor: pref.actionColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time and days
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: pref.isEnabled 
                        ? pref.actionColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time, 
                        size: 14, 
                        color: pref.isEnabled ? pref.actionColor : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pref.time.format(context),
                        style: TextStyle(
                          fontSize: 12,
                          color: pref.isEnabled ? pref.actionColor : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: pref.isEnabled 
                        ? pref.actionColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat, 
                        size: 14, 
                        color: pref.isEnabled ? pref.actionColor : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pref.formattedDays,
                        style: TextStyle(
                          fontSize: 12,
                          color: pref.isEnabled ? pref.actionColor : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pref.actionType != null && pref.actionType!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: pref.isEnabled 
                          ? pref.actionColor.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link, 
                          size: 14, 
                          color: pref.isEnabled ? pref.actionColor : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getActionLabel(pref.actionType!),
                          style: TextStyle(
                            fontSize: 12,
                            color: pref.isEnabled ? pref.actionColor : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Predefined badge
            if (pref.isPredefined) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'Predefined',
                      style: TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditNotificationDialog(pref),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: pref.actionColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    if (pref.id != null) {
                      if (pref.isPredefined) {
                        // For predefined, just disable instead of delete
                        provider.togglePreference(pref.id!, false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Predefined notification disabled'),
                            backgroundColor: Colors.amber,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        _showDeleteConfirmation(pref);
                      }
                    }
                  },
                  icon: Icon(
                    pref.isPredefined ? Icons.block : Icons.delete_outline,
                    size: 16,
                    color: pref.isPredefined ? Colors.amber : Colors.red,
                  ),
                  label: Text(
                    pref.isPredefined ? 'Disable' : 'Delete',
                    style: TextStyle(
                      color: pref.isPredefined ? Colors.amber : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(NotificationProvider provider) {
    if (provider.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No notification history',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Notifications you receive will appear here',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.history.length,
      itemBuilder: (context, index) {
        final history = provider.history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: history.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                history.statusIcon,
                color: history.statusColor,
                size: 20,
              ),
            ),
            title: Text(
              history.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.yMMMd().add_jm().format(history.scheduledFor),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: history.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                history.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: history.statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDevicesTab(NotificationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registered Devices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          if (provider.tokens.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.devices_other, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No devices registered',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This device will be registered when you receive notifications',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.tokens.map((token) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getDeviceColor(token.deviceType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getDeviceIcon(token.deviceType),
                        color: _getDeviceColor(token.deviceType),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            token.deviceName ?? 'Unknown Device',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Type: ${token.deviceType ?? 'Unknown'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Last used: ${DateFormat.yMMMd().add_jm().format(token.lastUsed)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Device'),
                            content: Text('Remove ${token.deviceName ?? 'this device'} from notifications?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.removeToken(token.fcmToken);
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )),

          const SizedBox(height: 24),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Devices are automatically registered when you log in. You can manage them here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getActionLabel(String actionType) {
    switch (actionType) {
      case 'open_activity': return 'Opens Activity';
      case 'log_water': return 'Log Water';
      case 'log_meal': return 'Log Meal';
      case 'take_medication': return 'Take Medication';
      case 'meditate': return 'Meditate';
      default: return '';
    }
  }

  IconData _getDeviceIcon(String? deviceType) {
    if (deviceType == null) return Icons.devices;
    switch (deviceType.toLowerCase()) {
      case 'android': return Icons.android;
      case 'ios': return Icons.phone_iphone;
      case 'web': return Icons.web;
      default: return Icons.devices;
    }
  }

  Color _getDeviceColor(String? deviceType) {
    if (deviceType == null) return Colors.grey;
    switch (deviceType.toLowerCase()) {
      case 'android': return Colors.green;
      case 'ios': return Colors.grey;
      case 'web': return Colors.blue;
      default: return Colors.grey;
    }
  }
}