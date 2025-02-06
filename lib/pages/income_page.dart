import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/date_picker.dart';
import '../widgets/text_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/member_select.dart';
import '../utils/constants.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({Key? key}) : super(key: key);

  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  // Member list and selection
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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _addIncome() async {
    if (_formKey.currentState?.validate() ?? false) {
      final incomeData = {
        'date': _dateController.text,
        'amount': _amountController.text,
        'remark': _remarkController.text,
        'members': _selectedMembers,
      };

      const String webAppUrl = kWebAppUrl;

      try {
        final response = await http.post(
          Uri.parse("$webAppUrl?function=addIncome"), // Specify the function
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(incomeData),
        );

        if (response.statusCode == 200) {
          print("Income data sent successfully: ${response.body}");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Income added successfully!")));
        } else {
          print("Failed to send income data: ${response.statusCode}");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to add income.")));
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
    // _dateController.clear();
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
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: const Text(
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
        // Add SafeArea to avoid overlapping with the status bar
        child: SingleChildScrollView(
          // Wrap content with SingleChildScrollView to allow scrolling
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DatePickerWidget(controller: _dateController, label: 'Date'),
                  // Amount Input Field
                  TextInputWidget(
                    controller: _amountController,
                    label: "Amount",
                    keyboardType: TextInputType.number,
                  ),
                  // Remark Input Field
                  TextInputWidget(
                    controller: _remarkController,
                    label: "Remark",
                  ),
                  // Select member widget
                  MemberSelectWidget(
                    members: _members,
                    selectedMembers: _selectedMembers,
                  ),

                  // Add income button
                  CustomButton(text: 'Add income', onPressed: _addIncome),
                  const SizedBox(height: 10),
                  // Clear Fields button
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
      ),
    );
  }
}
