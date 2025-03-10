import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For .env files to store API URLs
import 'package:shared_preferences/shared_preferences.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({Key? key}) : super(key: key);

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  bool _isLoading = true;
  List<dynamic> transactions = [];
  String _errorMessage = ''; // To show error messages if any
  double totalBalance = 0.0; // To store user balances by ID
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  // Fetch users from the backend
  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('userId');

    if (storedUserId != null) {
      try {
        // Decode the JSON data
        // final decodeUserId = jsonDecode(storedUserId);

        setState(() {
          userId = storedUserId;
        });

        // After getting user id, fetch transactions
        _fetchTransactions();
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = '❌ Error decoding user id: $e';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = '❌ User ID not found in local storage.';
      });
    }
  }

  // Fetch dashboard data for each user and update their balance
  Future<void> _fetchTransactions() async {
    final String apiUrl = dotenv.env['API_BASE_URL']!; // Get API URL from .env
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/$userId/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          transactions = data['transactions'];
          totalBalance = (data['totalBalance'] as num).toDouble();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print("❌ Error fetching transactions: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Error fetching transactions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final type = transaction['type'];
                          final date = DateTime.parse(transaction['date']);
                          final amount =
                              (transaction['amount'] as num).toDouble();
                          final share =
                              (transaction['share'] as num).toDouble();
                          final remark = transaction['remark'];

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color:
                                  type == 'income'
                                      ? Colors.green[100]
                                      : Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${date.toLocal()}'.split(
                                      ' ',
                                    )[0], // Show date (YYYY-MM-DD)
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${share.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color:
                                          type == 'income'
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                remark,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
