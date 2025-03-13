import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:snowplow/widgets/serviceProviders/loginScreen.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyRegForm extends StatefulWidget {
  const CompanyRegForm({super.key});

  @override
  State<CompanyRegForm> createState() => _CompanyRegFormState();
}

class _CompanyRegFormState extends State<CompanyRegForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  void _registerCompany() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String companyName = _companyNameController.text.trim();
      String email = _emailController.text.trim();
      String contact = _contactController.text.trim();
      String password = _passwordController.text.trim();


      try {
        String companyId = Uuid().v4();
        String url = "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/companies";

        Map<String, dynamic> companyData = {
          "fields": {
            "companyId": {"stringValue": companyId},
            "companyName": {"stringValue": companyName},
            "email": {"stringValue": email},
            "contact": {"stringValue": contact},
            "password": {"stringValue": password},
            "createdAt": {"timestampValue": DateTime.now().toUtc().toIso8601String()},
          }
        };

        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(companyData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Store companyId locally for profile retrieval
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("companyId", companyId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Company Registration Successful"),
                backgroundColor: Colors.teal[200]),
          );
          Navigator.pushReplacementNamed(context, "/companyLogin");
          _formKey.currentState!.reset();
        } else {
          throw Exception("Failed to register: ${response.body}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
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
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.teal[100],
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          color: Colors.white,
          margin: EdgeInsets.all(20.0),
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Company Registration",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[200]),
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: InputDecoration(labelText: "Company Name", border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? "Enter company name" : null,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                      validator: (value) =>
                      value == null || value.isEmpty ? "Enter email" : (!value.contains("@") || !value.contains(".")) ? "Enter a valid email" : null,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: "Phone", border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? "Enter phone number" : null,
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
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Enter password" : value.length < 8 ? "Password must be at least 8 characters" : null,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder()),
                      validator: (value) => value != _passwordController.text ? "Passwords do not match" : null,
                    ),
                    SizedBox(height: 15),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _registerCompany,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[200],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: Text("Register", style: TextStyle(fontSize: 16)),
                    ),
                    SizedBox(height: 15),
                    TextButton(
                      onPressed: (){
                        Navigator.push(context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text("Already Registered ? Login",
                        style: TextStyle(color: Colors.teal[100]),
                      ),
                    )
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
