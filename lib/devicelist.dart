import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class DeviceList extends StatefulWidget {
  final List<Map<String, dynamic>> deviceList;

  const DeviceList({super.key, required this.deviceList});

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DatabaseHelper dbHelper = DatabaseHelper();
  late List<Map<String, dynamic>> devices;

  @override
  void initState() {
    super.initState();
    devices = widget.deviceList;
    _loadOfflineData();
  }

  /// ✅ **Check for Offline Data and Load from SQLite**
  Future<void> _loadOfflineData() async {
    try {
      final offlineDevices = await dbHelper.getDevices();
      if (offlineDevices.isNotEmpty) {
        print("📢 Loaded from SQLite: $offlineDevices");
        setState(() {
          devices = offlineDevices;
        });
      } else {
        print("⚠️ No offline data found in SQLite.");
      }
    } catch (e) {
      print("❌ Error loading offline data: $e");
    }
  }

  void _toggleStatus(String docId, int index, bool currentStatus) async {
    bool newStatus = !currentStatus;
    print("🔄 Updating Status for $docId: $currentStatus → $newStatus");

    try {
      await firestore.collection("Devices").doc(docId).update({'Status': newStatus});
      print("✅ Firestore update successful");

      try {
        await dbHelper.updateDeviceStatus(docId, newStatus);
        print("✅ SQLite update successful");
      } catch (e) {
        print("⚠️ Skipping SQLite update on Web: $e");
      }

      setState(() {
        devices[index]['Status'] = newStatus;
      });
    } catch (e) {
      print("❌ Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("📢 UI Device List: $devices");

    return Scaffold(
      appBar: AppBar(title: Text("Device List")),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];

          return ListTile(
            title: Text(device['DeviceName'] ?? "Unknown Device"),
            subtitle: Text(device['Description'] ?? "No description"),
            trailing: Switch(
              value: device['Status'] ?? false,
              onChanged: (bool newValue) {
                _toggleStatus(device['id'], index, device['Status']);
              },
            ),
          );
        },
      ),
    );
  }
}
