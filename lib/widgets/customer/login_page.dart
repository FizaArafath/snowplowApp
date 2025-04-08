import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/widgets/customer/bottomNavigationBar.dart';
import 'package:snowplow/widgets/customer/registration_page.dart';
import 'package:http/http.dart' as http;


class loginPage extends StatefulWidget {
  const loginPage({super.key});

  @override
  State<loginPage> createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  // void _login() async{
  //   if(_formkey.currentState!.validate()){
  //     setState(() {
  //       _isLoading = true;
  //     });
  //
  //     String email = _emailController.text.trim();
  //     String password = _passwordController.text.trim();
  //
  //   try {
  //     String url = "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/users";
  //
  //     final response = await http.get(Uri.parse(url));
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //
  //       bool isUserFound = false;
  //       String? userId;
  //
  //       for (var doc in data["documents"]) {
  //         if (doc["fields"] != null &&
  //             doc["fields"]["email"] != null &&
  //             doc["fields"]["password"] != null) {
  //           String storedEmail = doc["fields"]["email"]["stringValue"] ?? "";
  //           String storedPassword = doc["fields"]["password"]["stringValue"] ??
  //               "";
  //
  //           if (storedEmail == email && storedPassword == password) {
  //             isUserFound = true;
  //             userId = doc["name"]
  //                 .split('/')
  //                 .last; // Extract Firestore document ID
  //             break;
  //           }
  //         }
  //       }
  //
  //       if (isUserFound && userId != null) {
  //         SharedPreferences prefs = await SharedPreferences.getInstance();
  //         await prefs.setString("userId", userId);
  //
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("Login successful!"),
  //               backgroundColor: Colors.teal[200]),
  //         );
  //
  //         Navigator.pushReplacementNamed(context, "/bottomNavigationBar");
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("Invalid credentials. Please try again.")),
  //         );
  //       }
  //     }
  //   }catch (e){
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error: $e")),
  //     );
  //   }
  //   setState(() {
  //     _isLoading = false;
  //   });
  //   }
  // }



  void _login() async {
    if (_formkey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        final url = Uri.parse("https://snowplow.celiums.com/api/customers/login");

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'api-key': "c778f7fd-7056-4f61-8e0f-d83e57b09fb5",
            'auth-secret': "7161092a3ab46fb924d464e65c84e355"


          },
          body: jsonEncode({
            "email": email,
            "password": password,
            "api_mode": "test", // change to "live" if needed
          }),
        );

        final responseData = jsonDecode(response.body);

        print(responseData);
        print(response.statusCode);

        if (response.statusCode == 200 && responseData['status'] == 1) {
          final userId = responseData['data']['customer_id'].toString();

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString("userId", userId);

          if(mounted) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //       content: Text("Login successful!"),
            //       backgroundColor: Colors.teal[200]),
            // );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const BottomNavigationBarWidget()),
                  (route) => false,
            );
          }

          // ✅ Force navigate and clear back stack
          if (mounted) {

          }


        }
        else {


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? "Login failed")),
          );
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
          child:Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          color: Colors.white,
          margin: EdgeInsets.all(20.0),
          child: Padding(
              padding: EdgeInsets.all(20.0),
            child: Form(
              key: _formkey,
                child:Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Login Here",style: GoogleFonts.poppins(fontSize: 24,fontWeight: FontWeight.bold,color: Colors.teal[200])),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return "please enter your email";
                        }
                       if(!value.contains("@") || !value.contains(".")){
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
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: (){
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                            },
                        ),
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return "Enter your password";
                        }
                        if (value.length < 8){
                          return "Password must be at least 8 characters";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    _isLoading
                    ?CircularProgressIndicator()
                    :ElevatedButton(onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[200],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: EdgeInsets.symmetric(horizontal: 60,vertical: 10)
                        ),
                        child:Text("Login",style: GoogleFonts.poppins(fontSize: 18,fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 15),
                    TextButton(onPressed:(){
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => userRegForm()),
                      );
                    },
                        child: Text(
                      "Don't have an account? Sign Up here",
                      style: TextStyle(color: Colors.teal[100]),
                    ))
                  ],
                ),
            ),
          ),
        ),
        ),
      )
    );

  }
}
