import 'package:flutter/material.dart';
import 'expenses_page.dart';
import 'income_page.dart';
import 'dashboard_page.dart';
import 'transaction_page.dart';
import 'users_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'signin_page.dart';
import 'transaction_admin_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  double totalBalance = 0;
  bool isLoading = true;
  bool isAdmin = false; // New variable to track the role

  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _bottomNavItems;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Check if the user is an admin
  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    setState(() {
      isAdmin = role == 'admin';
      _setPagesAndNavItems(); // Update pages and nav items based on the role
    });
    print("✅ Role checked successfully.");
  }

  // Set the pages and bottom navigation items based on role
  void _setPagesAndNavItems() {
    if (isAdmin) {
      _pages = [
        ExpensesPage(refreshBalance: _refreshBalance),
        const IncomePage(),
        AdminTransactionPage(),
        const DashboardPage(),
        const UsersPage(),
      ];
      _bottomNavItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.payment_rounded),
          label: 'Expenses',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Income',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.transfer_within_a_station_rounded),
          label: 'Transactions',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.supervised_user_circle_rounded),
          label: 'Users',
        ),
      ];
    } else {
      _pages = [
        const TransactionPage(), // User sees only the transactions page
        const DashboardPage(), // User also sees the dashboard page
      ];
      // Ensure there are at least two items in the BottomNavigationBar
      _bottomNavItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.transfer_within_a_station_rounded),
          label: 'Transactions',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard', // Add dashboard for non-admins
        ),
        // const BottomNavigationBarItem(
        //   icon: Icon(Icons.home),
        //   label: 'Home', // Add a placeholder "Home" item
        // ),
      ];
    }
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
        print("✅ Refresh balance successfully.");
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
    return prefs.getString('token') ?? '';
  }

  // Fetch all users from the API and update SharedPreferences
  Future<void> _fetchAndUpdateUsers() async {
    final String webAppUrl = dotenv.env['API_BASE_URL']!;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final response = await http.get(
        Uri.parse('${webAppUrl}/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(
          response.body,
        ); // Decode the response

        // Update SharedPreferences with the fetched users
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('users', jsonEncode(users));

        print("✅ Users fetched and stored successfully.");
      } else {
        print("❌ Error fetching users: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching users: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAndUpdateUsers();
    _checkRole(); // Check the role when the screen is loaded
    _refreshBalance(); // Fetch balance when the screen is loaded
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
      body:
          _pages.isEmpty
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show a loading spinner while pages are being set
              : _pages[_selectedIndex], // Use _pages here
      bottomNavigationBar:
          _bottomNavItems.isEmpty
              ? const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
              : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: _bottomNavItems,
                backgroundColor: Colors.white,
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
              ),
    );
  }

  // Log out function
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');

    // Redirect to SignInPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }
}
