// lib/app/models/halaqah_setoran_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HalaqahSetoranModel {
  final String id;
  final String status;
  final Timestamp tanggalTugas;
  final Timestamp? tanggalDinilai;
  final Map<String, dynamic> tugas;
  final Map<String, dynamic> nilai;
  final String catatanPengampu;
  final String catatanOrangTua;
  
  // [PERBAIKAN] Tambahkan field-field ini
  final String idPengampu;
  final String namaPengampu;
  final String? aliasPengampu;
  final String idGrup;
  final String tahunAjaran;
  final String semester;
  final bool isDinilaiPengganti;
  final String? namaPenilai;

  HalaqahSetoranModel({
    required this.id,
    required this.status,
    required this.tanggalTugas,
    this.tanggalDinilai,
    required this.tugas,
    required this.nilai,
    required this.catatanPengampu,
    required this.catatanOrangTua,
    
    // [PERBAIKAN] Tambahkan ke konstruktor
    required this.idPengampu,
    required this.namaPengampu,
    this.aliasPengampu,
    required this.idGrup,
    required this.tahunAjaran,
    required this.semester,
    this.isDinilaiPengganti = false,
    this.namaPenilai,
  });

  factory HalaqahSetoranModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HalaqahSetoranModel(
      id: doc.id,
      status: data['status'] ?? 'Selesai',
      tanggalTugas: data['tanggalTugas'] ?? Timestamp.now(),
      tanggalDinilai: data['tanggalDinilai'],
      tugas: Map<String, dynamic>.from(data['tugas'] ?? {}),
      nilai: Map<String, dynamic>.from(data['nilai'] ?? {}),
      catatanPengampu: data['catatanPengampu'] ?? '',
      catatanOrangTua: data['catatanOrangTua'] ?? '',

      // [PERBAIKAN] Ambil data tambahan dari Firestore
      idPengampu: data['idPengampu'] ?? '',
      namaPengampu: data['namaPengampu'] ?? 'N/A',
      aliasPengampu: data['aliasPengampu'] as String?,
      idGrup: data['idGrup'] ?? '',
      tahunAjaran: data['tahunAjaran'] ?? '',
      semester: data['semester'] ?? '',
      isDinilaiPengganti: data['isDinilaiPengganti'] ?? false,
      namaPenilai: data['namaPenilai'] as String?,
    );
  }
}