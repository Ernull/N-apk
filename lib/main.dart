import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEF4056)),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tahoma')),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar("لطفا لینک را وارد کنید", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"X-Client-App": "JetApp-Secure-Client"},
      );

      if (response.statusCode != 200) {
        throw Exception("Server Error: ${response.statusCode}");
      }

      final Map<String, dynamic> data = json.decode(response.body);
      
      List<dynamic> cookies = [];
      var sessionData = data['session'];

      if (sessionData is List) {
        cookies = sessionData;
      } else if (sessionData is Map && sessionData['cookies'] is List) {
        cookies = sessionData['cookies'];
      } else {
        throw Exception("فرمت کوکی یافت نشد");
      }

      final cookieManager = WebViewCookieManager();
      for (var cookie in cookies) {
        String domain = (cookie['domain'] ?? '').toString();
        if (domain.startsWith('.')) domain = domain.substring(1);
        
        await cookieManager.setCookie(
          WebViewCookie(
            name: cookie['name'].toString(),
            value: cookie['value'].toString(),
            domain: domain,
            path: (cookie['path'] ?? '/').toString(),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WebScreen()),
      );

    } catch (e) {
      _showSnackBar("خطا: ارتباط ناموفق بود یا لینک نامعتبر است", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEF4056), Color(0xFF991733), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 90, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    "Nexus Digikala",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "ورود به حساب",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tahoma'),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _urlController,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: "https://your-domain.com/auth/token",
                            prefixIcon: const Icon(Icons.link, color: Color(0xFFEF4056)),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4056),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("اتصال امن و ورود", style: TextStyle(fontSize: 16, fontFamily: 'Tahoma')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse("https://www.digikala.com/profile/"));
  }

  Future<void> _logout() async {
    await WebViewCookieManager().clearCookies();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("دیجی‌کالا", style: TextStyle(fontFamily: 'Tahoma')),
        centerTitle: true,
        backgroundColor: const Color(0xFFEF4056),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "پاکسازی نشست و خروج",
          )
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Color(0xFFEF4056))),
        ],
      ),
    );
  }
}
