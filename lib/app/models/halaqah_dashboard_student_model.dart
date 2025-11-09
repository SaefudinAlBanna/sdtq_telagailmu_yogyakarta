// lib/app/models/halaqah_dashboard_student_model.dart

class HalaqahDashboardStudentModel {
  final String uid;
  final String nama;
  final String kelasId;
  final Map<String, dynamic>? grupData; // Menggantikan halaqahData

  HalaqahDashboardStudentModel({
    required this.uid,
    required this.nama,
    required this.kelasId,
    this.grupData,
  });

  bool get hasGroup => grupData != null && grupData!.isNotEmpty;
  String get namaGrup => grupData?['namaGrup'] ?? 'N/A';
  String get namaPengampu => grupData?['namaPengampu'] ?? 'N/A';
}