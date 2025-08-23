// lib/app/models/siswa_simple_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SiswaSimpleModel {
  final String uid;
  final String nama;
  final String kelasId;

  SiswaSimpleModel({required this.uid, required this.nama, required this.kelasId});

  factory SiswaSimpleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SiswaSimpleModel(
      uid: doc.id,
      nama: data['namaLengkap'] ?? data['namasiswa'] ?? 'Tanpa Nama', 
      kelasId: data['kelasId'] ?? 'N/A',
    );
  }
}