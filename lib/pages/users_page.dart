import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/text_input.dart';
import '../widgets/custom_button.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _isLoading = true;
  List<Map<String, String>> _members = [];

  // Controllers for Name and Password inputs
  TextEditingController _nameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  // Controller for Role
  String _role = 'user'; // Default role

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when the page loads
  }

  // Fetch users from SharedPreferences
  Future<void> _fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString(
      'users',
    ); // Get users data from SharedPreferences

    if (userData != null) {
      // Decode the JSON data
      final List<dynamic> users = jsonDecode(userData);

      setState(() {
        // Map the decoded user data to the required format
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
        _isLoading = false; // Set loading to false once users are fetched
      });
    } else {
      // Handle the case where user data is not found in SharedPreferences
      setState(() {
        _isLoading = false;
      });
      print("❌ User data not found in local storage.");
    }
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

  // Delete user by calling API
  Future<void> _deleteUser(String userId) async {
    final String apiUrl = dotenv.env['API_BASE_URL']!;
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // On successful deletion, remove the user from the list
        _fetchAndUpdateUsers();
        setState(() {
          _members.removeWhere((user) => user['id'] == userId);
        });
        print("✅ User deleted successfully");
      } else {
        print("❌ Error deleting user: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error deleting user: $e");
    }
  }

  // Show confirmation dialog for deletion
  Future<void> _showDeleteConfirmation(String userId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(); // Close the dialog without doing anything
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteUser(userId); // Call delete function if confirmed
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Show user creation dialog with role selection
  Future<void> _showCreateUserDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextInputWidget(controller: _nameController, label: 'Name'),
              TextInputWidget(
                controller: _passwordController,
                label: 'Password',
                isPassword: true,
              ),
              // Dropdown for Role selection
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  items:
                      <String>['admin', 'user'].map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _role = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: 'Create',
              onPressed: () async {
                // Get values from controllers
                String name = _nameController.text.trim();
                String password = _passwordController.text.trim();

                // Perform API request or save the user data here
                await _createUser(name, password, _role);

                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Function to create a new user
  Future<void> _createUser(String name, String password, String role) async {
    final String apiUrl = dotenv.env['API_BASE_URL']!;
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'password': password, 'role': role}),
      );

      if (response.statusCode == 201) {
        await _fetchAndUpdateUsers();
        print("✅ User created successfully");
        // Optionally, refresh users or update the list
        _fetchUsers();
      } else {
        print("❌ Error creating user: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error creating user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateUserDialog, // Show the create user dialog
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator while fetching users
              : ListView.builder(
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          member['name']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(member['id']!),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
