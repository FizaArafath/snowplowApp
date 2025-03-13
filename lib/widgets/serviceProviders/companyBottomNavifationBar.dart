import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/widgets/serviceProviders/companyProfile.dart';
import 'package:snowplow/widgets/serviceProviders/serviceHomePage.dart';

class CompanyBottomNavigation extends StatefulWidget {
  const CompanyBottomNavigation({super.key});

  @override
  State<CompanyBottomNavigation> createState() => _CompanyBottomNavigationState();
}

class _CompanyBottomNavigationState extends State<CompanyBottomNavigation> {
  int _selectedIndex = 0;
  String? _companyId;

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getString("companyId");
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    //pages
    final List<Widget> pages = [
      ServiceProviderHome(),
      _companyId != null
          ? CompanyProfileScreen(companyId: _companyId!)  // Pass companyId
          : Center(child: CircularProgressIndicator())
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
