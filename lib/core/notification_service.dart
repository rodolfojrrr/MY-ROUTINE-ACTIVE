import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app_store.dart';
import 'sync_entity.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {}

    const android = AndroidInitializationSettings('ic_notification');
    final windows = WindowsInitializationSettings(
      appName: 'My Routine Active',
      appUserModelId: 'Rodolfo.MyRoutineActive',
      guid: 'a623f2ce-5c4f-4a73-a6a8-a916db44d6ec',
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: android,
        windows: windows,
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (!_ready) await initialize();
    if (!Platform.isAndroid) return true;
    final implementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await implementation?.requestNotificationsPermission() ?? true;
  }

  Future<void> scheduleReminder(SyncEntity reminder) async {
    if (!_ready) await initialize();
    if (!Platform.isAndroid) return;
    final id = _notificationId(reminder.id);
    await _plugin.cancel(id: id);
    final enabled = reminder.payload['enabled'] != false;
    final date = DateTime.tryParse(reminder.payload['dateTime'] as String? ?? '');
    if (!enabled || date == null || !date.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: reminder.payload['title'] as String? ?? 'My Routine Active',
      body: reminder.payload['notes'] as String? ?? 'Você tem um lembrete agendado.',
      scheduledDate: tz.TZDateTime.from(date, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_reminders',
          'Lembretes da rotina',
          channelDescription: 'Lembretes locais de estudos, treinos e finanças',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'reminder',
    );
  }

  Future<void> syncReminders(AppStore store) async {
    if (!_ready) await initialize();
    if (!Platform.isAndroid) return;
    await _plugin.cancelAll();
    for (final reminder in store.records(EntityTypes.reminder)) {
      await scheduleReminder(reminder);
    }
  }

  Future<void> cancelReminder(String id) async {
    if (!_ready) await initialize();
    if (!Platform.isAndroid) return;
    await _plugin.cancel(id: _notificationId(id));
  }

  int _notificationId(String id) => id.codeUnits.fold<int>(17, (value, unit) {
        return ((value * 31) + unit) & 0x7fffffff;
      });
}
