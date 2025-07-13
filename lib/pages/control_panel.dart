import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'room_control_page.dart';

// ignore: use_key_in_widget_constructors
class ControlPanel extends StatelessWidget {
  final List<Map<String, dynamic>> rooms = [
    {"title": "Bathroom", "icon": Icons.bathtub, "color": Colors.teal},
     {"title": "Kitchen", "icon": Icons.kitchen, "color": Colors.orange},
    {"title": "Living Room", "icon": Icons.tv, "color": Colors.deepPurple},
    {"title": "Bedroom", "icon": Icons.bed, "color": Colors.blueGrey},
    {"title": "Bedroom2", "icon": Icons.bed, "color": Colors.indigo},
    
    
   
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: rooms.map((room) {
        return _buildControlButton(
          context,
          room['title'],
          room['icon'],
          room['color'],
          isDark,
        );
      }).toList(),
    );
  }

  Widget _buildControlButton(BuildContext context, String title, IconData icon, Color color, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RoomControlPage(
            roomName: title)),
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              // ignore: deprecated_member_use
              backgroundColor: color.withOpacity(0.1),
              radius: 30,
              child: Icon(icon, size: 40, color: color),
            ),
            SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
