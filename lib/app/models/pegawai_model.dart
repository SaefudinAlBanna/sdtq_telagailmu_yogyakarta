// Salin dan ganti seluruh isi file pegawai_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/user_role_enum.dart';

class PegawaiModel {
  final String uid;
  final String nama;
  final String? alias;
  final UserRole role;
  final String? profileImageUrl;
  
  // [BARU] Tambahkan properti untuk tugas dan role mentah
  final List<String> tugas;
  final String? roleString; // Untuk debugging jika role tidak diketahui

  PegawaiModel({
    required this.uid,
    required this.nama,
    this.alias,
    required this.role,
    this.profileImageUrl,
    required this.tugas, // Tambahkan di constructor
    this.roleString,    // Tambahkan di constructor
  });

  factory PegawaiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final roleMentah = data['role'] as String?;

    return PegawaiModel(
      uid: doc.id,
      nama: data['nama'] ?? 'Tanpa Nama',
      alias: data['alias'] as String?,
      
      // Gunakan role mentah untuk konversi
      role: UserRole.fromString(roleMentah), 
      
      profileImageUrl: data['profileImageUrl'] as String?,
      
      // [BARU] Ambil data 'tugas' dari Firestore. 
      // Default ke list kosong jika tidak ada atau bukan list.
      tugas: List<String>.from(data['tugas'] ?? []),

      // [BARU] Simpan string role mentah untuk referensi
      roleString: roleMentah, 
    );
  }
}