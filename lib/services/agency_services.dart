// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class Agency {
//   final String id;
//   final String name;
//   final String email;
//   final String phone;
//   final String address;
//   final bool isVerified;
//
//   Agency({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.phone,
//     required this.address,
//     required this.isVerified,
//   });
//
//   factory Agency.fromMap(Map<String, dynamic> map, String id) {
//     return Agency(
//       id: id,
//       name: map['name'] ?? '',
//       email: map['email'] ?? '',
//       phone: map['phone'] ?? '',
//       address: map['address'] ?? '',
//       isVerified: map['isVerified'] ?? false,
//     );
//   }
// }
//
// class AgencyService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Stream<List<Agency>> getVerifiedAgencies() {
//     return _firestore
//         .collection('Agency')
//
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs
//           .map((doc) => Agency.fromMap(doc.data(), doc.id))
//           .toList();
//     });
//   }
//
//   Future<Agency?> getAgencyById(String id) async {
//     final doc = await _firestore.collection('agencies').doc(id).get();
//     if (doc.exists) {
//       return Agency.fromMap(doc.data()!, doc.id);
//     }
//     return null;
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';

class Agency{
  final String id;
  final String name;
  final double rating;
  final String email;
  final String uid;

  Agency( {
    required this.id,
    required this.name,
    required this.rating,
    required this.email,
    required this.uid,
  });

  factory Agency.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Agency(
      id: doc.id,
      name: data['name'] ?? '',
      rating: (data['ratings'] ?? 0).toDouble(),  // Convert rating to double
      email: data['mail'] ?? '',
      uid: data['uid'] ?? '',
    );
  }
}

class AgencyService {
//  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Agency>> getVerifiedAgencies() {
    return FirebaseFirestore.instance
        .collection("Agency") // <-- Fetch from "agencyList" instead
        .snapshots()
        .map((snapshot) {
      final agencies = snapshot.docs.map((doc) {
        print("Fetched Agency: ${doc.data()}"); // Debug print
        return Agency.fromFirestore(doc);
      }).toList();
      print("Total Agencies: ${agencies.length}");
      return agencies;
    });
  }
}
