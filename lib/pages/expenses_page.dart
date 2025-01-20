import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../widgets/date_picker.dart';
import '../widgets/text_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/member_select.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({Key? key}) : super(key: key);

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  final List<String> _members = [
    'Ajith',
    'Pushpe',
    'Laka',
    'Buddhika',
    'Kumi',
    'Wimarsha',
    'Sadeep',
    'KT',
  ];
  final List<String> _selectedMembers = [];
  final String _type = 'expense';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _addExpense() async {
    if (_formKey.currentState?.validate() ?? false) {
      final expenseData = {
        'date': _dateController.text,
        'amount': _amountController.text,
        'remark': _remarkController.text,
        'type': _type,
        'members': _selectedMembers,
      };

      const String webAppUrl = kWebAppUrl;

      try {
        final response = await http.post(
          Uri.parse(webAppUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
            expenseData,
          ), // jsonEncode works after importing dart:convert
        );

        if (response.statusCode == 200) {
          print("Expense data sent successfully: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Expense added successfully!")),
          );
        } else {
          print("Failed to send expense data: ${response.statusCode}");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to add expense.")));
        }
      } catch (e) {
        print("Error occurred: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("An error occurred.")));
      }
      _clearFields();
    }
  }

  void _clearFields() {
    _amountController.clear();
    _remarkController.clear();
    setState(() {
      _selectedMembers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Expenses Page",
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

                MemberSelectWidget(
                  members: _members,
                  selectedMembers: _selectedMembers,
                ),
                TextInputWidget(controller: _remarkController, label: "Remark"),
                const SizedBox(height: 20),
                CustomButton(text: 'Add Expense', onPressed: _addExpense),
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
