class SiswaLaporanModel {
  final String uid;
  final String nama;
  final String nisn;
  
  // Hasil kalkulasi
  final double nilaiAkhirRapor;
  final double rataRataHarian;
  final int nilaiPts;
  final int nilaiPas;

  SiswaLaporanModel({
    required this.uid,
    required this.nama,
    required this.nisn,
    required this.nilaiAkhirRapor,
    required this.rataRataHarian,
    required this.nilaiPts,
    required this.nilaiPas,
  });
}