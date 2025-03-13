import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class CompanyProfileScreen extends StatefulWidget {
  final String companyId;
  const CompanyProfileScreen({super.key, required this.companyId});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  TextEditingController companyNameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController websiteController = TextEditingController();
  String companyEmail = "company@example.com";
  File? _logo;
  String? companyId; // Store company ID from SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  // Load company ID from SharedPreferences
  Future<void> _loadCompanyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      companyId = prefs.getString("companyId");
    });

    if (companyId != null) {
      fetchCompanyProfile(); // Fetch profile if companyId exists
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No company ID found. Please log in again.")),
      );
    }
  }

  // Fetch company profile from Firestore
  Future<void> fetchCompanyProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? companyId = prefs.getString("companyId"); // Fetch stored companyId

    if (companyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No company ID found. Please log in again.")),
        );
      }
      return;
    }

    String url =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/companies/$companyId";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (mounted) { // ✅ Check if widget is still in the tree
          setState(() {
            companyNameController.text = data['fields']['companyName']['stringValue'] ?? "";
            companyEmail = data['fields']['email']['stringValue']  ?? "";
            contactController.text = data['fields']['contact']['stringValue'] ?? "";
            addressController.text = data['fields']['address']['stringValue'] ?? "";
          });
        }
      } else {
        throw Exception("Failed to load company profile");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> updateCompanyProfile() async {
    if (companyId == null) return;

    String url = "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/companies/$companyId";

    try {
      // Fetch existing profile data first
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception("Failed to fetch profile data before update");
      }

      var data = jsonDecode(response.body);
      String existingPassword = data['fields']['password']['stringValue'] ?? "";

      // Prepare updated data (retaining password)
      Map<String, dynamic> updatedData = {
        "fields": {
          "companyId": {"stringValue": companyId},
          "companyName": {"stringValue": companyNameController.text},
          "contact": {"stringValue": contactController.text},
          "address": {"stringValue": addressController.text},
          "email": {"stringValue": companyEmail},
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




  // Delete company profile from Firestore
  Future<void> deleteCompanyProfile() async {
    if (companyId == null) return;

    String url =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/companies/$companyId";

    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove("companyId"); // Remove stored company ID
        Navigator.pushReplacementNamed(context, "/companyLogin");
      } else {
        throw Exception("Failed to delete company profile");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Show confirmation dialog before deleting the profile
  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.teal[100],
          title: Text("Delete Company Profile",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete this company profile? This action cannot be undone.",
              style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text("Cancel",style: TextStyle(color: Colors.white),),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                deleteCompanyProfile(); // Delete profile
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Pick an image from the gallery
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logo = File(pickedFile.path);
      });
    }
  }

  // Build input fields
  Widget buildTextField(String label, TextEditingController controller, {bool isEditable = true}) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: isEditable ? Icon(Icons.edit, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      enabled: isEditable,
    );
  }

  // Logout function
  void logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("companyId"); // Remove stored company ID
    Navigator.pushReplacementNamed(context, "/companyLogin");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text("Company Profile",style: GoogleFonts.poppins(color: Colors.white,fontWeight: FontWeight.bold)
      ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _logo != null ? FileImage(_logo!) : AssetImage('assets/company_placeholder.png') as ImageProvider,
                ),
              ),
              SizedBox(height: 20),
              buildTextField("Company Name", companyNameController),
              SizedBox(height: 20),
              buildTextField("Address", addressController),
              SizedBox(height: 20),
              buildTextField("Contact", contactController),
              SizedBox(height: 20),
              buildTextField("Email", TextEditingController(text: companyEmail), isEditable: false),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[100],
                    foregroundColor: Colors.red[300],
                    minimumSize: Size(double.infinity, 50)),
                onPressed: showDeleteConfirmationDialog, // Show alert before deleting
                child: Text("Delete Profile", style: GoogleFonts.poppins(color: Colors.red[300],fontSize: 24,fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[100],
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50)),
                onPressed: updateCompanyProfile,
                child: Text("Update Info", style: GoogleFonts.poppins(color: Colors.white,fontSize: 24,fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: logoutUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[100],
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text("Logout", style: GoogleFonts.poppins(color: Colors.white,fontSize: 24,fontWeight: FontWeight.bold),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
