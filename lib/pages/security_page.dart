import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key, required String roomName, required Null Function(dynamic message) onAlert});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  String gasSensorStatus = "Normal";
  String flameSensorStatus = "Normal";
  String gasValveStatus = "Open";

  final database = FirebaseDatabase.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenToKitchenSensors();
  }

  void _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  void _listenToKitchenSensors() {
    final ref = database.ref('rooms/kitchen');

    ref.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = snapshot.value as Map;

        final gasLevel = (data['gas'] ?? 0).toDouble();
        final flameStatusRaw = data['Flame'] ?? 'off';
        final flameStatus = flameStatusRaw.toString().toLowerCase();

        String newGasStatus = gasLevel >= 80 ? "Alert" : "Normal";
        String newFlameStatus = (flameStatus == "on" || flameStatus == "true" || flameStatus == "1")
            ? "Alert"
            : "Normal";
        String newValveStatus =
            (newGasStatus == "Alert" || newFlameStatus == "Alert") ? "Closed" : "Open";

        final alertTriggered =
            (newGasStatus == "Alert" && gasSensorStatus != "Alert") ||
            (newFlameStatus == "Alert" && flameSensorStatus != "Alert");

        setState(() {
          gasSensorStatus = newGasStatus;
          flameSensorStatus = newFlameStatus;
          gasValveStatus = newValveStatus;
        });

        if (alertTriggered) {
          final now = DateTime.now();
          final formattedDate = DateFormat('yyyy-MM-dd hh:mm:ss a').format(now);

          final alertText = 'Alert in Kitchen! '
              '${newGasStatus == "Alert" ? "Gas Sensor" : "Flame Sensor"} triggered at $formattedDate.';

          _showAlertNotification(alertText);
          _addNotificationToDatabase(alertText); 
          _triggerSoundAndVibration();
        }
      }
    });
  }

  void _showAlertNotification(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'alert_channel',
      'Security Alerts',
      channelDescription: 'Security sensor alert notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Security Alert',
      message,
      notificationDetails,
    );
  }

  void _triggerSoundAndVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000);
    }
  }

  Future<void> _addNotificationToDatabase(String message) async {
    final ref = database.ref('notifications').push();
    await ref.set({
      'message': message,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildStatusTile("Gas Sensor", gasSensorStatus),
        _buildStatusTile("Flame Sensor", flameSensorStatus),
        _buildStatusTile("Gas Valve", gasValveStatus),
      ],
    );
  }

  Widget _buildStatusTile(String title, String status) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: status == "Alert" ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }
}
