import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../services/agency_services.dart';
import 'order_list.dart';

class BidRequestForm extends StatefulWidget {
  const BidRequestForm({super.key});

  @override
  State<BidRequestForm> createState() => _BidRequestFormState();
}

class _BidRequestFormState extends State<BidRequestForm> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedService; // This will be used for both service selection and API
  String? _selectedOptions = "Bid";
  String? _selectedAgency;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<File> _selectedImages = [];
  final picker = ImagePicker();
  String? _selectedAddress;
  List<String> _previousAddresses = [];
  String _currentAddress = "Fetching location...";
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;
  bool _isLoadingAgencies = false;
  bool _isLoadingServices = false;
  bool _isLoading = false;
  String? selectedUrgency; // 'fast' or 'slow' or null

  List<String> _services = [];

  List<Agency> _agencies = [];

  List<Map<String, dynamic>> agencies = [];

  //service-type list
  Future<void> _fetchServices() async {
    setState(() {
      _isLoadingServices = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/services/list"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "per_page": "10",
          "page": "0",
          "api_mode": "test",
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 1 && responseData['data'] != null) {
          final List<dynamic> serviceList = responseData['data'];

          setState(() {
            _services = serviceList.map((service) => service['service_type'].toString()).toList();
          });

          print("Loaded services: $_services");
        } else {
          print("Invalid response format or no data.");
        }
      } else {
        print("Failed to load services. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching services: $e");
    } finally {
      setState(() {
        _isLoadingServices = false;
      });
    }
  }



  Future<void> _fetchAgencies()async{
    setState(() {
      _isLoading = true;
    });

    try{
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/agencies/list"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',

        },
        body: jsonEncode(
            {
              "per_page": "10",
              "page": "0",
              "api_mode": "test",
            }
        ),
      );
      if(response.statusCode == 200){
        final Map<String,dynamic> responseData = jsonDecode(response.body);

        if(responseData['status'] == 1 &&  responseData['data']!= null){
          final List<dynamic> agencyList = responseData['data'];
          print(responseData);
          print(response.body);
          setState(() {
            _agencies = agencyList.map((agency) => Agency(
              id: agency['agency_id'].toString(),
              name: agency['agency_name'].toString(),
              rating: double.tryParse(agency['rating'].toString()) ?? 0.0,
              email: agency['agency_email'].toString(),
              uid: agency['uid'].toString(),
            )).toList();
          });
          print("Loaded agencies: ${_agencies.length}");
        }
        else{
          print("Invalid response format or no data.");

        }
      }

      else{
        print("Failed to load agencies. Status: ${response.statusCode}");
      }
    }catch(e){
      print("Error fetching agencies: $e");
    }
    finally{
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    if (!mounted) return; // Prevent setState if widget is disposed

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();

      if (!mounted) return; // Check again before setting state

      setState(() {
        _latitude = position.latitude; // Store latitude
        _longitude = position.longitude; // Store longitude
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

  Future<void> _fetchAddress() async {
    String apiUrl =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/addresses";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('documents')) {
          List<String> addresses = (data['documents'] as List)
              .map((doc) {
                if (doc['fields'] != null && doc['fields']['address'] != null) {
                  return doc['fields']['address']['stringValue'].toString();
                }
                return "";
              })
              .where((address) => address.isNotEmpty) // Remove empty values
              .toList();

          setState(() {
            _previousAddresses = addresses;
          });

          print("Fetched Addresses: $_previousAddresses");
        } else {
          print("No addresses found.");
        }
      } else {
        print(
            "Failed to fetch addresses: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching addresses: $e");
    }
  }

  // Function to pick images
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    setState(() {
      _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
    });
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      String firebaseStorageUrl =
          "https://firebasestorage.googleapis.com/v0/b/snow-plow-d24c0.appspot.com/o";

      var uri = Uri.parse(
          "$firebaseStorageUrl/${Uri.encodeComponent(imageFile.path.split('/').last)}?uploadType=media");

      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        String downloadUrl =
            "https://firebasestorage.googleapis.com/v0/b/snow-plow-d24c0.appspot.com/o/${jsonResponse['name']}?alt=media";

        print("Image uploaded: $downloadUrl");
        return downloadUrl;
      } else {
        throw Exception("Image upload failed: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Image upload failed");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
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
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }




  void _submitForm() async {
    print("Submit button pressed");

    if (_formkey.currentState!.validate()) {
      print("Form validation passed");
      
      // Check for service
      if (_selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a service type")),
        );
        return;
      }

      // Check for valid date and time selection
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select both date and time")),
        );
        return;
      }

      // Format date and time properly
      final formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";
      final formattedDate = DateFormat("yyyy-MM-dd").format(_selectedDate!);

      // Get userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      print("User ID: $userId");

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not authenticated")),
        );
        return;
      }

      // Check if latitude and longitude are provided
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please provide a valid location")),
        );
        return;
      }

      // Convert selected images to Base64
      List<String> base64Images = [];
      for (var image in _selectedImages) {
        List<int> imageBytes = await image.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        base64Images.add(base64Image);
      }



      try {
        if (_selectedOptions == "Bid") {
          // BID REQUEST
          final response = await http.post(
            Uri.parse("https://snowplow.celiums.com/api/bids/bidrequest"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "agency_id": _selectedAgency ?? "",
              "comments": _areaController.text,
              "service_type": _selectedService,
              "service_area": _areaController.text,
              "service_city": _currentAddress,
              "service_latitude": _latitude?.toString() ?? "",
              "service_longitude": _longitude?.toString() ?? "",
              "urgency_level": selectedUrgency,
              "image": base64Images.join(","),
              "preferred_time": formattedTime,
              "service_street": _areaController.text,
              "preferred_date": formattedDate,
              "customer_id": userId,
              "api_mode": "test",
            }),
          );
          print("Response Body (Raw): ${response.body}");

          if (response.statusCode == 200 || response.statusCode == 201) {
            try {
              var jsonResponse = jsonDecode(response.body);
              print("Response Body (JSON): $jsonResponse");

              String message = jsonResponse['message'] ?? "Bid request sent successfully!";
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            } catch (e) {

              // Catch error while decoding JSON
              print("Error parsing JSON: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Bid request sent successfully!")),
              );
            }
            Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderList()));
          } else {
            print("Bid API Error Status Code: ${response.statusCode}");
            print("Bid API Error Body: ${response.body}");

            try {
              var errorResponse = jsonDecode(response.body);
              String errorMessage = errorResponse['message'] ?? "Bid request failed with status ${response.statusCode}";
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage)),
              );
            } catch (e) {
              print("Error parsing error response: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Bid request failed: ${response.statusCode} - ${response.body}")),
              );
            }
            throw Exception("Bid API returned ${response.statusCode}");
          }
        } else {
          // DIRECT REQUEST
          final response = await http.post(
            Uri.parse("https://snowplow.celiums.com/api/requests/companyrequest"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "7161092a3ab46fb924d464e65c84e355", // If required
            },
            body: jsonEncode({
              "customer_id": userId,
              "agency_id": _selectedAgency ?? "",
              "service_type": _selectedService,
              "service_area": _areaController.text,
              "address": _currentAddress,
              "preferred_time": formattedTime,
              "preferred_date": formattedDate,
              "image": base64Images.join(","),
              "image_ext": "jpg",
              "urgency_level": selectedUrgency,
              "service_latitude": _latitude!.toString(),
              "service_longitude": _longitude!.toString(),
              "api_mode": "test",
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            print("Response Status Code: ${response.statusCode}");
            print("Response Headers: ${response.headers}");

            // Check for content type and response body
            var contentType = response.headers['content-type'];
            print("Content-Type: $contentType");

            // Try to parse the response body as JSON
            try {
              var jsonResponse = jsonDecode(response.body);
              print("Response Body (JSON): $jsonResponse");

              // Show success message with any available message from the response
              String message = jsonResponse['message'] ?? "Request sent successfully!";
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            } catch (e) {
              // If not JSON, print raw body
              print("Response Body (Raw): ${response.body}");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Request sent successfully!")),
              );
            }
          } else {
            print("API Error Status Code: ${response.statusCode}");
            print("API Error Body: ${response.body}");

            // Try to parse error response
            try {
              var errorResponse = jsonDecode(response.body);
              String errorMessage = errorResponse['message'] ?? "Request failed with status ${response.statusCode}";
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage)),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Request failed: ${response.statusCode} - ${response.body}")),
              );
            }
            throw Exception("API returned ${response.statusCode}");
          }
        }
      } catch (e) {
        print("Submission error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Something went wrong. Please try again.")),
        );
      }
    }
  }






  Future<void> _geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _latitude = locations.first.latitude;
          _longitude = locations.first.longitude;
        });
      }
    } catch (e) {
      print("Geocoding error: $e");
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
    _locationController.text = _currentAddress;
    _fetchAddress();
    _fetchAgencies();
    _fetchServices();
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
                            fontWeight: FontWeight.bold),
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
                        validator: (value) => value == null || value.isEmpty
                            ? "Fetch or enter a location"
                            : null,
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
                              if (value != "other") {
                                _locationController.text = value!;
                                _geocodeAddress(value); // Geocode the selected address
                              } else {
                                _locationController.clear();
                              }
                            });
                          },
                          isDense: true,
                          isExpanded: true,
                        ),
                      ),

                      SizedBox(height: 20),

                      TextFormField(
                        style: GoogleFonts.poppins(),
                        controller: _areaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: "Approximate Area (sq ft)",
                            border: OutlineInputBorder()),
                        validator: (value) =>
                            value!.isEmpty ? "Enter area" : null,
                      ),
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedService,
                        decoration: InputDecoration(
                          labelText: "Choose a service",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        hint: Text("Choose a service"),
                        items: _services.map((service) {
                          return DropdownMenuItem(
                            value: service,
                            child: Text(service),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedService = value;
                          });
                        },
                        validator: (value) => value == null ? "Please select a service" : null,
                      ),

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
                        children: _selectedImages
                            .map((image) => Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Image.file(image,
                                      width: 70, height: 70, fit: BoxFit.cover),
                                ))
                            .toList(),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_a_photo),
                        onPressed: _pickImages,
                      ),
                      SizedBox(height: 15,),
                      Column(
                        children: [
                          Text("Urgency Level"),

                          CheckboxListTile(
                            title: Text('Fast'),
                            value: selectedUrgency == 'fast',
                            onChanged: (value) {
                              setState(() {
                                selectedUrgency = value! ? 'fast' : null;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: Text('Slow'),
                            value: selectedUrgency == 'slow',
                            onChanged: (value) {
                              setState(() {
                                selectedUrgency = value! ? 'slow' : null;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Radio(
                            value: "Bid",
                            groupValue: _selectedOptions,
                            onChanged: (value) => setState(
                                () => _selectedOptions = value as String),
                          ),
                          Text(
                            "Bid",
                            style: GoogleFonts.poppins(),
                          ),
                          Radio(
                            value: "Direct",
                            groupValue: _selectedOptions,
                            onChanged: (value) => setState(
                                () => _selectedOptions = value as String),
                          ),
                          Text(
                            "Direct",
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                      if (_selectedOptions == "Direct") ...[
                        _isLoadingAgencies
                            ? CircularProgressIndicator()
                            : _agencies.isEmpty
                                ? Text("No agencies available")
                                : DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: "Select agency",
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedAgency,
                                    items: _agencies.map<DropdownMenuItem<String>>((Agency agency){
                                      return DropdownMenuItem(
                                        value: agency.id,
                                          child: Text("${agency.name} ⭐ ${agency.rating.toStringAsFixed(1)}"),
                                      );
                                    }).toList(),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedAgency = value;
                                      });
                                    },
                                  validator: (value)=> value == null ? "Select an agency" : null,
                                ),
                        if (_selectedAgency != null) ...[
                          SizedBox(height: 10),
                          Text(
                          "Selected agency: ${_agencies.firstWhere((agency) => agency.id == _selectedAgency).name}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          )
                          // Text(
                          //     "Rating: ${agencies.firstWhere((agency) => agency["name"] == _selectedAgency)["rating"]} ⭐"
                          // ),
                        ],
                      ],
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:(){
                          print("Submit clicked");
                         _submitForm();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[100],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 60, vertical: 10)),
                        child: Text(
                          "Submit Request",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      )
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
