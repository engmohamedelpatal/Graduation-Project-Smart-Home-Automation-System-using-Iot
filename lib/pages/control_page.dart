import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'control_panel.dart';
import 'security_page.dart';

class ControlPageA extends StatefulWidget {
  const ControlPageA({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ControlPageAState createState() => _ControlPageAState();
}

class _ControlPageAState extends State<ControlPageA> {
  int _selectedIndex = 0;
  List<String> _notifications = [];
  int _unreadCount = 0;

  final DatabaseReference notificationsRef =
      FirebaseDatabase.instance.ref('notifications');

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      ControlPanel(),
      SecurityPage(
        roomName: 'kitchen',
        onAlert: (message) {
          _handleAlert(message);
        },
      ),
    ];

    _listenToNotifications(); 
  }

  void _handleAlert(String message) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _notifications.add(message);
      _unreadCount++;
    });

    await notificationsRef.push().set({
      'message': message,
      'timestamp': timestamp,
    });

    _triggerSoundAndVibration();
  }

  void _listenToNotifications() {
    notificationsRef.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final List<String> messages = [];

        data.forEach((key, value) {
          final notif = value as Map;
          final message = notif['message'] ?? '';
          messages.add(message);
        });

        if (messages.length > _notifications.length) {
          setState(() {
            _unreadCount += messages.length - _notifications.length;
          });
          _triggerSoundAndVibration();
        }

        setState(() {
          _notifications = messages.reversed.toList(); // الأحدث أولًا
        });
      }
    });
  }

  void _triggerSoundAndVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }

    SystemSound.play(SystemSoundType.alert);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showNotificationsDialog() {
    setState(() {
      _unreadCount = 0;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notifications"),
        content: _notifications.isEmpty
            ? const Text("No new notifications")
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(_notifications[index]),
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Home Control"),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _showNotificationsDialog,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Control"),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: "Security"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
