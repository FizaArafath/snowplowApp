import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PlaceBidScreen extends StatefulWidget {
  final String requestId;
  final String customerId;
  final List<dynamic> bidRequestList;
  final VoidCallback onBidPlaced;

  const PlaceBidScreen({
    super.key,
    required this.requestId,
    required this.customerId,
    required this.bidRequestList,
    required customerAddress,
    required approximateArea,
    required preferredDate,
    required preferredTime,
    required String photoUrl,
    //required Future<void> Function() onBidPlaced,
    required this.onBidPlaced,
  });

  @override
  State<PlaceBidScreen> createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends State<PlaceBidScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  // User details
  String userName = "N/A";
  String userEmail = "N/A";
  String userPhone = "N/A";

  // Request details
  String customerAddress = "N/A";
  String approximateArea = "N/A";
  String photoUrl = "";
  String preferredTime = "N/A";
  String preferredDate = "N/A";

  final TextEditingController bidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _extractCustomerDetails();
    _fetchUserDetails();
    // Removed _updateRequestStatus from here
  }

  void _extractCustomerDetails() {
    final customerData = widget.bidRequestList.firstWhere(
          (item) => item['customer_id'].toString() == widget.customerId,
      orElse: () => <String, dynamic>{},
    );

    if (customerData != null) {
      customerAddress = customerData['service_street'] ?? "N/A";
      approximateArea = customerData['service_area'] ?? "N/A";
      photoUrl = "https://snowplow.celiums.com/uploads/${customerData['image']}";
      preferredTime = customerData['preferred_time'] ?? "N/A";
      preferredDate = customerData['preferred_date'] ?? "N/A";
    }
  }

  Future<void> _fetchUserDetails() async {
    final apiUrl = "https://snowplow.celiums.com/api/users/profile";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"customer_id": widget.customerId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['data'] != null) {
          final user = data['data'];
          setState(() {
            userName = user['name'] ?? "N/A";
            userEmail = user['email'] ?? "N/A";
            userPhone = user['phone'] ?? "N/A";
          });
        }
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRequestStatus() async {
    final statusUpdateUrl = "https://snowplow.celiums.com/api/bids/bidupdate";

    try {
      final response = await http.post(
        Uri.parse(statusUpdateUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "request_id": widget.requestId,
          "status": "bid placed",
          "api_mode": "test"
        }),
      );

      if (response.statusCode == 200) {
        print("Status updated successfully");
      } else {
        print("Failed to update status: ${response.body}");
      }
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  Future<void> _submitBid() async {
    if (_formKey.currentState!.validate()) {
      // Validate bid amount is a positive number
      if (double.tryParse(bidAmountController.text) == null || double.parse(bidAmountController.text) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid bid amount")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Get the agency ID from shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? agencyId = prefs.getString('companyId');

        if (agencyId == null) {
          throw Exception('Missing agency ID');
        }

        // API URL for submitting the bid
        final apiUrl = "https://snowplow.celiums.com/api/bids/createbid";

        // Prepare request body
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "bid_request_id": widget.requestId,
            "agency_id": agencyId,
            "price": bidAmountController.text,
            "comments": notesController.text,
            "api_mode": "test",
          }),
        );

        final resData = jsonDecode(response.body);

        // Check if the response is successful
        if (response.statusCode == 200 && resData['status'] == 1) {
          // ✅ BID SUBMITTED SUCCESSFULLY, NOW UPDATE STATUS TO "Pending"
          await _updateRequestStatus();

          // Notify user of success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Bid submitted successfully!"),
              backgroundColor: Colors.teal[100],
            ),
          );

          // Optionally trigger the callback function in the parent screen
          widget.onBidPlaced();

          // Update the screen status if needed
          setState(() {
            widget.onBidPlaced();
            // You can also update some UI elements here if necessary
          });

          // Pop the screen to go back to the previous screen
          Navigator.pop(context, true); // Make sure parent screen handles refresh
        } else {
          throw Exception(resData['message'] ?? "Failed to submit bid");
        }
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting bid: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        // Reset loading state
        setState(() {
          _isLoading = false;
        });
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text("Place Your Bid",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
                _buildSectionTitle("User Details"),
                _buildReadOnlyField("Name", userName),
                _buildReadOnlyField("Email", userEmail),
                _buildReadOnlyField("Phone", userPhone),
                const SizedBox(height: 16),

                _buildSectionTitle("Request Details"),
                _buildReadOnlyField("Address", customerAddress),
                _buildReadOnlyField("Approximate Area", approximateArea),
                _buildReadOnlyField("Preferred Time", preferredTime),
                _buildReadOnlyField("Preferred Date", preferredDate),

                const SizedBox(height: 10),
                const Text("Uploaded Photo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Center(child: Image.network(photoUrl, height: 100, width: 100, fit: BoxFit.cover)),
                const SizedBox(height: 15),

                _buildTextField(bidAmountController, "Bid Amount", isNumber: true),
                _buildTextField(notesController, "Additional Notes", maxLines: 3),

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitBid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[200],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                    ),
                    child: Text("Submit Bid",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        style: GoogleFonts.poppins(),
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
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

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[800]),
      ),
    );
  }
}
