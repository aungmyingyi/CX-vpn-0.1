import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CXVpnApp());
}

class CXVpnApp extends StatelessWidget {
  const CXVpnApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(primaryColor: const Color(0xFFFF8A32)),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isConnected = false;
  final V2rayManager _mgr = V2rayManager();

  @override
  void initState() {
    super.initState();
    _mgr.initialize(onStatusChanged: (status) {
      if (mounted) setState(() => isConnected = status.state.toString().toUpperCase().contains('CONNECTED'));
    });
  }

  Future<void> _connect(String link) async {
    final ready = await _mgr.ensureInitialized();
    if (!ready) return;
    bool? permission = await _mgr.v2ray.requestPermission();
    if (permission != true) return;

    final parser = V2ray.parseFromURL(link);
    _mgr.v2ray.startV2Ray(remark: parser.remark, config: parser.getFullConfiguration());
    setState(() => isConnected = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CX VPN"),
        actions: [
          IconButton(
            icon: Icon(isConnected ? Icons.power_settings_new : Icons.power_off, color: isConnected ? Colors.green : Colors.red),
            onPressed: () {
              if (isConnected) {
                _mgr.v2ray.stopV2Ray();
                setState(() => isConnected = false);
              }
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('servers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No servers found.\nPlease add from Admin App."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Text(data['flag'] ?? "🌐", style: const TextStyle(fontSize: 30)),
                  title: Text(data['name'] ?? "Unknown Server"),
                  subtitle: Text(data['country'] ?? "Custom"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A32)),
                    onPressed: () => _connect(data['link']),
                    child: const Text("Connect", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class V2rayManager {
  V2rayManager._();
  static final V2rayManager _instance = V2rayManager._();
  factory V2rayManager() => _instance;
  late final V2ray v2ray;
  bool _initialized = false;
  void initialize({required Function(dynamic) onStatusChanged}) {
    v2ray = V2ray(onStatusChanged: onStatusChanged);
  }
  Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    await v2ray.initialize(notificationIconResourceType: "mipmap", notificationIconResourceName: "ic_launcher");
    _initialized = true;
    return true;
  }
}
