  import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalexam/database_helper.dart';
  import 'package:flutter/material.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'firebase_options.dart';
  import 'devicelist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final DatabaseHelper dbHelper = DatabaseHelper();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference devices = firestore.collection("Devices");

  List<Map<String, dynamic>> deviceList = [];

  try {
    print("📡 Fetching from Firestore...");
    final QuerySnapshot snapshot = await devices.get();
    deviceList = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();

    for (var device in deviceList) {
      await dbHelper.insertOrUpdateDevice(device);
    }

  } catch (e) {
    print("⚠️ Firestore failed. Loading from SQLite...");
    deviceList = await dbHelper.getDevices();
  }

  runApp(MyApp(deviceList: deviceList));
}

  class MyApp extends StatelessWidget {
    final List<Map<String, dynamic>> deviceList;

    const MyApp({super.key, required this.deviceList});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Flutter Firebase Web',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: HomePage(deviceList: deviceList),
      );
    }
  }

  // ✅ Fix: Prevent automatic back navigation by using a StatefulWidget
  class HomePage extends StatefulWidget {
    final List<Map<String, dynamic>> deviceList;

    const HomePage({super.key, required this.deviceList});

    @override
    State<HomePage> createState() => _HomePageState();
  }

  class _HomePageState extends State<HomePage> {
    bool _navigated = false; // Prevent duplicate navigation

    @override
    void initState() {
      super.initState();

      // ✅ Navigate only ONCE after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_navigated) {
          _navigated = true; // Prevent multiple navigations
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceList(deviceList: widget.deviceList),
            ),
          );
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()), 
      );
    }
  }
