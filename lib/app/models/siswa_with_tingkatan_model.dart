// lib/app/models/siswa_with_tingkatan_model.dart

class SiswaWithTingkatanModel {
  final String uid;
  final String nama;
  final Map<String, dynamic>? tingkatanSaatIni;

  SiswaWithTingkatanModel({
    required this.uid,
    required this.nama,
    this.tingkatanSaatIni,
  });

  String get namaTingkatan => (tingkatanSaatIni?['nama'] as String?) ?? 'Belum Diatur';
}