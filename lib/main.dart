import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/signin_page.dart';
import 'pages/MainScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Ensures Flutter is ready before loading anything

  try {
    await dotenv.load(fileName: ".env"); // ✅ Load environment variables
  } catch (e) {
    print(
      "❌ Error: .env file not found. Make sure it exists in the project root.",
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    setState(() {
      _isAuthenticated = token != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Boarding Expenses',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          _isLoading
              ? const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ), // ✅ Show loading screen first
              )
              : _isAuthenticated
              ? const MainScreen() // ✅ Redirect to Main Screen if authenticated
              : const SignInPage(), // ✅ Otherwise, go to SignInPage
    );
  }
}
