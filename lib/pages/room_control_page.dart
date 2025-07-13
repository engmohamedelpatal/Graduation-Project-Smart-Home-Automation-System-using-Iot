import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RoomControlPage extends StatefulWidget {
  final String roomName;

  const RoomControlPage({super.key, required this.roomName});

  @override
  State<RoomControlPage> createState() => _RoomControlPageState();
}

class _RoomControlPageState extends State<RoomControlPage> {
  bool lightOn = false;
  bool fanOn = false;
  bool doorOpen = false;
  bool windowOpen = false;
  bool exhaustFanOn = false;
  bool exLightOn = false;

  double temperature = 0;
  double humidity = 0;
  String flameStatus = "off";
  double gasLevel = 0.0;

  String lastUpdated = '';

  final database = FirebaseDatabase.instance;

  final Map<String, List<String>> roomDevices = {
    "bathroom": ["light", "exhaust_fan"],
    "kitchen": ["light", "exhaust_fan", "ex_light"],
    "living room": ["light", "ex_light", "fan"],
    "bedroom": ["light", "fan"],
    "bedroom2": ["light", "fan", "window", "ex_light"],
  };

  bool _shouldShow(String device) {
    final allowedDevices = roomDevices[widget.roomName.toLowerCase()] ?? [];
    return allowedDevices.contains(device);
  }

  @override
  void initState() {
    super.initState();
    _listenToDeviceStates();
  }

  void _listenToDeviceStates() {
    final ref = database.ref('rooms/${widget.roomName.toLowerCase()}');

    ref.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = snapshot.value as Map;

        setState(() {
          lightOn = data['light'] == 'on';
          fanOn = data['fan'] == 'on';
          doorOpen = data['door'] == 'on';
          windowOpen = data['window'] == 'on';
          exhaustFanOn = data['exhaust_fan'] == 'on';
          exLightOn = data['ex_light'] == 'on';

          final rawTemp = data['Temperature'];
          temperature = rawTemp is num ? rawTemp.toDouble() : double.tryParse('$rawTemp') ?? 0.0;

          final rawHum = data['Humidity'];
          humidity = rawHum is num ? rawHum.toDouble() : double.tryParse('$rawHum') ?? 0.0;

          final flameRaw = data['Flame'] ?? 'off';
          flameStatus = flameRaw.toString().toLowerCase() == 'on' ||
                        flameRaw == true || flameRaw == 1 ? 'on' : 'off';

          if (widget.roomName.toLowerCase() == "kitchen") {
            final rawGas = data['gas'];
            gasLevel = rawGas is num ? rawGas.toDouble() : double.tryParse('$rawGas') ?? 0.0;
          }

          if (data['updated_at'] != null) {
            final timestamp = data['updated_at'];
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
            lastUpdated =
                "${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
          }
        });
      }
    });
  }

  Future<void> _updateDeviceState(String device, bool state) async {
    final ref = database.ref('rooms/${widget.roomName.toLowerCase()}');
    await ref.update({
      device.toLowerCase(): state ? 'on' : 'off',
      'updated_at': ServerValue.timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.roomName} Controls")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (lastUpdated.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Last updated: $lastUpdated",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          _buildMeasurementTile(
            icon: Icons.thermostat,
            title: "Temperature",
            value: "${temperature.toStringAsFixed(1)}°C",
          ),
          _buildMeasurementTile(
            icon: Icons.water_drop,
            title: "Humidity",
            value: "${humidity.toStringAsFixed(1)}%",
          ),
          _buildMeasurementTile(
            icon: Icons.local_fire_department,
            title: "Flame",
            value: flameStatus == "on" ? "Detected" : "Normal",
          ),
          if (widget.roomName.toLowerCase() == "kitchen")
            _buildMeasurementTile(
              icon: Icons.gas_meter,
              title: "Gas Level",
              value: "${gasLevel.toStringAsFixed(2)} ppm",
            ),
          const Divider(),
          if (_shouldShow("light"))
            _buildToggleTile("Light", lightOn, (val) {
              _updateDeviceState("light", val);
            }),
          if (_shouldShow("fan"))
            _buildToggleTile("Fan", fanOn, (val) {
              _updateDeviceState("fan", val);
            }),
          if (_shouldShow("door"))
            _buildToggleTile("Door", doorOpen, (val) {
              _updateDeviceState("door", val);
            }),
          if (_shouldShow("window"))
            _buildToggleTile("Window", windowOpen, (val) {
              _updateDeviceState("window", val);
            }),
          if (_shouldShow("exhaust_fan"))
            _buildToggleTile("Exhaust Fan", exhaustFanOn, (val) {
              _updateDeviceState("exhaust_fan", val);
            }),
          if (_shouldShow("ex_light"))
            _buildToggleTile("Ex Light", exLightOn, (val) {
              _updateDeviceState("ex_light", val);
            }),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (val) {
        setState(() {}); 
        onChanged(val);  
      },
    );
  }

  Widget _buildMeasurementTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
