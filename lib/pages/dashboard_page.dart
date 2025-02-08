import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For .env files to store API URLs
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, String>> _users = []; // To hold the users' data (name & id)
  bool _isLoading = true; // Show loading spinner while fetching users
  String _errorMessage = ''; // To show error messages if any
  Map<String, double> _userBalances = {}; // To store user balances by ID

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when the page loads
  }

  // Fetch users from the backend
  Future<void> _fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString(
      'users',
    ); // Retrieve users' data from SharedPreferences

    if (userData != null) {
      try {
        // Decode the JSON data
        final List<dynamic> usersData = jsonDecode(userData);

        setState(() {
          _users =
              usersData
                  .where(
                    (user) => user is Map<String, dynamic>,
                  ) // Ensure it's a valid Map
                  .map<Map<String, String>>(
                    (user) => {
                      "id": user['_id'].toString(), // Convert ID to String
                      "name": user['name'].toString(), // Convert Name to String
                    },
                  )
                  .toList();
          _isLoading = false; // Hide the loading spinner once data is fetched
        });

        // After fetching users, retrieve their dashboard data if necessary
        _fetchDashboardData(); // Assuming you need to call this function
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Error decoding user data: $e'; // Error handling if JSON decoding fails
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User data not found in local storage.';
      });
    }
  }

  // Fetch dashboard data for each user and update their balance
  Future<void> _fetchDashboardData() async {
    final String apiUrl = dotenv.env['API_BASE_URL']!; // Get API URL from .env

    for (var user in _users) {
      try {
        final response = await http.get(
          Uri.parse(
            '$apiUrl/dashboard/${user['id']}',
          ), // API endpoint to fetch user dashboard data
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            // Update the balance for each user based on the API response
            _userBalances[user['id']!] = data['totalBalance'] as double;
          });
        } else {
          print(
            "❌ Error fetching dashboard data for user ${user['name']}: ${response.statusCode}",
          );
        }
      } catch (e) {
        print(
          "❌ Error occurred while fetching dashboard data for user ${user['name']}: $e",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final balance = _userBalances[user['id']];
                    return Card(
                      color: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              user['name']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (balance != null)
                              Text(
                                'Total Balance: Rs. $balance',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
