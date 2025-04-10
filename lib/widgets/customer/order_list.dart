import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class orderList extends StatefulWidget {
  const orderList({super.key});

  @override
  State<orderList> createState() => _orderListState();
}

class _orderListState extends State<orderList> {
  final String apiUrl = "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/bid_requests";

  List<Map<String,dynamic>> requests =[];

  @override
  void initState() {
    super.initState();
    fetchRequest();
  }



  // Future<void> fetchRequest() async {
  //   try {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     String? userId = prefs.getString("userId");  // Retrieve logged-in user ID
  //
  //     if (userId == null) {
  //       print("⚠️ User ID not found!");
  //       return;
  //     }
  //
  //     final response = await http.get(
  //       Uri.parse(apiUrl),
  //       headers: {"Content-Type": "application/json"},
  //     );
  //
  //     print("Response Code: ${response.statusCode}");
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       List<Map<String, dynamic>> loadedRequests = [];
  //
  //       if (data["documents"] != null) {
  //         for (var doc in data["documents"]) {
  //           var fields = doc["fields"];
  //
  //           // Extract request owner's ID from Firestore
  //           String? requestOwnerId = fields.containsKey("userId") ? fields["userId"]["stringValue"] : null;
  //
  //           // 🔥 Only process requests that belong to the logged-in user
  //           if (requestOwnerId != null && requestOwnerId == userId) {
  //             String? rawStatus = fields.containsKey("status") ? fields["status"]["stringValue"] : null;
  //             String status = rawStatus?.trim().toLowerCase() ?? "pending";
  //
  //             loadedRequests.add({
  //               "area": fields.containsKey("area") ? fields["area"]["stringValue"] ?? "Unknown" : "Unknown",
  //               "date": fields.containsKey("date") ? fields["date"]["stringValue"] ?? "N/A" : "N/A",
  //               "time": fields.containsKey("time") ? fields["time"]["stringValue"] ?? "N/A" : "N/A",
  //               "requestType": fields.containsKey("serviceType") ? fields["serviceType"]["stringValue"] ?? "Unknown" : "Unknown",
  //               "selectedAgency": fields.containsKey("agency") ? fields["agency"]["stringValue"] ?? "N/A" : "N/A",
  //               "status": status,
  //             });
  //
  //             print("✅ Added Request for User ID: $userId -> ${loadedRequests.last}");
  //           }
  //         }
  //       }
  //
  //       setState(() {
  //         requests = loadedRequests;
  //       });
  //
  //       print("🔥 Total Requests for Logged-In User: ${requests.length}");
  //     } else {
  //       throw Exception("Failed to load requests. Status Code: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print("❌ Error fetching requests: $e");
  //   }
  // }

  final String Url = "https://snowplow.celiums.com/api/requests/getrequests"; // your PHP endpoint

  Future<void> fetchRequest() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId");

      if (userId == null) {
        print("⚠️ User ID not found!");
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "customer_id": userId,
          "api_mode": "test"
        }),
      );

      print("Response Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == 1 && data["data"] != null) {
          List<Map<String, dynamic>> loadedRequests = [];

          for (var req in data["data"]) {
            String status = (req["status"] ?? "pending").toString().toLowerCase().trim();

            loadedRequests.add({
              "area": req["service_area"] ?? "Unknown",
              "date": req["preferred_date"] ?? "N/A",
              "time": req["preferred_time"] ?? "N/A",
              "requestType": req["service_type"] ?? "Unknown",
              "selectedAgency": req["agency_id"] ?? "N/A",
              "status": status,
            });
          }

          setState(() {
            requests = loadedRequests;
          });

          print("✅ Loaded ${requests.length} requests");
        } else {
          print("⚠️ No request data found");
        }
      } else {
        throw Exception("Failed to load requests. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching requests: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Snow Plow Requests",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20
          ),
          ),
          backgroundColor: Colors.teal[100],
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => Navigator.pushNamed(context, "/request"),
            ),
          ],
          bottom: TabBar(
            unselectedLabelStyle: GoogleFonts.poppins(color: Colors.white,fontWeight: FontWeight.bold),
              labelStyle: GoogleFonts.poppins(color: Colors.blue,fontWeight: FontWeight.bold),
              tabs: [
            Tab(text: "Active"),
            Tab(text: "Pending"),
            Tab(text: "Completed"),
          ]),
        ),
        body: TabBarView(children: [
          requestList("Active"),
          requestList("Pending"),
          requestList("Completed"),
        
        ]),
      ),
    );
  }
  Widget requestList(String status) {
    List<Map<String, dynamic>> filteredRequest;

    if (status == "Active") {
      print("🔥 Before Filtering - All Requests: ${requests.map((r) => r["status"])}");

      filteredRequest = requests.where((req) {
        String requestStatus = req["status"].toString().trim().toLowerCase();
        print("🔍 Checking Request: Status = $requestStatus");

        return requestStatus == "accepted"; // Ensure proper case handling
      }).toList();

      print("✅ Filtered Requests for 'Active': ${filteredRequest.length}");

    } else {
      // Normal filtering for Pending/Completed
      filteredRequest = requests.where((req) =>
      req["status"].toString().trim().toLowerCase() == status.toLowerCase()
      ).toList();
    }

    print("✅ Final Requests for '$status': ${filteredRequest.length}");




    return filteredRequest.isEmpty
        ? Center(child: CircularProgressIndicator())
        : filteredRequest.isEmpty
        ? Center(
      child: Text(
        "No requests found!",
        style: TextStyle(fontSize: 16),
      ),
    )
        : ListView.builder(
      itemCount: filteredRequest.length,
      itemBuilder: (context, index) {
        final request = filteredRequest[index];
        return Card(
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          child: ListTile(
            title: Text("Area : ${request["area"]} sq ft"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date: ${request["date"]}"),
                Text("Time: ${request["time"]}"),
                Text("Type: ${request["requestType"]}"),
                if (request["requestType"] == "Direct")
                  Text("Agency: ${request["selectedAgency"]}"),
                Text("Status: ${request["status"]}", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Icon(Icons.snowing),
          ),
        );
      },
    );
  }

}
