import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:spendwise/models/todo_task.dart';

class TodoNotificationService {
  static final TodoNotificationService _instance =
      TodoNotificationService._internal();
  factory TodoNotificationService() => _instance;
  TodoNotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'todo_reminders';
  static const _channelName = 'Rappels Tâches';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) { debugPrint('TodoNotificationService.init exactAlarms: $e'); }

    // Create notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> scheduleReminder(TodoTask task) async {
    if (task.id == null) return;
    if (task.dueDate.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime(
      tz.local,
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.dueDate.hour,
      task.dueDate.minute,
    );

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const notifDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      task.id.hashCode,
      task.title,
      '${task.isDeposit ? "+" : "-"} ${task.amount.toStringAsFixed(0)}',
      scheduledDate,
      notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  Future<void> cancelReminder(String todoId) async {
    await _plugin.cancel(todoId.hashCode);
  }

  Future<void> rescheduleAll(List<TodoTask> todos) async {
    await _plugin.cancelAll();
    for (final todo in todos) {
      if (!todo.isCompleted) {
        await scheduleReminder(todo);
      }
    }
  }
}
