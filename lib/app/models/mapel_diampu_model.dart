// lib/app/models/mapel_diampu_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MapelDiampuModel {
  final String idMapel;
  final String namaMapel;
  final String idKelas;
  final String idGuru;
  final String namaGuru;
  final bool isPengganti;
  final String? namaGuruAsli; 

  MapelDiampuModel({
    required this.idMapel,
    required this.namaMapel,
    required this.idKelas,
    required this.idGuru,
    required this.namaGuru,
    this.isPengganti = false,
    this.namaGuruAsli, 
  });

  factory MapelDiampuModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, {bool isPengganti = false}) {
    final data = doc.data() ?? {};
    return MapelDiampuModel(
      idMapel: doc.id,
      // [PERBAIKAN BACKWARD-COMPATIBLE]: Coba baca 'namaMapel' dulu, jika tidak ada, fallback ke 'namamatapelajaran'.
      namaMapel: data['namaMapel'] ?? data['namamatapelajaran'] ?? 'Tanpa Nama Mapel', 
      idKelas: data['idKelas'] ?? 'Tanpa ID Kelas',
      idGuru: data['idGuru'] ?? '',
      namaGuru: data['namaGuru'] ?? 'Tanpa Nama Guru', // Menggunakan 'namaGuru' yang baru
      isPengganti: isPengganti,
      namaGuruAsli: data['namaGuruAsli'],
    );
  }
}