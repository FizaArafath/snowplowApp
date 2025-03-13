import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PlaceBidScreen extends StatefulWidget {
  final String requestId;
  const PlaceBidScreen({super.key, required this.requestId});

  @override
  State<PlaceBidScreen> createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends State<PlaceBidScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String customerAddress = "N/A";
  String approximateArea = "N/A";
  String photoUrl = "https://via.placeholder.com/150";
  String preferredTime = "N/A";
  String preferredDate = "N/A";

  final TextEditingController bidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  String _formatDateManually(String dateString) {
    if (dateString == "N/A") return dateString; // Handle missing date

    try {
      // Extract only 'yyyy-MM-dd' part (ignoring time if present)
      List<String> parts = dateString.split("T")[0].split("-");

      // Rearrange as 'dd/MM/yyyy'
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    } catch (e) {
      return "Invalid Date";
    }
  }


  Future<void> _fetchRequestDetails() async {
    String apiUrl =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/bid_requests/${widget.requestId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final fields = data['fields'] as Map<String,dynamic>;

        setState(() {
          customerAddress = fields['address']?['stringValue'] ?? "N/A";
          approximateArea = fields['area']?['stringValue'] ?? "N/A";
          photoUrl = fields['photoUrl']?['stringValue'] ?? "https://via.placeholder.com/150";
          preferredTime = fields['time']?['stringValue'] ?? "N/A";
          String rawDate = fields['date']?['stringValue'] ?? "N/A";
          preferredDate = _formatDateManually(rawDate);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load request details');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitBid() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      try {
        // Get current user ID (you'll need to implement this)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('userId');
        SharedPreferences pref = await SharedPreferences.getInstance();
        String? companyId = pref.getString('companyId');

        if (userId == null) {
          throw Exception('User not authenticated');
        }

        // Prepare the bid data
        Map<String, dynamic> bidData = {
          "bidAmount": bidAmountController.text,
          "notes": notesController.text,
          "requestId": widget.requestId,
          "userId": userId,
          "customerAddress": customerAddress,
          "approximateArea": approximateArea,
          "preferredTime": preferredTime,
          "preferredDate": preferredDate,
          "photoUrl": photoUrl,
          "status": "pending", // or "submitted" depending on your workflow
          "timestamp": DateTime.now().toIso8601String(),
        };

        // Post to Firebase
        String apiUrl =
            "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/placedBids";

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "fields": {
              "bidAmount": {"stringValue": bidAmountController.text},
              "notes": {"stringValue": notesController.text},
              "requestId": {"stringValue": widget.requestId},
              "userId": {"stringValue": userId},
              "companyId": {"stringValue": companyId},
              "customerAddress": {"stringValue": customerAddress},
              "approximateArea": {"stringValue": approximateArea},
              "preferredTime": {"stringValue": preferredTime},
              "preferredDate": {"stringValue": preferredDate},
              "photoUrl": {"stringValue": photoUrl},
              "status": {"stringValue": "pending"},
              "createdAt": {"timestampValue": DateTime.now().toUtc().toIso8601String()},
            }
          }),
        );

        String updateApiUrl = "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/bid_requests/${widget.requestId}";

        final updateResponse = await http.patch(
          Uri.parse(updateApiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "fields": {
              "status": {"stringValue": "bid placed"},
              "bidAmount": {"stringValue": bidAmountController.text},
              "notes": {"stringValue": notesController.text},
              "requestId": {"stringValue": widget.requestId},
              "userId": {"stringValue": userId},
              "companyId": {"stringValue": companyId},
              "customerAddress": {"stringValue": customerAddress},
              "approximateArea": {"stringValue": approximateArea},
              "preferredTime": {"stringValue": preferredTime},
              "preferredDate": {"stringValue": preferredDate},
              "photoUrl": {"stringValue": photoUrl},
              "createdAt": {"timestampValue": DateTime.now().toUtc().toIso8601String()},


            }
          }),
        );

        if (updateResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Bid submitted successfully!"),
              backgroundColor: Colors.teal[100],
            ),
          );
          Navigator.pop(context); // Close the screen after successful submission
        } else {
          throw Exception('Failed to submit bid: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting bid: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //reject order
  Future<void> _rejectOrder() async {
    String apiUrl =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/bid_requests/${widget.requestId}";

    try {
      final response = await http.delete(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bid request rejected and deleted successfully!"),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context); // Close the screen after rejection
      } else {
        throw Exception('Failed to delete request');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: Unable to delete request"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text("Place Your Bid",style: GoogleFonts.poppins(color: Colors.white,fontSize: 22,fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReadOnlyField("Address", customerAddress),
                _buildReadOnlyField("Approximate Area", approximateArea),
                _buildReadOnlyField("Preferred Time", preferredTime),
                _buildReadOnlyField("Preferred Date", preferredDate),
                const SizedBox(height: 10),
                const Text("Uploaded Photos",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Center(
                  child: Image.network(photoUrl, height: 100, width: 100, fit: BoxFit.cover),
                ),
                const SizedBox(height: 15),
                _buildTextField(bidAmountController, "Bid Amount", isNumber: true),
                _buildTextField(notesController, "Additional Notes", maxLines: 3),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton("Bid", Colors.teal[200]!, _submitBid),
                    _buildButton("Reject", Colors.redAccent, _rejectOrder),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        style: GoogleFonts.poppins(),
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $labelText";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
      ),
      child: Text(text,style: GoogleFonts.poppins(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold)),
    );
  }
}
