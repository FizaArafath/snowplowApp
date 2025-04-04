import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class directRequestForm extends StatefulWidget {
  final String selectedAgency;
  final double agencyRating;
  final String companyId;

  const directRequestForm(
      {super.key,
      required this.selectedAgency,
      required this.agencyRating,
      required this.companyId});

  @override
  State<directRequestForm> createState() => _directRequestFormState();
}

class _directRequestFormState extends State<directRequestForm> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _areaControlller = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(text: "");
  // final TextEditingController _locationController = TextEditingController();
  String? _selectedServiceType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<File> _images = [];
  final picker = ImagePicker();
  String? _selectedAddress;
  List<String> _previousAddresses = [];
  String _currentAddress = "Fetching location...";
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false; // Loading indicator for location fetching

  final List<String> serviceTypes = [
    "Residential Snow Removal",
    "Commercial Snow Removal",
    "Driveway Clearing",
    "Sidewalk Shoveling",
    "Full Property Cleanup",
  ];

  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permission denied")),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Location permission permanently denied. Enable it from settings.")),
      );
      return false;
    }

    return true;
  }

  Future<void> _fetchCurrentLocation() async {
    if (!mounted) return; // Prevent errors if widget is disposed

    setState(() {
      _isFetchingLocation = true;
    });

    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      setState(() {
        _isFetchingLocation = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentAddress =
            "${place.street ?? 'Unknown Street'}, ${place.locality ?? 'Unknown City'}, "
            "${place.administrativeArea ?? 'Unknown State'}, ${place.country ?? 'Unknown Country'}";
        _locationController.text = _currentAddress;
        _isFetchingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _currentAddress = "Error fetching location: $e";
        _locationController.text = _currentAddress;
        _isFetchingLocation = false;
      });
    }
  }

  // Future<void> _submitRequest() async {
  //   if (!_formkey.currentState!.validate()) {
  //     return;
  //   }
  //
  //   // Ensure location is fetched
  //   if ((_locationController.text.isEmpty ||
  //           _locationController.text == "Fetching location...") &&
  //       (_selectedAddress == null || _selectedAddress == "other")) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: Text("Please select an address or fetch your location")));
  //     return;
  //   }
  //
  //   // Retrieve stored user ID
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? userId = prefs.getString('userId');
  //
  //   if (userId == null) {
  //     print("User ID not found!");
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text("User not authenticated")));
  //     return;
  //   }
  //
  //   String apiUrl =
  //       "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/bid_requests";
  //
  //   try {
  //     var uuid = Uuid();
  //     String requestId = uuid.v4();
  //
  //     // Upload images and get URLs
  //     List<Map<String, dynamic>> imageUrls = await _uploadImages();
  //     String defaultType = "Direct";
  //
  //     // Prepare request data
  //     Map<String, dynamic> requestData = {
  //       "fields": {
  //         "requestId": {"stringValue": requestId},
  //         "userId": {"stringValue": userId},
  //         "latitude": {"doubleValue": _latitude!}, // ✅ Ensure non-null
  //         "longitude": {"doubleValue": _longitude!}, // ✅ Ensure non-null
  //         "area": {"stringValue": _areaControlller.text},
  //         "address": {"stringValue": _currentAddress},
  //         "serviceType": {"stringValue": _selectedServiceType!},
  //         "companyId": {"stringValue": widget.companyId},
  //         "date": {"stringValue": _selectedDate!.toIso8601String()},
  //         "time": {"stringValue": _selectedTime!.format(context)},
  //         "agency": {"stringValue": widget.selectedAgency},
  //         "agencyRating": {"doubleValue": widget.agencyRating},
  //         "requestType": {"stringValue": defaultType},
  //         "images": {
  //           "arrayValue": {"values": imageUrls}
  //         }
  //       }
  //     };
  //
  //     // Send POST request
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(requestData),
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       if (_selectedAddress == null ||
  //           !_previousAddresses.contains(_locationController.text)) {
  //         _saveAddress(_locationController.text);
  //       }
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //           backgroundColor: Colors.teal[100],
  //           content: Text("Request submitted successfully!",
  //               style: GoogleFonts.poppins())));
  //       Navigator.pop(context);
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //           content: Text("Failed to submit request: ${response.body}")));
  //     }
  //   } catch (e) {
  //     print("Error submitting request: $e");
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text("Error submitting request")));
  //   }
  // }


  Future<void> _submitRequest() async {
    if (!_formkey.currentState!.validate()) return;

    if ((_locationController.text.isEmpty || _locationController.text == "Fetching location...") &&
        (_selectedAddress == null || _selectedAddress == "other")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an address or fetch your location")),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      print("User ID not found!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not authenticated")),
      );
      return;
    }

    try {
      var uri = Uri.parse("https://snowplow.celiums.com/api/requests/companyrequest");
      var request = http.MultipartRequest("POST", uri);

      request.fields['user_id'] = userId;
      request.fields['company_id'] = widget.companyId;
      request.fields['request_type'] = "Direct";
      request.fields['latitude'] = _latitude?.toString() ?? "";
      request.fields['longitude'] = _longitude?.toString() ?? "";
      request.fields['area'] = _areaControlller.text;
      request.fields['address'] = _locationController.text;
      request.fields['service_type'] = _selectedServiceType!;
      request.fields['date'] = _selectedDate!.toIso8601String();
      request.fields['time'] = _selectedTime!.format(context);
      request.fields['agency'] = widget.selectedAgency;
      request.fields['agency_rating'] = widget.agencyRating.toString();

      // Attach images
      for (var image in _images) {
        request.files.add(await http.MultipartFile.fromPath('images[]', image.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_selectedAddress == null || !_previousAddresses.contains(_locationController.text)) {
          _saveAddress(_locationController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.teal[100],
          content: Text("Request submitted successfully!", style: GoogleFonts.poppins()),
        ));
        Navigator.pop(context);
      } else {
        print("Failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to submit request: ${response.body}"),
        ));
      }
    } catch (e) {
      print("Error submitting request: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error submitting request"),
      ));
    }
  }



// Upload images to Firebase Storage (Replace this with actual Firebase Storage logic)
  Future<List<Map<String, dynamic>>> _uploadImages() async {
    List<Map<String, dynamic>> imageUrls = [];

    for (var image in _images) {
      // Simulating an upload, replace this with Firebase Storage upload logic
      String uploadedUrl = "https://your-storage-url.com/${image.path}";
      imageUrls.add({"stringValue": uploadedUrl});
    }

    return imageUrls;
  }

  Future<void> _fetchAddress() async {
    String apiUrl =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/addresses";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('documents')) {
          List<String> addresses = (data['documents'] as List)
              .map((doc) => doc['fields']['address']['stringValue'].toString())
              .toList();

          setState(() {
            _previousAddresses = addresses;
          });
        }
      }
    } catch (e) {
      print("Error fetching addresses: $e");
    }
  }

  Future<void> _pickedImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveAddress(String address) async {
    String apiUrl =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/addresses";

    Map<String, dynamic> addressData = {
      "fields": {
        "address": {"stringValue": address}
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(addressData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Address saved successfully!");
        _fetchAddress(); // Refresh addresses after saving
      } else {
        print(
            "Failed to save address: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error saving address: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    // _locationController.text = _currentAddress;
    checkLocationPermission();
    _fetchAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, "/bottomNavigationBar");
          },
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.teal[100],
      body: Center(
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                      "Snow Removal Request",
                      style: GoogleFonts.poppins(
                        color: Colors.teal[100],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      style: GoogleFonts.poppins(),
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: "Current Location",
                        border: OutlineInputBorder(),
                        suffixIcon: _isFetchingLocation
                            ? Padding(
                                padding: EdgeInsets.all(8.0),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: Icon(Icons.my_location,
                                    color: Colors.teal[100]),
                                onPressed: () {
                                  _fetchCurrentLocation();
                                  setState(() {
                                    _selectedAddress =
                                        null; // Clear dropdown when fetching location
                                  });
                                },
                              ),
                      ),
                      readOnly: _selectedAddress != null &&
                          _selectedAddress != "other",
                    ),

                    SizedBox(height: 15),

                    SizedBox(
                      width: double
                          .infinity, // Ensures it fits within the parent container
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Select An Address",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedAddress,
                        items: _previousAddresses.map((address) {
                          return DropdownMenuItem(
                              value: address,
                              child: Text(address,
                                  overflow: TextOverflow.ellipsis));
                        }).toList()
                          ..add(
                            DropdownMenuItem(
                              value: "other",
                              child: Text("Enter a new address"),
                            ),
                          ),
                        onChanged: (value) {
                          setState(() {
                            _selectedAddress = value;
                            _locationController
                                .clear(); // Clear "Current Location"
                          });
                        },
                        isDense: true,
                        isExpanded: true,
                      ),
                    ),

                    SizedBox(height: 20),

                    TextFormField(
                      style: GoogleFonts.poppins(),
                      controller: _areaControlller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Approximate Area (sq ft)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter area" : null,
                    ),
                    SizedBox(height: 15),

                    // SizedBox(height: 15),
                    //   TextFormField(
                    //       style: GoogleFonts.poppins(),
                    //       controller: _addressController,
                    //       decoration: InputDecoration(labelText: "or enter new address",border: OutlineInputBorder()),
                    //       enabled: _selectedAddress ==null,
                    //       onChanged: (value){
                    //         if(value.isNotEmpty){
                    //           setState(() {
                    //             _selectedAddress=null;
                    //           });
                    //         }
                    //       },
                    //       validator: (value){
                    //         if((value == null || value.isEmpty) && _selectedAddress == null){
                    //           return "enter or select an address";
                    //         }
                    //         return null;
                    //       }
                    //   ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Preferred  Date : ${_selectedDate != null ? _selectedDate!.toLocal().toString().split(' ')[0] : "Selected date"}",
                          style: GoogleFonts.poppins(),
                        ),
                        IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context)),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Preferred Time : ${_selectedTime != null ? _selectedTime!.format(context) : "Select Time"}",
                          style: GoogleFonts.poppins(),
                        ),
                        IconButton(
                            onPressed: () => _selectTime(context),
                            icon: Icon(Icons.access_time)),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Upload Image",
                      style: GoogleFonts.poppins(),
                    ),
                    Wrap(
                      children: _images
                          .map((image) => Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Image.file(image,
                                    width: 70, height: 70, fit: BoxFit.cover),
                              ))
                          .toList(),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_a_photo),
                      onPressed: _pickedImage,
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Service Type",
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedServiceType,
                      items: serviceTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedServiceType = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? "Select a service type" : null,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Selected Agency",
                        border: OutlineInputBorder(),
                      ),
                      initialValue: widget.selectedAgency,
                      readOnly: true,
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Rating: ${widget.agencyRating} ⭐",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[100],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 60, vertical: 10),
                      ),
                      child: Text(
                        "Submit Request",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
