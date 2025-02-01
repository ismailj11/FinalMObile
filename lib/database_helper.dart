import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableName = "devices";
  final FirebaseFirestore firestore = FirebaseFirestore.instance; // Firestore for Web

  /// ✅ Check if running on Web
  Future<bool> isWeb() async {
    try {
      return Platform.isAndroid || Platform.isIOS ? false : true;
    } catch (_) {
      return true; // Assume Web if Platform API is unavailable
    }
  }

  /// ✅ Initialize SQLite database (Only on Mobile)
  Future<Database> get database async {
    if (await isWeb()) {
      print("📢 Running on Web, skipping SQLite");
      return Future.error("SQLite not supported on Web");
    }

    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'devices.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print("✅ Creating SQLite Table...");
        await db.execute('''
          CREATE TABLE $tableName(
            id TEXT PRIMARY KEY,
            DeviceName TEXT NOT NULL,
            Description TEXT,
            Status INTEGER NOT NULL  -- Store as 1 (true) or 0 (false)
          )
        ''');
      },
    );
  }

  /// 📥 **Insert or Update Device**
  Future<void> insertOrUpdateDevice(Map<String, dynamic> device) async {
    if (await isWeb()) {
      await firestore.collection("Devices").doc(device['id']).set(device);
      print("✅ Firestore Data Synced: $device");
      return;
    }

    final db = await database;
    final sqliteDevice = {
      'id': device['id'],
      'DeviceName': device['DeviceName'] ?? "Unknown",
      'Description': device['Description'] ?? "",
      'Status': (device['Status'] == true) ? 1 : 0, // Convert bool to 1/0
    };

    print("📝 Inserting into SQLite: $sqliteDevice");

    await db.insert(
      tableName,
      sqliteDevice,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    List<Map<String, dynamic>> savedDevices = await getDevices();
    print("📢 SQLite After Insert: $savedDevices");
  }

  /// 📤 **Get Devices**
  Future<List<Map<String, dynamic>>> getDevices() async {
    if (await isWeb()) {
      final snapshot = await firestore.collection("Devices").get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    }

    final db = await database;
    final List<Map<String, dynamic>> data = await db.query(tableName);

    print("📢 Retrieved from SQLite: $data");

    if (data.isEmpty) {
      print("⚠️ No offline data found in SQLite.");
    }

    return data.map((device) {
      return {
        'id': device['id'],
        'DeviceName': device['DeviceName'] ?? "Unknown",
        'Description': device['Description'] ?? "",
        'Status': (device['Status'] as int) == 1,
      };
    }).toList();
  }

  /// 🔄 **Update Device Status**
  Future<void> updateDeviceStatus(String id, bool newStatus) async {
    if (await isWeb()) {
      await firestore.collection("Devices").doc(id).update({'Status': newStatus});
      print("✅ Firestore Status Updated: $id → $newStatus");
      return;
    }

    final db = await database;
    await db.update(
      tableName,
      {'Status': newStatus ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    List<Map<String, dynamic>> savedDevices = await getDevices();
    print("📢 SQLite After Status Update: $savedDevices");
  }
}
