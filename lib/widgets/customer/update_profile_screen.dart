import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  File? _image;
  String? base64Image = "";
  String? imageExtension = "";

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    nameController.text = prefs.getString('name') ?? "";
    contactController.text = prefs.getString('phone') ?? "";
    addressController.text = prefs.getString('address') ?? "";
    emailController.text = prefs.getString('email') ?? "";
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64 = base64Encode(imageBytes);
      String ext = pickedFile.path.split('.').last;

      setState(() {
        _image = imageFile;
        base64Image = base64;
        imageExtension = ext;
      });
    }
  }

  Future<void> updateProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiKey');
    String? customerId = prefs.getString('userId');

    if (token == null || customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please login again")),
      );
      return;
    }

    Map<String, dynamic> body = {
      'customer_id': customerId,
      'name': nameController.text,
      'email': emailController.text,
      'phone': contactController.text,
      'address': addressController.text,
      'profile_image': base64Image ?? "",
      'profile_image_ext': imageExtension ?? "",
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile updated successfully")),
          );
          Navigator.pop(context, true); // Pop back to ProfileScreen
        } else {
          throw Exception(data['message'] ?? "Update failed");
        }
      } else {
        throw Exception("Failed: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text("Update Profile",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : AssetImage('assets/personlogo.jpeg') as ImageProvider,
                backgroundColor: Colors.grey[300],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder()),
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: contactController,
              decoration: InputDecoration(labelText: "Contact", border: OutlineInputBorder()),
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: "Address", border: OutlineInputBorder()),
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[100],
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Save Changes", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
