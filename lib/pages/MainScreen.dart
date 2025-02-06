import 'package:flutter/material.dart';
import 'expenses_page.dart';
import 'income_page.dart';
import 'dashboard_page.dart';
import 'users_page.dart'; // Admin page
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'signin_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  double totalBalance = 0; // Store the balance
  bool isLoading = true; // To show loading spinner while fetching balance

  final List<Widget> _pages = [
    const ExpensesPage(),
    const IncomePage(),
    const DashboardPage(),
    const UsersPage(), // Only visible to Admin
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Check if the user is an admin
  Future<bool> _isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString(
      'role',
    ); // Assume 'role' is stored as 'admin' or 'user'
    return role == 'admin';
  }

  // Fetch the final balance from the backend
  Future<void> _fetchBalance() async {
    final String webAppUrl =
        dotenv.env['API_BASE_URL']!; // Load API base URL from .env
    final String token =
        await _getAuthToken(); // Get the auth token to pass in header

    print("✅ API URL: $webAppUrl");
    print("✅ Auth Token: $token");

    try {
      final response = await http.get(
        Uri.parse('$webAppUrl/total-balance'), // API endpoint to fetch balance
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Pass the token in the header
        },
      );

      print("✅ Response body: ${response.body}"); // Debugging

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalBalance = (data['totalBalance'] as num).toDouble();
          isLoading = false; // Hide loading spinner
        });
      } else {
        // Handle any errors from the API
        setState(() {
          isLoading = false;
        });
        print("❌ Error fetching balance: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("❌ Error occurred while fetching balance: $e");
    }
  }

  // Function to get authentication token
  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ??
        ''; // Get token from SharedPreferences
  }

  @override
  void initState() {
    super.initState();
    _fetchBalance(); // Fetch balance when the screen is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Boarding Expenses',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          // Show total balance on the right
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                isLoading
                    ? const CircularProgressIndicator() // Show loading spinner while fetching balance
                    : Text(
                      'Rs. $totalBalance',
                      style: const TextStyle(
                        fontSize: 26.0, // Increased font size of the balance
                        fontWeight:
                            FontWeight.bold, // Make the balance text bold
                        color: Colors.green, // Make the balance text green
                      ),
                    ),
          ),
          // Popup menu for settings (with log out)
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 1) {
                _logout(); // If log out is selected
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<int>(value: 1, child: Text('Log Out')),
                ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: FutureBuilder<bool>(
        future: _isAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.payment_rounded),
                label: 'Expenses',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Income',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              if (snapshot.data == true) // Show Users only for Admin
                const BottomNavigationBarItem(
                  icon: Icon(Icons.supervised_user_circle_rounded),
                  label: 'Users',
                ),
            ],
          );
        },
      ),
    );
  }

  // Log out function
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Remove token to log out
    await prefs.remove('role'); // Optionally remove role as well

    // Redirect to SignInPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }
}
