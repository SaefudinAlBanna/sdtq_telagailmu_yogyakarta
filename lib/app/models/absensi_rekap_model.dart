// lib/app/models/absensi_rekap_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AbsensiRekapModel {
  final Timestamp tanggal;
  final Map<String, dynamic> rekap;
  final Map<String, dynamic> siswa;
  final String? namaWaliKelas; // [BARU] Tambahkan properti ini

  AbsensiRekapModel({
    required this.tanggal,
    required this.rekap,
    required this.siswa,
    this.namaWaliKelas, // [BARU] Tambahkan ke constructor
  });

  factory AbsensiRekapModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return AbsensiRekapModel(
      tanggal: data['tanggal'] as Timestamp? ?? Timestamp.now(),
      rekap: data['rekap'] as Map<String, dynamic>? ?? {},
      
      // [PERBAIKAN KUNCI]
      // Langsung baca field 'siswa' dari data.
      // Jika tidak ada atau bukan Map, kembalikan map kosong.
      siswa: data['siswa'] as Map<String, dynamic>? ?? {},
      
      namaWaliKelas: data['namaWaliKelas'] as String?,
    );
  }
}