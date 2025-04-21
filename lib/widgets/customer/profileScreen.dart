import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/widgets/customer/update_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  File? _image;
  String? userId;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiKey');
    String? customerId = prefs.getString('userId');

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

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if ((data['status'] == 1 || data['status'] == 'success') && data['data'] != null) {
          var userData = data['data'];
          if (mounted) {
            setState(() {
              nameController.text = userData['customer_name'] ?? "";
              emailController.text = userData['customer_email'] ?? "";
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
    }
  }

  Future<void> updateCompanyProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiKey');
    String? customerId = prefs.getString('userId');

    if (token == null || customerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please login again")),
        );
      }
      return;
    }

    Map<String, dynamic> body = {
      'customer_id': customerId,
      'name': nameController.text,
      'email': emailController.text,
      'phone': contactController.text,
      'profile_image': "",
      'profile_image_ext': "",
      'api_mode': 'test',
    };

    try {
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/profile/update"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'api_mode': 'test',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 1) {
          if (mounted) {
            setState(() {
              isEditing = false;
            });
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

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
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
        await prefs.remove("userId");
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

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.teal[100],
          title: Text("Delete Company Profile", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete this profile? This action cannot be undone.",
              style: GoogleFonts.poppins(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteCompanyProfile();
              },
              child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text("Profile", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30)),
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
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : AssetImage('assets/personlogo.jpeg') as ImageProvider,
                  backgroundColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder()),
                style: GoogleFonts.poppins(),
                readOnly: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: InputDecoration(labelText: "Contact", border: OutlineInputBorder()),
                style: GoogleFonts.poppins(),
                readOnly: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: "Address", border: OutlineInputBorder()),
                style: GoogleFonts.poppins(),
                readOnly: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                style: GoogleFonts.poppins(),
                readOnly: true,
              ),
              SizedBox(height: 30),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UpdateProfileScreen()),
                      );
                      if (updated == true) {
                        fetchProfileData(); // Refresh on return
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[100],
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Edit Profile", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),

                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: showDeleteConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[300],
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Delete Profile", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: logoutUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[100],
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text("Logout", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
