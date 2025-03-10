import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminTransactionPage extends StatefulWidget {
  @override
  _AdminTransactionPageState createState() => _AdminTransactionPageState();
}

class _AdminTransactionPageState extends State<AdminTransactionPage> {
  final String apiUrl =
      dotenv.env['API_BASE_URL']!; // Ensure API_BASE_URL is set in .env
  List<dynamic> transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  // Fetch transactions from the API
  Future<void> fetchTransactions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(
      'token',
    ); // Assuming token is stored in shared preferences

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$apiUrl/transactions/recent'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> fetchedTransactions = json.decode(response.body);
          setState(() {
            transactions = fetchedTransactions;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Failed to load transactions. Status: ${response.statusCode}';
            _isLoading = false;
          });
        }
      } catch (error) {
        setState(() {
          _errorMessage = 'Error occurred: $error';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'No token found';
        _isLoading = false;
      });
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token != null) {
      try {
        final response = await http.delete(
          Uri.parse('$apiUrl/transactions/$transactionId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          // Successfully deleted, refresh the transaction list
          fetchTransactions();
        } else {
          setState(() {
            _errorMessage =
                'Failed to delete transaction. Status: ${response.statusCode}';
          });
        }
      } catch (error) {
        setState(() {
          _errorMessage = 'Error occurred while deleting transaction: $error';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'No token found';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transactions')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : transactions.isEmpty
              ? Center(child: Text('No transactions available'))
              : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final type = transaction['type'] ?? 'Unknown';
                  final date =
                      DateTime.tryParse(transaction['date'] ?? '') ??
                      DateTime.now();
                  final share =
                      (transaction['share'] as num?)?.toDouble() ?? 0.0;
                  final amount =
                      (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                  final remark = transaction['remark'] ?? 'No remark';

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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${date.toLocal()}'.split(
                              ' ',
                            )[0], // Show date (YYYY-MM-DD)
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rs. ${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color:
                                  type == 'income' ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(remark, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Delete Transaction'),
                                content: Text(
                                  'Are you sure you want to delete this transaction?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      deleteTransaction(
                                        transaction['_id'] ?? '',
                                      );
                                      Navigator.pop(context);
                                    },
                                    child: Text('Yes'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('No'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
