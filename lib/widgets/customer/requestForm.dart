import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../services/agency_services.dart';

class bidRequestForm extends StatefulWidget {
  const bidRequestForm({super.key});

  @override
  State<bidRequestForm> createState() => _bidRequestFormState();
}

class _bidRequestFormState extends State<bidRequestForm> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _areaControlller = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  // final TextEditingController _locationController = TextEditingController();
  String? _selectedServiceType;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<File> _selectedImages = [];
  final picker = ImagePicker();
  String? _selectedOptions = "Bid";
  String? _selectedAgency;
  String? _selectedAddress;
  List<String> _previousAddresses = [];
  String _currentAddress = "Fetching location...";
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;
  bool _isLoadingAgencies = false;
  bool _isLoadingServices = false;
  bool _isLoading = false;

   List<String> _services = [
    // "Residential Snow Removal",
    // "Commercial Snow Removal",
    // "Driveway Clearing",
    // "Sidewalk Shoveling",
    // "Full Property Cleanup",
  ];

  List<Agency> _agencies = [];

String? _selectedService;

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


  // Future<void> _fetchAgencies() async {
  //   setState(() {
  //     _isLoadingAgencies = true;
  //   });
  //
  //   try {
  //     String apiUrl =
  //         "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/companies";
  //
  //     final response = await http.get(Uri.parse(apiUrl));
  //
  //     if (response.statusCode == 200) {
  //       Map<String, dynamic> data = jsonDecode(response.body);
  //       List<Map<String, dynamic>> fetchedAgencies = [];
  //
  //       if (data.containsKey('documents')) {
  //         fetchedAgencies = (data['documents'] as List).map((doc) {
  //           return {
  //             "name": doc['fields']['companyName']?['stringValue'] ?? 'Unknown',
  //             // "rating": doc['fields']['rating']?['doubleValue']?.toDouble() ?? 0.0,
  //             // Add other fields as needed
  //           };
  //         }).toList();
  //       }
  //
  //       setState(() {
  //         agencies = fetchedAgencies;
  //       });
  //     } else {
  //       print("Failed to fetch agencies: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print("Error fetching agencies: $e");
  //   } finally {
  //     setState(() {
  //       _isLoadingAgencies = false;
  //     });
  //   }
  // }


  //AgencyList
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
        _latitude = position.latitude; // ✅ Store latitude
        _longitude = position.longitude; // ✅ Store longitude
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
    if (picked != null || picked != _selectedDate) {
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
    if (picked != null || picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formkey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Please select a date"),
              backgroundColor: Colors.teal[200]),
        );
        return;
      }

      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Please select a time"),
              backgroundColor: Colors.teal[200]),
        );
        return;
      }

      // Retrieve stored user ID
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId'); // Retrieve stored user ID

      if (userId == null) {
        print("User ID not found!");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("User not authenticated")));
        return;
      }
      List<String> imageUrls = [];
      for (var image in _selectedImages) {
        String imageUrl = await uploadImage(File(image.path)); // ✅ Upload Image
        imageUrls.add(imageUrl);
      }

      String apiUrl =
          "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/bid_requests";

      Map<String, dynamic> formData = {
        "fields": {
          "userId": {"stringValue": userId}, // Store user ID
          "area": {"stringValue": _areaControlller.text},
          "serviceType": {"stringValue": _selectedServiceType},
          "latitude": {"doubleValue": _latitude!}, // ✅ Ensure non-null
          "longitude": {"doubleValue": _longitude!},
          "address": {"stringValue": _currentAddress},
          "date": {"stringValue": _selectedDate?.toIso8601String() ?? ""},
          "time": {"stringValue": _selectedTime?.format(context) ?? ""},
          "imageUrls": {
            "arrayValue": {
              "values": imageUrls.map((url) => {"stringValue": url}).toList()
            }
          },
          "requestType": {"stringValue": _selectedOptions ?? "Bid"},
          "selectedAgency": {
            "stringValue":
                _selectedOptions == "Direct" ? _selectedAgency ?? "" : ""
          },
          "status": {"stringValue": "pending"},
        }
      };

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(formData),
        );
        print("Response Status Code: ${response.statusCode}");
        print("Response Body: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (_selectedAddress == null ||
              !_previousAddresses.contains(_locationController.text)) {
            _saveAddress(_locationController.text);
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Request submitted successfully"),
              backgroundColor: Colors.teal[200]));
          _formkey.currentState!.reset();
          setState(() {
            _selectedDate = null;
            _selectedTime = null;
            _selectedAgency = null;
            _selectedImages = [];
            _locationController.clear();
            _areaControlller.clear();
          });
        } else {
          print("Error: ${response.body}");
          throw Exception("Failed to submit request");
        }
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to submit request")));
      }
    }
  }

  // Future<void> _saveAddress(String address) async{
  //   String apiUrl ="https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/addresses";
  //   Map<String,dynamic> addressData ={
  //     "fields": {"address": {"stringValue": address}}
  //   };
  //   await http.post(
  //     Uri.parse(apiUrl),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode(addressData),
  //   );
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
                            border: OutlineInputBorder()),
                        validator: (value) =>
                            value!.isEmpty ? "Enter area" : null,
                      ),
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedService,
                        decoration: InputDecoration(
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
                      ),

                      // SizedBox(height: 15),
                      //     TextFormField(
                      //         style: GoogleFonts.poppins(),
                      //       controller: _locationController,
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
                      //     ),
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
                        onPressed: _submitForm,
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
