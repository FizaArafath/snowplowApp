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
    fetchBidRequests();
  }

  Future<void> fetchBidRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? customerId = prefs.getString("userId");

    if (customerId == null) {
      setState(() {
        errorMessage = "No user ID found. Please log in again.";
        isLoading = false;
      });
      return;
    }

    String apiUrl = "https://snowplow.celiums.com/api/bids/list";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "customer_id": customerId,
          "per_page": "10",
          "page": "0",
          "api_mode": "test",
        }),
      );

      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] != 1) {
          setState(() {
            bidsRequests = [];
            errorMessage = decoded["message"] ?? "No requests found.";
            isLoading = false;
          });
          return;
        }

        final List<dynamic> bids = decoded["data"];

        setState(() {
          bidsRequests = bids.map((bid) {
            return {
              "bid_request_id": bid["bid_request_id"]?.toString(),
              "customer_id": bid["customer_id"]?.toString(),
              "service_street": bid["service_street"] ?? "No Street Info",
              "service_city": bid["service_city"] ?? "No City Info",
              "service_state": bid["service_state"] ?? "No State Info",
              "service_zip": bid["service_zip"] ?? "",
              "service_latitude": bid["service_latitude"] ?? "",
              "service_longitude": bid["service_longitude"] ?? "",
              "service_type": bid["service_type"] ?? "",
              "service_area": bid["service_area"] ?? "No Area Info",
              "preferred_date": bid["preferred_date"] ?? "",
              "preferred_time": bid["preferred_time"] ?? "",
              "urgency_level": bid["urgency_level"] ?? "",
              "image": bid["image"] ?? "",
              "created": bid["created"] ?? "",
              "updated": bid["updated"] ?? "",
              "status": bid["status"] == "0" ? "Pending" : "Completed",
              "requestType": "Bid",
            };
          }).toList();

          isLoading = false;
          errorMessage = "";
        });
      } else {
        throw Exception('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Exception: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text(
          "Request",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          unselectedLabelStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue),
          tabs: const [
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
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (requests.isEmpty) {
      return const Center(child: Text('No requests found'));
    }

    return RefreshIndicator(
      onRefresh: fetchBidRequests,
      child: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          var request = requests[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(request["title"]?.toString() ?? 'No Title'),
              subtitle: Text(request["comments"]?.toString() ?? 'No Area Info'),
              trailing: Chip(
                label: Text(request["status"]?.toString() ?? 'Pending'),
                backgroundColor: _getStatusColor(request["status"]?.toString() ?? ''),
              ),
              onTap: () {
                String? requestId = request['id']?.toString();
                String? customerId = request['customer_id']?.toString();

                if (requestId == null || customerId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Missing required request info')),
                  );
                  return;
                }

                if (request["requestType"] == "Bid") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaceBidScreen(
                        requestId: requestId,
                        customerId: customerId,
                        customerAddress: request["title"] ?? "N/A",
                        approximateArea: request["comments"] ?? "N/A",
                        preferredDate: request["preferred_date"] ?? "N/A",
                        preferredTime: request["preferred_time"] ?? "N/A",
                        photoUrl: request["image"] != null
                            ? "https://snowplow.celiums.com/uploads/${request['image']}"
                            : "https://via.placeholder.com/150",
                        bidRequestList: bidsRequests,
                        onBidPlaced: fetchBidRequests,
                      ),
                    ),
                  ).then((_) => fetchBidRequests());
                } else if (request["requestType"] == "Direct") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => directPlaceOrder(
                        requestId: requestId,
                        customerId: customerId,
                        customerAddress: request["title"] ?? "N/A",
                        approximateArea: request["comments"] ?? "N/A",
                        photoUrl: request["image"] != null
                            ? "https://snowplow.celiums.com/uploads/${request['image']}"
                            : "https://via.placeholder.com/150",
                        preferredTime: request["preferred_time"] ?? "N/A",
                        preferredDate: request["preferred_date"] ?? "N/A",
                      ),
                    ),
                  ).then((_) => fetchBidRequests());
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
