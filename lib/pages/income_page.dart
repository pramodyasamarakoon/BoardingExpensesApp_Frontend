import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/date_picker.dart';
import '../widgets/text_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/member_select.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class IncomePage extends StatefulWidget {
  final Function?
  refreshBalance; // Nullable callback function to refresh balance

  const IncomePage({Key? key, this.refreshBalance}) : super(key: key);

  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  List<Map<String, String>> _members = []; // Stores user IDs & names
  List<String> _selectedMemberIds = []; // Stores selected user IDs
  final String _type = 'income';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = true; // Show loading while fetching users
  bool _isLoadingTransaction = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when screen loads
  }

  /// Fetch users from backend
  Future<void> _fetchUsers() async {
    final String apiUrl = dotenv.env['API_BASE_URL']!; // Get API from .env

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/allUsers'), // API endpoint
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);

        setState(() {
          _members =
              users
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
          _isLoading = false;
        });
      } else {
        _handleError("Error fetching users", response);
      }
    } catch (e) {
      _handleError("Exception while fetching users", e);
    }
  }

  /// Add transaction to backend
  Future<void> _addTransaction() async {
    setState(() {
      _isLoadingTransaction = true;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoadingTransaction = false;
      });
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      setState(() {
        _isLoadingTransaction = false;
      });
      _showSnackbar("❌ Please select at least one member.");
      return;
    }

    final String apiUrl = dotenv.env['API_BASE_URL']!;
    final String endpoint = '$apiUrl/addTransaction';

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoadingTransaction = false;
        });
        _showSnackbar("❌ No auth token found. Please log in again.");
        return;
      }

      // ✅ Ensure the date is in `YYYY-MM-DD` format
      String formattedDate = DateFormat(
        "yyyy-MM-dd",
      ).format(DateTime.parse(_dateController.text));

      if (_selectedMemberIds.isEmpty) {
        setState(() {
          _isLoadingTransaction = false;
        });
        _showSnackbar("❌ Please select at least one member.");
        return;
      }

      final transactionData = {
        "type": _type,
        "date": formattedDate, // ✅ Correct format (YYYY-MM-DD)
        "amount":
            double.tryParse(_amountController.text) ??
            0.0, // Ensure `amount` is a number
        "selectedMembers":
            _selectedMemberIds, // Ensure it's an array of user IDs
        "remark":
            _remarkController.text.trim().isEmpty
                ? "No remark"
                : _remarkController.text.trim(), // Handle empty remark
      };

      print("📤 Sending Transaction Data: ${jsonEncode(transactionData)}");

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Ensure correct headers
          'x-auth-token': token,
        },
        body: jsonEncode(transactionData),
      );

      print("✅ API Response Code: ${response.statusCode}");
      print("✅ API Response Body: ${response.body}");

      if (response.statusCode == 201) {
        _showSnackbar("✅ Transaction added successfully!");
        if (widget.refreshBalance != null) {
          print("✅ Triggering refreshBalance to update the total balance.");
          widget
              .refreshBalance!(); // Call the callback to refresh balance if not null
        }
        _clearFields();
      } else {
        _showSnackbar("❌ Failed to add transaction: ${response.body}");
      }
      setState(() {
        _isLoadingTransaction = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTransaction = false;
      });
      print("❌ Exception occurred: $e");
      _showSnackbar("❌ An error occurred. Please try again.");
    }
  }

  /// Clears input fields after submission
  void _clearFields() {
    _amountController.clear();
    _remarkController.clear();
    setState(() {
      _selectedMemberIds.clear();
    });
  }

  /// Handles API errors and prints logs
  void _handleError(String message, dynamic error) {
    print("❌ $message: $error");
    _showSnackbar("❌ $message");
    setState(() {
      _isLoading = false;
    });
  }

  /// Shows snackbar message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Income Page",
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DatePickerWidget(controller: _dateController, label: 'Date'),
                TextInputWidget(
                  controller: _amountController,
                  label: "Amount",
                  keyboardType: TextInputType.number,
                ),
                TextInputWidget(controller: _remarkController, label: "Remark"),

                if (_isLoading)
                  const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),

                if (!_isLoading)
                  MemberSelectWidget(
                    members: _members.map((user) => user["name"]!).toList(),
                    selectedMembers: _selectedMemberIds,
                    onSelectionChanged: (selectedNames) {
                      setState(() {
                        _selectedMemberIds =
                            _members
                                .where(
                                  (user) =>
                                      selectedNames.contains(user["name"]),
                                )
                                .map((user) => user["id"]!)
                                .toList();
                      });
                    },
                  ),

                const SizedBox(height: 20),
                CustomButton(
                  text: 'Add Income',
                  onPressed: _isLoading ? null : _addTransaction,
                  isLoading: _isLoadingTransaction,
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Clear Fields',
                  onPressed: _clearFields,
                  backgroundColor: Colors.white,
                  textColor: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
