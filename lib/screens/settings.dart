import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/services/notification_service.dart';
import '../constants/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyNotificationsEnabled = true;
  TimeOfDay _dailyNotificationTime = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _defaultReminderTime = TimeOfDay(hour: 9, minute: 0);
  String _selectedLanguage = 'Türkçe';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final hour = prefs.getInt('reminder_hour') ?? 9;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _defaultReminderTime = TimeOfDay(hour: hour, minute: minute);

      _dailyNotificationsEnabled =
          prefs.getBool('daily_notifications_enabled') ?? true;
      final dailyHour = prefs.getInt('daily_notification_hour') ?? 8;
      final dailyMinute = prefs.getInt('daily_notification_minute') ?? 0;
      _dailyNotificationTime = TimeOfDay(hour: dailyHour, minute: dailyMinute);

      _selectedLanguage = prefs.getString('language') ?? 'Türkçe';

      if (_dailyNotificationsEnabled) {
        NotificationService().scheduleDailyNotification(
          hour: _dailyNotificationTime.hour,
          minute: _dailyNotificationTime.minute,
        );
      }
    });
  }

Future<void> _saveSettings() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('notifications_enabled', _notificationsEnabled);
  await prefs.setBool('daily_notification_enabled', _dailyNotificationsEnabled); // Anahtar değişti
  await prefs.setInt('reminder_hour', _defaultReminderTime.hour);
  await prefs.setInt('reminder_minute', _defaultReminderTime.minute);
  await prefs.setInt('daily_notification_hour', _dailyNotificationTime.hour);
  await prefs.setInt('daily_notification_minute', _dailyNotificationTime.minute);
  await prefs.setString('language', _selectedLanguage);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tdBGColor,
      appBar: AppBar(
        backgroundColor: tdBGColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tdBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
          style: TextStyle(color: tdBlack, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          // Notifications Section
          _buildSectionHeader('Bildirimler'),
          _buildSettingsCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Görev Bildirimleri'),
                  subtitle: Text('Görev hatırlatıcıları al'),
                  value: _notificationsEnabled,
                  activeThumbColor: tdBlue,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Varsayılan Hatırlatma Saati'),
                  subtitle: Text(
                    'Görevden ${_defaultReminderTime.hour.toString().padLeft(2, '0')}:${_defaultReminderTime.minute.toString().padLeft(2, '0')} önce',
                  ),
                  trailing: Icon(Icons.access_time, color: tdBlue),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _defaultReminderTime,
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _defaultReminderTime = picked;
                      });
                      _saveSettings();
                    }
                  },
                ),
                Divider(height: 1),
                SwitchListTile(
                  value: _dailyNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _dailyNotificationsEnabled = value;
                    });
                    _saveSettings();
                    if (value) {
                      NotificationService().scheduleDailyNotification(
                        hour: _dailyNotificationTime.hour,
                        minute: _dailyNotificationTime.minute,
                      );
                    } else {
                      NotificationService().cancelDailyNotification();
                    }
                  },
                  title: Text("Günlük Hatırlatma"),
                  subtitle: Text(
                    "Gün içinde yapacakların hakkında bildirim al",
                  ),
                  activeThumbColor: tdBlue,
                ),
                if (_dailyNotificationsEnabled) ...[
                  Divider(height: 1),
                  ListTile(
                    title: Text("Günlük Hatırlatma Saati"),
                    subtitle: Text(
                      '${_dailyNotificationTime.hour.toString().padLeft(2, '0')}:${_dailyNotificationTime.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: Icon(Icons.access_time, color: tdBlue),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _dailyNotificationTime,
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _dailyNotificationTime = picked;
                        });
                        _saveSettings();

                        // Reschedule daily notification with new time
                        NotificationService().scheduleDailyNotification(
                          hour: _dailyNotificationTime.hour,
                          minute: _dailyNotificationTime.minute,
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 30),

          // App Settings Section
          _buildSectionHeader('Uygulama'),
          _buildSettingsCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language, color: tdBlue),
                  title: Text('Dil'),
                  subtitle: Text(_selectedLanguage),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.palette, color: tdBlue),
                  title: Text('Tema'),
                  subtitle: Text('Açık'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement theme switcher
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Yakında eklenecek!')),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Data Section
          _buildSectionHeader('Veri'),
          _buildSettingsCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.download, color: tdBlue),
                  title: Text('Verileri Dışa Aktar'),
                  subtitle: Text('Görevlerini yedekle'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement export
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Yakında eklenecek!')),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    'Tüm Verileri Sil',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: Text('Bu işlem geri alınamaz'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showDeleteConfirmation();
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // About Section
          _buildSectionHeader('Hakkında'),
          _buildSettingsCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info, color: tdBlue),
                  title: Text('Versiyon'),
                  subtitle: Text('1.0.0'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: tdBlue),
                  title: Text('Gizlilik Politikası'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Show privacy policy
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description, color: tdBlue),
                  title: Text('Kullanım Koşulları'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Show terms
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dil Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Türkçe'),
              value: 'Türkçe',
              groupValue: _selectedLanguage,
              activeColor: tdBlue,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              activeColor: tdBlue,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tüm Verileri Sil?'),
        content: Text('Tüm görevlerin silinecek. Bu işlem geri alınamaz!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('todos');
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Tüm veriler silindi')));
            },
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
