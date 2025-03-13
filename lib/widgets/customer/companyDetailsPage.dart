import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snowplow/widgets/customer/directRequestFrom.dart';

class CompanyDetailsPage extends StatelessWidget {
  final Map<String, dynamic> company;

  const CompanyDetailsPage({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        title: Text(company['name'],
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📍 Address: ${company['address']}",
                style: GoogleFonts.poppins(fontSize: 18)),
            Text("📧 Email: ${company['email']}",
                style: GoogleFonts.poppins(fontSize: 18)),
            Text("📞 Contact: ${company['contact']}",
                style: GoogleFonts.poppins(fontSize: 18)),
            Text("⭐ Rating: ${company['rating']}",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[200],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => directRequestForm(selectedAgency: company['name'], agencyRating: 2, companyId: company['id']),
                    ),
                  );
                },
                child: Text("Request Snow Removal",
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
