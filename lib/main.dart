import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/signin_page.dart';
import 'pages/MainScreen.dart';
import 'dart:convert'; // For encoding/decoding stored JSON data
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is ready before loading anything

  try {
    await dotenv.load(fileName: ".env"); // Load environment variables
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
  bool _isUserDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _fetchAndStoreUserData(); // Fetch and store user data every time the app starts
  }

  // Check authentication status
  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    setState(() {
      _isAuthenticated = token != null;
      _isLoading = false;
    });
  }

  // Fetch users from the API and store them in local storage
  Future<void> _fetchAndStoreUserData() async {
    final String apiUrl = dotenv.env['API_BASE_URL']!; // Get API URL from .env

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/allUsers'), // Fetch users API
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('users', jsonEncode(usersData)); // Store user data

        setState(() {
          _isUserDataLoaded = true; // Mark data as loaded
        });
      } else {
        print("❌ Error fetching users: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error occurred while fetching users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Boarding Expenses',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          _isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _isAuthenticated
              ? _isUserDataLoaded
                  ? const MainScreen() // Go to MainScreen if data is loaded
                  : const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ) // Show loading screen until user data is loaded
              : const SignInPage(), // Otherwise, go to SignInPage
    );
  }
}
