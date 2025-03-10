import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'MainScreen.dart';
import '../widgets/text_input.dart';
import '../widgets/custom_button.dart';
import 'package:jwt_decode/jwt_decode.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ✅ Check if .env variable is loaded correctly
    final String? apiUrl = dotenv.env['API_BASE_URL'];
    if (apiUrl == null || apiUrl.isEmpty) {
      setState(() {
        _errorMessage =
            "API URL is not configured. Please check your .env file.";
        _isLoading = false;
      });
      print("❌ Error: API_BASE_URL is missing in .env");
      return;
    }

    final loginData = {
      'name': _nameController.text,
      'password': _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse("$apiUrl/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      // Log the response body for debugging
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract the token from the response
        String? token = data['token'];

        if (token == null || token.isEmpty) {
          throw Exception('Missing token in response');
        }

        // ✅ Decode the JWT token to get the userId and role
        Map<String, dynamic> decodedToken = Jwt.parseJwt(token);

        // Extract userId and role from the decoded token
        String? userId = decodedToken['id'];
        String? role = decodedToken['role'];

        // Check if userId or role is missing or empty
        if (userId == null || userId.isEmpty || role == null || role.isEmpty) {
          throw Exception('Decoded userId or role is empty');
        }

        // ✅ Store token, userId, and role in SharedPreferences
        await _storeToken_UserIdAndRole(token, userId, role);

        // ✅ Log success message
        print(
          "✅ User '${_nameController.text}' signed in successfully at ${DateTime.now()}",
        );

        // ✅ Navigate to Expenses Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        setState(() {
          _errorMessage = "Invalid credentials. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
      print("❌ Login error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _storeToken_UserIdAndRole(
    String token,
    String userId,
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // Store the token, userId, and role in SharedPreferences
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    await prefs.setString('role', role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adjust form size
              children: [
                // ✅ Title "Boarding Expenses"
                const Text(
                  "Boarding Expenses",
                  style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24), // Spacing below title

                TextInputWidget(controller: _nameController, label: "Name"),
                TextInputWidget(
                  controller: _passwordController,
                  label: "Password",
                  isPassword: true,
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14.0),
                    ),
                  ),

                // ✅ Disable Button when loading
                CustomButton(
                  text: _isLoading ? "Signing in..." : "Sign In",
                  disabled: _isLoading ? true : false,
                  onPressed:
                      _isLoading ? () {} : _signIn, // ✅ Disabled when loading
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
