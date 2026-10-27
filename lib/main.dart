import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CXVpnApp());
}

// ==========================================
// 1. User Storage Manager (အကောင့်သိမ်းဆည်းရန်)
// ==========================================
class UserManager {
  static const String _keyCurrentUser = 'current_user';
  
  static Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentUser);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  static Future<bool> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('users_list') ?? [];
    if (users.any((u) => u.split(':')[0] == username)) return false; 
    users.add('$username:$password');
    await prefs.setStringList('users_list', users);
    await prefs.setString(_keyCurrentUser, username);
    return true;
  }

  static Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('users_list') ?? [];
    if (users.contains('$username:$password')) {
      await prefs.setString(_keyCurrentUser, username);
      return true;
    }
    return false;
  }
}

// ==========================================
// 2. Main App & Auth Check
// ==========================================
class CXVpnApp extends StatelessWidget {
  const CXVpnApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final user = await UserManager.getCurrentUser();
    if (!mounted) return;
    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen(username: user)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// ==========================================
// 3. Beautiful Background (Sky, Sun, Leaves)
// ==========================================
class SkyBackground extends StatefulWidget {
  const SkyBackground({super.key});
  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Leaf> _leaves = List.generate(12, (index) => Leaf());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Gradient Sky
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF00D2FF), Color(0xFF00E1D9)],
                ),
              ),
            ),
            // Sun
            Positioned(
              top: 80,
              right: 40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD54F),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withOpacity(0.6),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            // Leaves (Animated)
            ..._leaves.map((leaf) {
              final double progress = (_controller.value + leaf.offset) % 1.0;
              final double yPos = progress * MediaQuery.of(context).size.height;
              final double xPos = leaf.xPos + (sin(progress * 2 * pi) * 40);
              return Positioned(
                top: yPos,
                left: xPos,
                child: Transform.rotate(
                  angle: progress * 4 * pi,
                  child: Icon(
                    Icons.eco,
                    color: const Color(0xFF2E7D32).withOpacity(0.8),
                    size: 28,
                  ),
                ),
              );
            }).toList(),
            // Tree Silhouette (Bottom)
            Positioned(
              bottom: -50,
              left: -50,
              right: -50,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.park, size: 400, color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Leaf {
  final double xPos;
  final double offset;
  Leaf({double? xPos, double? offset})
      : xPos = xPos ?? Random().nextDouble() * 400,
        offset = offset ?? Random().nextDouble();
}

// ==========================================
// 4. Login / Register Screen
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    bool success;
    if (_isLogin) {
      success = await UserManager.login(_userCtrl.text, _passCtrl.text);
    } else {
      success = await UserManager.register(_userCtrl.text, _passCtrl.text);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen(username: _userCtrl.text)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isLogin ? "Invalid Username or Password!" : "Username already exists!"),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const SkyBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('CX VPN', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
                      const SizedBox(height: 10),
                      Text(_isLogin ? 'Welcome Back' : 'Create Account', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _userCtrl,
                        decoration: InputDecoration(
                          labelText: "Username",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A32),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _loading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isLogin ? "Login" : "Register", style: const TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(_isLogin ? "Don't have an account? Register" : "Already have an account? Login", style: const TextStyle(color: Color(0xFF37474F))),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. Main Screen with Bottom Nav
// ==========================================
class MainScreen extends StatefulWidget {
  final String username;
  const MainScreen({super.key, required this.username});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(username: widget.username),
      const ServersPage(),
      const SettingsPage(),
      const PremiumPage(),
    ];

    return Scaffold(
      extendBody: true, // Bottom Nav ကို ဖောက်မြင်စေရန်
      body: Stack(
        children: [
          const SkyBackground(),
          SafeArea(child: IndexedStack(index: _currentIndex, children: pages)),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, "Home"),
              _navItem(1, Icons.public, "Servers"),
              _navItem(2, Icons.settings, "Settings"),
              _navItem(3, Icons.workspace_premium, "Premium"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8A32).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFFF8A32) : Colors.grey[600]),
            if (isSelected) Text(label, style: const TextStyle(color: Color(0xFFFF8A32), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. Home Page (VPN Connection)
// ==========================================
class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = false;
  final V2rayManager _mgr = V2rayManager();

  // နမူနာ ဆာဗာ Link (သင့်ရဲ့ တကယ့် vless link ကို ဒီမှာ ထည့်ပါ)
  final String dummyLink = "vless://e13cf851-b4fd-413b-8d49-146e6eb8e5d4@platform117.golnamakcert.top:80?path=%2Fplatform117&security=&encryption=none&host=platform117.halalkhor.info&type=ws#Singapore"; 

  @override
  void initState() {
    super.initState();
    _mgr.initialize(onStatusChanged: (status) {
      if (mounted) setState(() => isConnected = status.state.toString().toUpperCase().contains('CONNECTED'));
    });
  }

  Future<void> _connect() async {
    final ready = await _mgr.ensureInitialized();
    if (!ready) return;
    bool? permission = await _mgr.v2ray.requestPermission();
    if (permission != true) return;

    final parser = V2ray.parseFromURL(dummyLink);
    _mgr.v2ray.startV2Ray(remark: "Server", config: parser.getFullConfiguration());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("WELCOME BACK", style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
                  Text(widget.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
                ],
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.dark_mode, color: Color(0xFF37474F)), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.settings, color: Color(0xFF37474F)), onPressed: () {}),
                ],
              )
            ],
          ),
        ),
        
        const Spacer(),
        
        // Connect Button
        GestureDetector(
          onTap: () {
            if (isConnected) {
              _mgr.v2ray.stopV2Ray();
            } else {
              _connect();
            }
          },
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
            ),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Icon(Icons.power_settings_new, size: 50, color: isConnected ? Colors.white : const Color(0xFF37474F)),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        Text(
          isConnected ? "CONNECTED" : "NOT CONNECTED",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isConnected ? Colors.green : const Color(0xFF37474F)),
        ),
        const SizedBox(height: 5),
        Text("Tap to connect securely", style: TextStyle(color: Colors.grey[800])),
        
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: isConnected ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Text(isConnected ? "Protected" : "Ready to connect", style: const TextStyle(color: Color(0xFF37474F))),
            ],
          ),
        ),

        const Spacer(),
        
        // Location Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.public, color: Color(0xFFFF8A32)),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("YOUR LOCATION", style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("Auto Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
      ],
    );
  }
}

// ==========================================
// 7. Other Pages (UI Only)
// ==========================================
class ServersPage extends StatelessWidget {
  const ServersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Servers Page (Coming Soon)", style: TextStyle(color: Color(0xFF37474F), fontWeight: FontWeight.bold)));
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Settings Page (Coming Soon)", style: TextStyle(color: Color(0xFF37474F), fontWeight: FontWeight.bold)));
  }
}

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Premium Page (Coming Soon)", style: TextStyle(color: Color(0xFF37474F), fontWeight: FontWeight.bold)));
  }
}

// ==========================================
// 8. V2ray Manager
// ==========================================
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
