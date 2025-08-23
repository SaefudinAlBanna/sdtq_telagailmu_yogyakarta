// lib/app/models/absensi_rekap_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AbsensiRekapModel {
  final String id; // Tanggal (YYYY-MM-DD)
  final Timestamp tanggal;
  final Map<String, int> rekap; // {'hadir': 25, 'sakit': 1, ...}
  final Map<String, dynamic> siswa; // Data siswa yang tidak hadir

  AbsensiRekapModel({
    required this.id,
    required this.tanggal,
    required this.rekap,
    required this.siswa,
  });

  factory AbsensiRekapModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AbsensiRekapModel(
      id: doc.id,
      tanggal: data['tanggal'] ?? Timestamp.now(),
      rekap: Map<String, int>.from(data['rekap'] ?? {}),
      siswa: Map<String, dynamic>.from(data['siswa'] ?? {}),
    );
  }
}