import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/widgets/serviceProviders/registrationScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  void _loginCompany() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        String url =
            "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/companies";
        final response = await http.get(Uri.parse(url));

        print("API Response: ${response.body}"); // Debugging

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (!data.containsKey("documents") || data["documents"] == null) {
            throw Exception("No companies found in Firestore.");
          }

          bool isCompanyFound = false;
          String? companyId;

          for (var doc in data["documents"]) {
            if (!doc.containsKey("fields") || doc["fields"] == null) {
              print("Skipping document, missing fields: $doc");
              continue;
            }

            String storedEmail = doc["fields"]["email"]?["stringValue"]?.toLowerCase() ?? "";
            String storedPassword = doc["fields"]["password"]?["stringValue"] ?? "";

            print("Checking company: $storedEmail - $storedPassword");

            if (storedEmail == email.toLowerCase() && storedPassword == password) {
              isCompanyFound = true;
              companyId = doc["name"].split('/').last; // Extract Firestore document ID
              break;
            }
          }

          if (isCompanyFound && companyId != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("companyId", companyId);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Login successful!"), backgroundColor: Colors.teal[200]),
            );

            Navigator.pushReplacementNamed(context, "/companyBottomNavigation");
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Invalid email or password."), backgroundColor: Colors.red),
            );
          }
        } else {
          throw Exception("Failed to fetch company data: ${response.body}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white), // Back Arrow
          onPressed: () {
            Navigator.pushReplacementNamed(context, "/welcomeScreen");
          },
        ),
      ),
      backgroundColor: Colors.teal[100],
      body: SingleChildScrollView(
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            color: Colors.white,
            margin: EdgeInsets.all(20.0),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Login Here",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[200],
                        ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter your email";
                        if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}").hasMatch(value)) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isObscure = !_isObscure),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Enter your password";
                        if (value.length < 8) return "Password must be at least 8 characters";
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _loginCompany,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[200],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.symmetric(horizontal: 60, vertical: 10),
                      ),
                      child: Text("Login", style: TextStyle(fontSize: 16)),
                    ),
                    SizedBox(height: 15),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CompanyRegForm())),
                      child: Text("Don't have an account? Sign Up here", style: TextStyle(color: Colors.teal[200])),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}