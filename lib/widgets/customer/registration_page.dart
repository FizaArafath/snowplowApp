import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/widgets/customer/login_page.dart';
import 'package:uuid/uuid.dart';


class userRegForm extends StatefulWidget {
  const userRegForm({super.key});

  @override
  State<userRegForm> createState() => _userRegFormState();
}

class _userRegFormState extends State<userRegForm> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;


  void _register() async {
    if (_formkey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String name = _nameController.text.trim();
      String email = _emailController.text.trim();
      String contact = _contactController.text.trim();
      String password = _passwordController.text.trim();

      try {
        String userId = Uuid().v4();

        String url = "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/users";


        Map<String, dynamic> userData = {
          "fields": {
            "userId": {"stringValue": userId},
            "name": {"stringValue": name},
            "email": {"stringValue": email},
            "contact": {"stringValue": contact},
            "password": {"stringValue": password},
            "createdAt": {"timestampValue": DateTime.now().toUtc().toIso8601String()},
          }
        };


        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(userData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("userId", userId);


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration Successful"),
                backgroundColor: Colors.teal[200]),
          );
          Navigator.pushReplacementNamed(context, "/login");


          _formkey.currentState!.reset();
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
      backgroundColor: Colors.teal[100],
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          color: Colors.white,
          margin: EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.all(20.0),
              child: Form(
                key: _formkey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Register here:",
                        style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold,color: Colors.teal[200]),
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: "Name",border: OutlineInputBorder()),
                        validator: (value){
                          if (value == null || value.isEmpty){
                            return "Enter your name";
                          }return null;
                        },
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: "Email",border: OutlineInputBorder()),
                        validator: (value){
                          if(value == null || value.isEmpty){
                            return "Enter your email";
                          }if(!value.contains("@") || !value.contains(".")){
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: "Phone",border: OutlineInputBorder()),
                        validator: (value){
                          if(value ==  null || value.isEmpty){
                            return "Enter your phone number";
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
                            icon:Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: (){
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                        ),
                        validator: (value){
                          if(value == null || value.isEmpty){
                            return "Please enter your password";
                          }
                          if (value.length < 8) {
                            return "Password must be at least 8 characters";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "confirm password",
                          border: OutlineInputBorder()
                        ),
                        validator: (value){
                          if (value != _passwordController.text){
                            return " password not match";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      _isLoading
                      ?CircularProgressIndicator()
                      :ElevatedButton(onPressed:_register,
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[200],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.symmetric(horizontal: 50,vertical: 15),
                      ),
                        child: Text("Register",style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 15),
                      TextButton(
                          onPressed: (){
                            Navigator.push(context,
                            MaterialPageRoute(builder: (context) => loginPage()),
                            );
                          },
                          child: Text("Already Registered ? Login",
                        style: TextStyle(color: Colors.teal[100]),
                          ),
                      )
                    ],
                  )
              ),
            ),
          ),
        ),
      ),
    );
  }
}
