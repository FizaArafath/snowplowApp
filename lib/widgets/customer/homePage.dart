import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'companyDetailsPage.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  List<dynamic> companies = [];
  List<dynamic> filteredCompanies = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();



  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }



  Future<void> fetchCompanies() async {
    const String apiUrl =
        "https://firestore.googleapis.com/v1/projects/snow-plow-d24c0/databases/(default)/documents/companies";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] as List<dynamic>?;

        if (documents != null) {
          List<dynamic> companyList = documents.map((doc) {
            final fields = doc['fields'] ?? {};

            return {
              'name': fields['companyName']?['stringValue'] ?? 'Unknown',
              'email': fields['email']?['stringValue'] ?? 'No Email',
              'address': fields['address']?['stringValue'] ?? 'No Address',
              'contact': fields['contact']?['stringValue'] ?? 'No Contact',
              'id':fields['companyId']?['stringValue']?? ''
              // 'rating': fields['rating']?['stringValue'] ?? 'No Rating',
            };
          }).toList();

          setState(() {
            companies = companyList;
            filteredCompanies = companyList;
            isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load companies");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("🔥 Error fetching companies: $e");
    }
  }

  void searchCompany(String query) {
    setState(() {
      filteredCompanies = companies
          .where((company) =>
      company['name'].toLowerCase().contains(query.toLowerCase()) ||
          company['address'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text("Welcome to SnowPlow",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search company...",
                prefixIcon: Icon(Icons.search, color: Colors.teal[700]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onChanged: searchCompany,
            ),
          ),

          // Company List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCompanies.isEmpty
                ? const Center(child: Text("No companies found"))
                : ListView.builder(
              itemCount: filteredCompanies.length,
              itemBuilder: (context, index) {
                var company = filteredCompanies[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Icon(Icons.business, color: Colors.teal[700]),
                    title: Text(company['name'],
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500)),
                    subtitle: Text(company['address'],
                        style: GoogleFonts.poppins(fontSize: 14)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyDetailsPage(company: company),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
