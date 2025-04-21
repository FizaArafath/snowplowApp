import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderList extends StatefulWidget {
  const OrderList({super.key});

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> with TickerProviderStateMixin {
  final String apiUrl = "https://snowplow.celiums.com/api/requests/list";
  final String bidApiUrl = "https://snowplow.celiums.com/api/bids/list";

  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> bidRequests = [];

  bool isLoadingRequests = false;
  bool isLoadingBids = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this); // ✅ FIXED HERE
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {
        fetchBidRequests();
      }
    });

    fetchRequest();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchRequest() async {
    if (!mounted) return;
    setState(() {
      isLoadingRequests = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId");

      if (userId == null) return;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "agency_id": userId,
          "customer_id": "24",
          "per_page": "10",
          "page": "0",
          "api_mode": "test"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == 1 && data["data"] != null) {
          List<Map<String, dynamic>> loadedRequests = [];

          for (var req in data["data"]) {
            String status = (req["status"] ?? "0").toString().trim();

            String date = "N/A";
            try {
              final rawDate = req["preferred_date"];
              if (rawDate != null && rawDate != "") {
                date = DateFormat("yyyy-MM-dd").format(DateTime.parse(rawDate));
              }
            } catch (_) {}

            String time = "N/A";
            try {
              final rawTime = req["preferred_time"];
              if (rawTime != null && rawTime.contains(":")) {
                List<String> timeParts = rawTime.split(':');
                time = "${timeParts[0]}:${timeParts[1]}";
              }
            } catch (_) {}

            loadedRequests.add({
              "request_id": req["request_id"]?.toString() ?? "",
              "service_area": req["service_area"]?.toString() ?? "Unknown",
              "preferred_date": date,
              "preferred_time": time,
              "requestType": "Direct",
              "selectedAgency": req["agency_id"]?.toString() ?? "N/A",
              "status": status,
              "service_street": req["service_street"]?.toString() ?? "",
              "service_type": req["service_type"]?.toString() ?? "",
              "created": req["created"]?.toString() ?? "",
            });
          }

          if (!mounted) return;
          setState(() {
            requests = loadedRequests;
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching requests: $e");
    }

    if (!mounted) return;
    setState(() {
      isLoadingRequests = false;
    });
  }



  Future<void> fetchBidRequests() async {
    if (!mounted) return;
    setState(() {
      isLoadingBids = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId");

      if (userId == null) return;

      final response = await http.post(
        Uri.parse(bidApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "customer_id": userId,
          "per_page": "10",
          "page": "0",
          "api_mode": "test"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == 1 && data["data"] != null) {
          List<Map<String, dynamic>> loadedBids = [];

          for (var item in data["data"]) {
            loadedBids.add({
              "id": item["id"]?.toString() ?? "",
              "service_type": item["service_type"]?.toString() ?? "",
              "service_street": item["service_street"]?.toString() ?? "",
              "service_area": item["service_area"]?.toString() ?? "",
              "preferred_date": item["preferred_date"]?.toString() ?? "",
              "preferred_time": item["preferred_time"]?.toString() ?? "",
              "urgency_level": item["urgency_level"]?.toString() ?? "",
              "created": item["created"]?.toString() ?? "",
              "status": item["status"]?.toString() ?? "0",
            });
          }
          print("loaded:$loadedBids");

          if (!mounted) return;
          setState(() {
            bidRequests = loadedBids;
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching bid requests: $e");
    }

    if (!mounted) return;
    setState(() {
      isLoadingBids = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Snow Plow Requests",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal[100],
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => Navigator.pushNamed(context, "/request"),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: "Direct Requests"),
              Tab(text: "Bid Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildRequestList(requests, isLoadingRequests),
            buildRequestList(bidRequests, isLoadingBids),
          ],
        ),
      ),
    );
  }

  Widget buildRequestList(List<Map<String, dynamic>> list, bool isLoading) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(
        child: Text(
          "No requests found!",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final request = list[index];
        return InkWell(
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => RequestDetailScreen(requestData: request),
            //   ),
            // );
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Service: ${request["service_type"]}",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500)),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            request["status"] == "0"
                                ? "PENDING"
                                : request["status"] == "1"
                                    ? "ACCEPTED"
                                    : request["status"] == "2"
                                        ? "COMPLETED"
                                        : "UNKNOWN",
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.teal),
                          ),
                        ),
                      ]),
                  SizedBox(height: 8),
                  if (request["service_street"] != null)
                    Row(children: [
                      Icon(Icons.location_on_outlined, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(request["service_street"],
                              style: GoogleFonts.poppins())),
                    ]),
                  SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.map_outlined, size: 16),
                    SizedBox(width: 8),
                    Text("Area: ${request["service_area"] ?? "Unknown"}",
                        style: GoogleFonts.poppins()),
                  ]),
                  SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 16),
                    SizedBox(width: 8),
                    Text("Date: ${request["preferred_date"] ?? "N/A"}",
                        style: GoogleFonts.poppins()),
                  ]),
                  SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.access_time_outlined, size: 16),
                    SizedBox(width: 8),
                    Text("Time: ${request["preferred_time"] ?? "N/A"}",
                        style: GoogleFonts.poppins()),
                  ]),
                  if (request["urgency_level"] != null &&
                      request["urgency_level"].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(children: [
                        Icon(Icons.speed_outlined, size: 16),
                        SizedBox(width: 8),
                        Text("Urgency: ${request["urgency_level"]}",
                            style: GoogleFonts.poppins()),
                      ]),
                    ),
                  SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.schedule_outlined, size: 16),
                    SizedBox(width: 8),
                    Text("Created: ${request["created"] ?? "N/A"}",
                        style: GoogleFonts.poppins()),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildBidRequestList(
      List<Map<String, dynamic>> bidRequests, bool isLoading) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (bidRequests.isEmpty) {
      return Center(
        child: Text(
          "No bid requests found!",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: bidRequests.length,
      itemBuilder: (context, index) {
        final bid = bidRequests[index];
        print("bid:$bid");
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Service: ${bid["service_type"]}",
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bid["status"] == "0"
                              ? "PENDING"
                              : bid["status"] == "1"
                                  ? "ACCEPTED"
                                  : bid["status"] == "2"
                                      ? "COMPLETED"
                                      : "UNKNOWN",
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue),
                        ),
                      ),
                    ]),
                SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(bid["service_street"],
                          style: GoogleFonts.poppins())),
                ]),
                SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.map_outlined, size: 16),
                  SizedBox(width: 8),
                  Text("Area: ${bid["service_area"]}",
                      style: GoogleFonts.poppins()),
                ]),
                SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 16),
                  SizedBox(width: 8),
                  Text("Date: ${bid["preferred_date"]}",
                      style: GoogleFonts.poppins()),
                ]),
                SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.access_time_outlined, size: 16),
                  SizedBox(width: 8),
                  Text("Time: ${bid["preferred_time"]}",
                      style: GoogleFonts.poppins()),
                ]),
                if (bid["urgency_level"] != null &&
                    bid["urgency_level"].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(children: [
                      Icon(Icons.speed_outlined, size: 16),
                      SizedBox(width: 8),
                      Text("Urgency: ${bid["urgency_level"]}",
                          style: GoogleFonts.poppins()),
                    ]),
                  ),
                SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.schedule_outlined, size: 16),
                  SizedBox(width: 8),
                  Text("Created: ${bid["created"] ?? "N/A"}",
                      style: GoogleFonts.poppins()),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}
