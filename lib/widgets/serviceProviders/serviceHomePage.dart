import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/widgets/serviceProviders/bidPlaceform.dart';
import 'package:snowplow/widgets/serviceProviders/directPlaceOrder.dart';

class ServiceProviderHome extends StatefulWidget {
  const ServiceProviderHome({super.key});

  @override
  State<ServiceProviderHome> createState() => _ServiceProviderHomeState();
}

class _ServiceProviderHomeState extends State<ServiceProviderHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> bidsRequests = [];
  List<dynamic> directRequests = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchRequests();
  }



  Future<void> fetchRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? companyId = prefs.getString("companyId"); // Get logged-in company's ID

    if (companyId == null) {
      setState(() {
        errorMessage = "No company ID found. Please log in again.";
        isLoading = false;
      });
      return;
    }

    String apiUrl = "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/bid_requests";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('documents')) {
          List<dynamic> allRequests = data['documents'].map((doc) {
            var fields = doc['fields'] ?? {}; // Handle missing fields
            return {
              'id': doc['name'].split('/').last,
              "title": fields.containsKey('area') ? fields['area']['stringValue'] ?? "No Title" : "No Title",
              "description": fields.containsKey('address') ? fields['address']['stringValue'] ?? "No Description" : "No Description",
              "status": fields.containsKey('status') ? fields['status']['stringValue'] ?? "Unknown" : "Unknown",
              "requestType": fields.containsKey('requestType') ? fields['requestType']['stringValue'] ?? "Bid" : "Bid",
              "companyId": fields.containsKey('companyId') ? fields['companyId']['stringValue'] ?? "" : "",
            };
          }).toList();

          setState(() {
            bidsRequests = allRequests.where((req) =>
            req["requestType"] == "Bid" &&
                (req["status"] == "pending" || req["status"] == "bid placed")
            ).toList();

            // ✅ Filter Direct Requests Based on Logged-in Company
            directRequests = allRequests.where((req) =>
            req["requestType"] == "Direct" && req["companyId"] == companyId
            ).toList();

            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load requests');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text("Request",style: GoogleFonts.poppins(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 26)),
        bottom: TabBar(
          controller: _tabController,
          unselectedLabelStyle: GoogleFonts.poppins(color: Colors.white,fontWeight: FontWeight.bold),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold,color: Colors.blue),
          tabs: [
            Tab(text: 'Bids'),
            Tab(text: 'Direct'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildRequestList(bidsRequests),
          buildRequestList(directRequests),
        ],
      ),
    );
  }

  Widget buildRequestList(List<dynamic> requests) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (requests.isEmpty) {
      return Center(child: Text('No requests found'));
    }

    return RefreshIndicator(
      onRefresh: fetchRequests,
      child: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          var request = requests[index];

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(request["title"].toString()),
              subtitle: Text(request["description"].toString()),
              trailing: Chip(
                label: Text(request["status"].toString()),
                backgroundColor: _getStatusColor(request["status"].toString()),
              ),
              onTap: () {
                if(request["requestType"]=="Bid") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PlaceBidScreen(requestId: request['id'])
                    ),
                  );
                  fetchRequests();
                }else if(request["requestType"] == "Direct"){
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context)=>
                          directPlaceOrder(requestId:request['id'])),
                  );
                  fetchRequests();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "accepted":
        return Colors.green;
      case "completed":
        return Colors.blue;
      case "bid placed":
        return Colors.green[300]!;
      default:
        return Colors.grey;
    }
  }
}
