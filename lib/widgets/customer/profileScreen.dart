import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class profileScreen extends StatefulWidget {
  final String userId;
  const profileScreen({super.key,required this.userId});

  @override
  State<profileScreen> createState() => _profileScreenState();
}

class _profileScreenState extends State<profileScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  String email = "";
  File? _image;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // Use the userId passed from widget
    fetchProfileData(); // Directly call fetchProfileData
  }

  Future<void> fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiKey');
    String? customerId = prefs.getString('userId'); // Assuming this is the customer_id

    if (token == null || customerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please login again")),
        );
      }
      return;
    }

    String url = "https://snowplow.celiums.com/api/profile/details";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
          'api_mode': 'test',
        },
        body: jsonEncode({
          'customer_id': customerId,
          'api_mode': 'test',
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print('Parsed data: $data');

        if (data['status'] == 'success' && data['data'] != null) {
          var userData = data['data'];
          if (mounted) {
            setState(() {
              nameController.text = userData['customer_name'] ?? "";
              email = userData['customer_email'] ?? "";
              contactController.text = userData['customer_phone'] ?? "";
              addressController.text = userData['customer_address'] ?? "";
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? "Failed to fetch profile data")),
            );
          }
        }
      } else {
        throw Exception("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
      print('Error details: $e');
    }
  }




  Future<void> updateCompanyProfile() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: No user ID found. Please log in again.")),
      );
      return;
    }

    String url = "https://snowplow.celiums.com/api/profile/update";

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("apiKey"); // ✅ Match the token key used during login
      String? customerId = prefs.getString("userId");

      if (token == null || customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please login again")),
        );
        return;
      }

      Map<String, dynamic> body = {
        'customer_id': customerId, // ✅ Required by backend
        'customer_name': nameController.text,
        'customer_email': email,
        'customer_phone': contactController.text,
        'customer_address': addressController.text,
        'api_mode': 'test',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ Add Bearer here too
          'api_mode': 'test',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Profile updated successfully")),
            );
          }
        } else {
          throw Exception(data['message'] ?? "Update failed");
        }
      } else {
        throw Exception("Failed to update profile: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    }
  }



  Future<void> deleteCompanyProfile() async {
    if (userId == null) return;

    String url =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/users/$userId";

    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove("userId"); // Remove stored company ID
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        throw Exception("Failed to delete company profile");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void logoutUser() {
    Navigator.pushReplacementNamed(context, "/login");
  }

  // Show confirmation dialog before deleting the profile
  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.teal[100],
          title: Text("Delete Company Profile",style: GoogleFonts.poppins(color: Colors.white,fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete this profile? This action cannot be undone.",
              style: GoogleFonts.poppins(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text("Cancel",style: GoogleFonts.poppins(color: Colors.white),),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                deleteCompanyProfile(); // Delete profile
              },
              child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickImage() async{
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(pickedFile != null){
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  //text fields
  Widget buildTextField(String label, TextEditingController controller, {bool isEditable = true}) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        suffixStyle: GoogleFonts.poppins(),
        suffixIcon: isEditable
            ? Icon(Icons.edit, color: Colors.grey)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      enabled: isEditable,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text("Profile",
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 30
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/profile_placeholder.png'),
                ),
              ),
              SizedBox(height: 20,),
              buildTextField("Name", nameController),
              SizedBox(height: 20),
              buildTextField("Address", addressController),
              SizedBox(height: 20),
              buildTextField("contact", contactController),
              SizedBox(height: 20),
              buildTextField("Email", TextEditingController(text: email), isEditable: false),
              SizedBox(height: 30),
              ElevatedButton(
                style:ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[100],
                    foregroundColor: Colors.red[300],
                    minimumSize: Size(double.infinity, 50)
                ),
                onPressed: showDeleteConfirmationDialog,
                child: Text("Delete Profile",style: GoogleFonts.poppins(fontSize: 24,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                style:ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[100],
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50)
                ),
                onPressed: updateCompanyProfile,
                child: Text("Update Profile",style: GoogleFonts.poppins(fontSize: 24,fontWeight: FontWeight.bold),),
              ),

              SizedBox(height: 15),
              ElevatedButton(
                onPressed: logoutUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[100],
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text("Logout", style: GoogleFonts.poppins(fontSize: 24,fontWeight: FontWeight.bold)),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
