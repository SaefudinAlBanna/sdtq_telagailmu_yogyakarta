// lib/app/models/pengajuan_ujian_model.dart

class PengajuanUjianModel {
  final String id; // ID dokumen ujian
  final String uidSiswa;
  final String namaSiswa;
  final String kelasId;
  final String namaPengaju;

  PengajuanUjianModel({
    required this.id,
    required this.uidSiswa,
    required this.namaSiswa,
    required this.kelasId,
    required this.namaPengaju,
  });

  factory PengajuanUjianModel.fromFirestore(doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PengajuanUjianModel(
      id: doc.id,
      uidSiswa: data['uidSiswa'] ?? '',
      namaSiswa: data['namaSiswa'] ?? 'Tanpa Nama',
      kelasId: data['kelasId'] ?? 'N/A',
      namaPengaju: data['namaPengaju'] ?? 'N/A',
    );
  }
}