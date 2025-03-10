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
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    for (var user in _users) {
      try {
        final response = await http.get(
          Uri.parse('$apiUrl/${user['id']}/dashboard'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          double balance;

          // Handling different types of `totalBalance` values from the backend
          if (data['totalBalance'] is int) {
            balance =
                (data['totalBalance'] as int)
                    .toDouble(); // Convert int to double
          } else if (data['totalBalance'] is double) {
            balance = data['totalBalance']; // Already a double
          } else if (data['totalBalance'] is Map<String, dynamic> &&
              data['totalBalance'].containsKey("\$numberDecimal")) {
            balance = double.parse(
              data['totalBalance']['\$numberDecimal'],
            ); // Extract Decimal128 value
          } else {
            print(
              "❌ Unexpected totalBalance format for user ${user['name']}: ${data['totalBalance']}",
            );
            continue; // Skip this user if the data format is wrong
          }

          // Update UI state with the user's balance
          setState(() {
            _userBalances[user['id']!] = balance;
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
                      color: Colors.white, // Keeping card color as white
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user['name']!,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (balance != null)
                              Text(
                                'Rs. ${balance.toStringAsFixed(2)}', // Format balance to 2 decimal points
                                style: TextStyle(
                                  color:
                                      balance < 0
                                          ? Colors.redAccent
                                          : Colors.green,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
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
