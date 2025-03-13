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
  String email = "user@example.com";
  File? _image;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  // Load userID from SharedPreferences
  Future<void> _loadCompanyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString("userId");
    });

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No user ID found. Please log in again.")),
      );
    } else {
      // Store it again to ensure it remains
      await prefs.setString("userId", userId!);
      fetchProfileData();
    }
  }


  Future<void> fetchProfileData() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId"); // Fetch stored userId

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user ID found. Please log in again.")),
        );
      }
      return;
    }

    String url = "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/users/$userId";

    try{
      final response = await http.get(Uri.parse(url));
      if(response.statusCode == 200){
        var data = jsonDecode(response.body);

        if(mounted) {
          setState(() {
            nameController.text = data['fields']['name']['stringValue'];
            email = data['fields']['email']['stringValue'] ?? "No email found";
            // addressController.text = data['fields']['address']['stringValue'] ?? "";
          });
        }
      }else{
        throw Exception("failed to load profile");
      }
    }catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> updateCompanyProfile() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: No user ID found. Please log in again.")),
      );
      return;
    }

    String url = "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/users/$userId";

    try {
      // Fetch existing profile data to retain any missing fields
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch profile data before update");
      }

      var data = jsonDecode(response.body);
      String existingPassword = data['fields']['password']['stringValue'] ?? "";
      String existingUserId = data['name'].split('/').last;  // Ensure we keep userId

      // Prepare updated data
      Map<String, dynamic> updatedData = {
        "fields": {
          "userId": {"stringValue": userId},
          "name": {"stringValue": nameController.text},
          "contact": {"stringValue": contactController.text},
          "address": {"stringValue": addressController.text},
          "email": {"stringValue": email},
          "password": {"stringValue": existingPassword} // Retain existing password
        }
      };

      // Send PATCH request to update profile
      final updateResponse = await http.patch(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updatedData),
      );

      if (updateResponse.statusCode == 200) {
        // Store userId again to make sure it's not lost
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("userId", existingUserId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.teal[200]),
        );
      } else {
        throw Exception("Failed to update profile");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
