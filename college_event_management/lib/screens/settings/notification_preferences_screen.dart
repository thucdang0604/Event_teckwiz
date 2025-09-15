import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/unified_notification_service.dart';
import '../../services/notification_service.dart';
import '../../constants/app_colors.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final UnifiedNotificationService _notificationService =
      UnifiedNotificationService();

  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId != null) {
        _preferences = await _notificationService.getUserPreferences(userId);
      }
    } catch (e) {
      print('Error loading preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _notificationService.saveUserPreferences(_preferences!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _updateChannelPreference(
    NotificationType type,
    NotificationChannel channel,
  ) {
    setState(() {
      _preferences = NotificationPreferences(
        userId: _preferences!.userId,
        channelPreferences: Map.from(_preferences!.channelPreferences)
          ..[type] = channel,
        enabledTypes: _preferences!.enabledTypes,
        emailEnabled: _preferences!.emailEnabled,
        pushEnabled: _preferences!.pushEnabled,
        quietHoursStart: _preferences!.quietHoursStart,
        quietHoursEnd: _preferences!.quietHoursEnd,
        preferredLanguages: _preferences!.preferredLanguages,
      );
    });
  }

  void _updateEnabledType(NotificationType type, bool enabled) {
    setState(() {
      _preferences = NotificationPreferences(
        userId: _preferences!.userId,
        channelPreferences: _preferences!.channelPreferences,
        enabledTypes: Map.from(_preferences!.enabledTypes)..[type] = enabled,
        emailEnabled: _preferences!.emailEnabled,
        pushEnabled: _preferences!.pushEnabled,
        quietHoursStart: _preferences!.quietHoursStart,
        quietHoursEnd: _preferences!.quietHoursEnd,
        preferredLanguages: _preferences!.preferredLanguages,
      );
    });
  }

  void _updateEmailEnabled(bool enabled) {
    setState(() {
      _preferences = NotificationPreferences(
        userId: _preferences!.userId,
        channelPreferences: _preferences!.channelPreferences,
        enabledTypes: _preferences!.enabledTypes,
        emailEnabled: enabled,
        pushEnabled: _preferences!.pushEnabled,
        quietHoursStart: _preferences!.quietHoursStart,
        quietHoursEnd: _preferences!.quietHoursEnd,
        preferredLanguages: _preferences!.preferredLanguages,
      );
    });
  }

  void _updatePushEnabled(bool enabled) {
    setState(() {
      _preferences = NotificationPreferences(
        userId: _preferences!.userId,
        channelPreferences: _preferences!.channelPreferences,
        enabledTypes: _preferences!.enabledTypes,
        emailEnabled: _preferences!.emailEnabled,
        pushEnabled: enabled,
        quietHoursStart: _preferences!.quietHoursStart,
        quietHoursEnd: _preferences!.quietHoursEnd,
        preferredLanguages: _preferences!.preferredLanguages,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_preferences == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Unable to load notification settings')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePreferences,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSettings(),
            const SizedBox(height: 24),
            _buildNotificationTypes(),
            const SizedBox(height: 24),
            _buildChannelPreferences(),
            const SizedBox(height: 24),
            _buildQuietHours(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: _preferences!.emailEnabled,
              onChanged: _updateEmailEnabled,
              activeColor: AppColors.primary,
            ),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on device'),
              value: _preferences!.pushEnabled,
              onChanged: _updatePushEnabled,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...NotificationType.values.map((type) {
              final isEnabled = _preferences!.enabledTypes[type] ?? false;
              return SwitchListTile(
                title: Text(_getNotificationTypeTitle(type)),
                subtitle: Text(_getNotificationTypeDescription(type)),
                value: isEnabled,
                onChanged: (value) => _updateEnabledType(type, value),
                activeColor: AppColors.primary,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelPreferences() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Channels',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how to receive notifications for each type',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...NotificationType.values.map((type) {
              final isEnabled = _preferences!.enabledTypes[type] ?? false;
              if (!isEnabled) return const SizedBox.shrink();

              final currentChannel =
                  _preferences!.channelPreferences[type] ??
                  NotificationChannel.both;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getNotificationTypeTitle(type),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: NotificationChannel.values.map((channel) {
                        return Expanded(
                          child: RadioListTile<NotificationChannel>(
                            title: Text(
                              _getChannelTitle(channel),
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: channel,
                            groupValue: currentChannel,
                            onChanged: (value) {
                              if (value != null) {
                                _updateChannelPreference(type, value);
                              }
                            },
                            dense: true,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHours() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiet Hours',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Notifications will be scheduled to send after quiet hours',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(_preferences!.quietHoursStart ?? 'Not set'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectQuietHoursStart,
            ),
            ListTile(
              title: const Text('End Time'),
              subtitle: Text(_preferences!.quietHoursEnd ?? 'Not set'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectQuietHoursEnd,
            ),
          ],
        ),
      ),
    );
  }

  String _getNotificationTypeTitle(NotificationType type) {
    switch (type) {
      case NotificationType.eventCreated:
        return 'New Event';
      case NotificationType.eventUpdated:
        return 'Event Update';
      case NotificationType.eventCancelled:
        return 'Event Cancelled';
      case NotificationType.registrationConfirmed:
        return 'Registration Confirmed';
      case NotificationType.registrationCancelled:
        return 'Registration Cancelled';
      case NotificationType.registrationRejected:
        return 'Registration Rejected';
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.systemAnnouncement:
        return 'System Announcement';
      case NotificationType.chatMessage:
        return 'Chat Message';
      case NotificationType.certificateIssued:
        return 'Certificate Issued';
    }
  }

  String _getNotificationTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.eventCreated:
        return 'Notification when a new event is created';
      case NotificationType.eventUpdated:
        return 'Notification when an event is updated';
      case NotificationType.eventCancelled:
        return 'Notification when an event is cancelled';
      case NotificationType.registrationConfirmed:
        return 'Notification when registration is confirmed';
      case NotificationType.registrationCancelled:
        return 'Notification when registration is cancelled';
      case NotificationType.registrationRejected:
        return 'Notification when registration is rejected';
      case NotificationType.eventReminder:
        return 'Reminder before event starts';
      case NotificationType.systemAnnouncement:
        return 'System announcements';
      case NotificationType.chatMessage:
        return 'Messages in chat';
      case NotificationType.certificateIssued:
        return 'When you receive a certificate';
    }
  }

  String _getChannelTitle(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.push:
        return 'Push';
      case NotificationChannel.email:
        return 'Email';
      case NotificationChannel.both:
        return 'Both';
      case NotificationChannel.none:
        return 'Off';
    }
  }

  Future<void> _selectQuietHoursStart() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _preferences = NotificationPreferences(
          userId: _preferences!.userId,
          channelPreferences: _preferences!.channelPreferences,
          enabledTypes: _preferences!.enabledTypes,
          emailEnabled: _preferences!.emailEnabled,
          pushEnabled: _preferences!.pushEnabled,
          quietHoursStart:
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
          quietHoursEnd: _preferences!.quietHoursEnd,
          preferredLanguages: _preferences!.preferredLanguages,
        );
      });
    }
  }

  Future<void> _selectQuietHoursEnd() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _preferences = NotificationPreferences(
          userId: _preferences!.userId,
          channelPreferences: _preferences!.channelPreferences,
          enabledTypes: _preferences!.enabledTypes,
          emailEnabled: _preferences!.emailEnabled,
          pushEnabled: _preferences!.pushEnabled,
          quietHoursStart: _preferences!.quietHoursStart,
          quietHoursEnd:
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
          preferredLanguages: _preferences!.preferredLanguages,
        );
      });
    }
  }
}
