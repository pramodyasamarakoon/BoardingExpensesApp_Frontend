import 'package:flutter/material.dart';
import 'pages/expenses_page.dart';
import 'pages/income_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/settings_page.dart';
import 'utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Boarding Expenses',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ExpensesPage(),
    const IncomePage(),
    const DashboardPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Boarding Expenses',
                style: TextStyle(fontSize: 12.0, color: kMainColor),
              ),
              Text(
                'Rs. 112,345', // Dynamically loaded total balance
                style: const TextStyle(
                  fontSize: 32.0,
                  color: kSuccessColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(height: 0.5, color: kMainColor),
          Expanded(
            child:
                _pages[_selectedIndex], // Page content changes based on selected index
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 8.0,
        ), // 8px horizontal padding
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black, // Active item color (icon and text)
          unselectedItemColor:
              kMainColor, // Inactive item color (icon and text)
          showSelectedLabels: true, // Display labels
          showUnselectedLabels: true, // Display labels for unselected items
          type: BottomNavigationBarType.fixed, // Removes animation
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.payment_rounded), // Material icon for Expenses
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.account_balance_wallet_rounded,
              ), // Material icon for Income
              label: 'Income',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.dashboard_rounded,
              ), // Material icon for Dashboard
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded), // Material icon for Settings
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
