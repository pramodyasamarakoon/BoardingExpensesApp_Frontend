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
  double totalBalance = 0;
  bool isLoading = true;

  late List<Widget> _pages;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Check if the user is an admin
  Future<bool> _isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    return role == 'admin';
  }

  // Fetch the final balance from the backend
  Future<void> _refreshBalance() async {
    final String webAppUrl = dotenv.env['API_BASE_URL']!;
    final String token = await _getAuthToken();

    try {
      final response = await http.get(
        Uri.parse('$webAppUrl/total-balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalBalance = (data['totalBalance'] as num).toDouble();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("❌ Error fetching balance: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("❌ Error fetching balance: $e");
    }
  }

  // Function to get authentication token
  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  @override
  void initState() {
    super.initState();
    _refreshBalance(); // Fetch balance when the screen is loaded

    _pages = [
      ExpensesPage(refreshBalance: _refreshBalance),
      const IncomePage(),
      const DashboardPage(),
      const UsersPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boarding Expenses', style: TextStyle(fontSize: 14)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                isLoading
                    ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                    : GestureDetector(
                      onTap: _refreshBalance, // Reload the balance on tap
                      child: Text(
                        'Rs. $totalBalance',
                        style: const TextStyle(
                          fontSize: 26.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
          ),
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
      body: _pages[_selectedIndex], // Use _pages here
      bottomNavigationBar: FutureBuilder<bool>(
        future: _isAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 3),
            );
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
              if (snapshot.data == true)
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
    await prefs.remove('auth_token');
    await prefs.remove('role');

    // Redirect to SignInPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }
}
