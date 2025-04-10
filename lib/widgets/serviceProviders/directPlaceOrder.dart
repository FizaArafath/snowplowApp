import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';

class directPlaceOrder extends StatefulWidget {
  final String requestId;
  const directPlaceOrder({super.key, required this.requestId, required String customerId, required customerAddress, required approximateArea, required String photoUrl, required preferredTime, required preferredDate});

  @override
  State<directPlaceOrder> createState() => _directPlaceOrderState();
}

class _directPlaceOrderState extends State<directPlaceOrder> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String customerAddress = "N/A";
  String approximateArea = "N/A";
  String photoUrl = "https://via.placeholder.com/150";
  String preferredTime = "N/A";
  String preferredDate = "N/A";
  final TextEditingController notesController = TextEditingController();
  bool _isAccepted = false;

  double requesterLat = 0.0; // Default value
  double requesterLng = 0.0; // Default value



  Future<String> getImageUrl(String filePath) async {
    try {
      String downloadUrl =
          await FirebaseStorage.instance.ref(filePath).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error fetching image URL: $e");
      return "https://via.placeholder.com/150"; // Default image
    }
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
        final fields = data['fields'] as Map<String, dynamic>;

        setState(() {
          customerAddress = fields['address']?['stringValue'] ?? "N/A";
          approximateArea = fields['area']?['stringValue'] ?? "N/A";

          preferredTime = fields['time']?['stringValue'] ?? "N/A";

          // Extract date string and reformat it manually
          String rawDate = fields['date']?['stringValue'] ?? "N/A";
          preferredDate = _formatDateManually(rawDate);

          // Fetch image URL properly
          String? storedPhotoUrl = fields['photoUrl']?['stringValue'];
          if (storedPhotoUrl != null && storedPhotoUrl.isNotEmpty) {
            // If stored as a path in Firebase Storage, convert to a public URL
            if (!storedPhotoUrl.startsWith("http")) {
              getImageUrl(storedPhotoUrl).then((url) {
                setState(() {
                  photoUrl = url;
                });
              });
            } else {
              photoUrl = storedPhotoUrl;
            }
          } else {
            photoUrl = "https://via.placeholder.com/150"; // Default image
          }

          // Check if the order is already accepted
          _isAccepted = fields['status']?['stringValue'] == "Accepted";

          // Extract latitude and longitude (Ensure Firestore stores them as double values)
          requesterLat = fields['latitude']?['doubleValue'] ?? 0.0;
          requesterLng = fields['longitude']?['doubleValue'] ?? 0.0;

          print("Requester Lat: $requesterLat, Requester Lng: $requesterLng");

          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load request details');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching request details: $e");
    }
  }

  Future<void> _openGoogleMaps() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Location permissions are required to open Google Maps.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Please enable location permissions in app settings.")),
      );
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        double userLat = position.latitude;
        double userLng = position.longitude;

        String googleMapsUrl =
            "https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng&destination=$requesterLat,$requesterLng&travelmode=driving";

        Uri uri = Uri.parse(googleMapsUrl);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          print("Could not launch URL");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Google Maps app not found! Please install it.")),
          );
        }
      } catch (e) {
        print("Error opening Google Maps: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open Google Maps: $e")),
        );
      }
    }
  }

  Future<void> _acceptOrder() async {
    String apiUrl =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/bid_requests/${widget.requestId}?updateMask.fieldPaths=status";

    Map<String, dynamic> updatedData = {
      "fields": {
        "status": {"stringValue": "Accepted"}
      }
    };

    try {
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Update status immediately
          _isAccepted = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order accepted successfully!"),
            backgroundColor: Colors.teal[100],
          ),
        );
      } else {
        throw Exception("Failed to accept order");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: Unable to accept order"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrder() async {
    String apiUrl =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/bid_requests/${widget.requestId}";

    try {
      final response = await http.delete(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(" request rejected and deleted successfully!"),
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
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchRequestDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal[100],
          title: Text(
            "Direct Place Order",
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.all(16.0),
                child: Form(
                    child: SingleChildScrollView(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadOnlyField("Place", customerAddress),
                      _buildReadOnlyField("Approximate Area", approximateArea),
                      _buildReadOnlyField("Preferred date", preferredDate),
                      _buildReadOnlyField("Preferred time", preferredTime),
                      const SizedBox(height: 10),
                      const Text("Uploaded Photos",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Image.network(photoUrl,
                          fit: BoxFit.cover, width: 150, height: 150,
                          errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                            "https://via.placeholder.com/150"); // Fallback
                      }),
                      const SizedBox(height: 15),
                      _buildTextField(notesController, "Additional Notes",
                          maxLines: 3),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment
                            .stretch, // Ensures buttons take full width
                        children: [
                          if (!_isAccepted) // Show Accept button if order is not accepted
                            _buildButton(
                                "Accept", Colors.teal[100]!, _acceptOrder),
                          if (!_isAccepted) // Add space between buttons if "Accept" is visible
                            SizedBox(height: 20),
                          if (_isAccepted) // Show Get Start button after accepting
                            _buildButton("Get Start", Colors.teal[100]!,
                                _openGoogleMaps),
                          if (_isAccepted) // Add space between buttons if "Get Start" is visible
                            SizedBox(height: 20),
                          _buildButton(
                              "Reject", Colors.redAccent, _rejectOrder),
                        ],
                      ),
                    ],
                  ),
                )),
              ));
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        style: GoogleFonts.poppins(),
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.teal[50],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        style: GoogleFonts.poppins(),
        controller: controller,
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
