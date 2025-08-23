// lib/app/modules/rekap_absensi/controllers/rekap_absensi_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/absensi_rekap_model.dart';

class RekapAbsensiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // State
  final isLoading = false.obs;
  final RxString scope = "kelas".obs; // 'kelas' atau 'sekolah'
  final Rxn<String> selectedKelasId = Rxn<String>();
  final RxList<DocumentSnapshot> daftarKelas = <DocumentSnapshot>[].obs;
  
  // Date Range State
  final Rx<DateTime> startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  // Data State
  final RxList<AbsensiRekapModel> rekapData = <AbsensiRekapModel>[].obs;
  final RxMap<String, int> totalRekap = <String, int>{
    'hadir': 0, 'sakit': 0, 'izin': 0, 'alfa': 0
  }.obs;

  // @override
  // void onInit() {
  //   super.onInit();
  //   final args = Get.arguments as Map<String, dynamic>? ?? {};
  //   scope.value = args['scope'] ?? 'kelas';
    
  //   if (scope.value == 'kelas') {
  //     selectedKelasId.value = args['id'];
  //     fetchRekapData();
  //   } else {
  //     _fetchDaftarKelas();
  //   }
  // }

  @override
  void onInit() {
    super.onInit();
    // --- [PERBAIKAN & DEBUGGING] ---
    // Gunakan Get.arguments langsung untuk menghindari cast error
    if (Get.arguments is Map<String, dynamic>) {
      final args = Get.arguments as Map<String, dynamic>;
      scope.value = args['scope'] ?? 'kelas';
      
      // [DEBUG] Tampilkan argumen yang diterima
      print(">> DEBUG REKAP: Argumen diterima -> scope: ${scope.value}, id: ${args['id']}");

      if (scope.value == 'kelas') {
        selectedKelasId.value = args['id'];
        fetchRekapData();
      } else { // scope == 'sekolah'
        _fetchDaftarKelas();
      }
    } else {
      // Fallback jika tidak ada argumen sama sekali
      print(">> DEBUG REKAP: TIDAK ADA ARGUMEN DITERIMA. Masuk mode default (kelas).");
      // Cek apakah user adalah wali kelas dan set ID-nya
      if (configC.infoUser.containsKey('kelasDiampu')) {
        selectedKelasId.value = configC.infoUser['kelasDiampu'];
        fetchRekapData();
      }
    }
    // --- AKHIR PERBAIKAN ---
  }

  Future<void> _fetchDaftarKelas() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('kelastahunajaran').get();
    daftarKelas.assignAll(snapshot.docs);
  }

  Future<void> fetchRekapData() async {
    if (selectedKelasId.value == null) return;
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('kelastahunajaran').doc(selectedKelasId.value)
          .collection('semester').doc(configC.semesterAktif.value)
          .collection('absensi')
          .where('tanggal', isGreaterThanOrEqualTo: startDate.value)
          .where('tanggal', isLessThanOrEqualTo: endDate.value)
          .orderBy('tanggal', descending: true)
          .get();

      rekapData.assignAll(snapshot.docs.map((doc) => AbsensiRekapModel.fromFirestore(doc)).toList());
      _calculateTotalRekap();
    } catch (e) { Get.snackbar("Error", "Gagal memuat rekap: $e"); } 
    finally { isLoading.value = false; }
  }

  void _calculateTotalRekap() {
    int hadir = 0, sakit = 0, izin = 0, alfa = 0;
    for (var rekap in rekapData) {
      hadir += rekap.rekap['hadir'] ?? 0;
      sakit += rekap.rekap['sakit'] ?? 0;
      izin += rekap.rekap['izin'] ?? 0;
      alfa += rekap.rekap['alfa'] ?? 0;
    }
    totalRekap['hadir'] = hadir;
    totalRekap['sakit'] = sakit;
    totalRekap['izin'] = izin;
    totalRekap['alfa'] = alfa;
  }

  void pickDateRange(BuildContext context) async {
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate.value, end: endDate.value),
    );

    if (newRange != null) {
      startDate.value = newRange.start;
      endDate.value = newRange.end;
      fetchRekapData();
    }
  }
}