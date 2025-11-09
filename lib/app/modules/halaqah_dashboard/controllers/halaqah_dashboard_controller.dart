// lib/app/modules/halaqah_dashboard/controllers/halaqah_dashboard_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_dashboard_student_model.dart';

import '../../../controllers/dashboard_controller.dart';

class HalaqahDashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final DashboardController dashC = Get.find<DashboardController>();

  // State Utama
  final RxBool isLoading = true.obs;
  final RxString selectedKelas = "Semua Kelas".obs;
  final RxList<String> daftarKelas = <String>["Semua Kelas"].obs;
  
  // State Data Hasil Analisis & Statistik
  final RxList<HalaqahDashboardStudentModel> semuaSiswaDiFilter = <HalaqahDashboardStudentModel>[].obs;
  final RxList<HalaqahDashboardStudentModel> siswaTanpaGrup = <HalaqahDashboardStudentModel>[].obs;
  
  final RxInt totalGrupAktif = 0.obs;
  final RxInt siswaDalamSiklusUjian = 0.obs;

  final isRunningScript = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchDaftarKelas();
    await fetchDataForDashboard();
  }

  Future<void> _fetchDaftarKelas() async {
    // Menggunakan logika yang sudah kita perbaiki di Fase 1
    final tahunAjaran = configC.tahunAjaranAktif.value;
    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) return;

    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').get();

    final classNames = snapshot.docs.map((doc) => doc.id.split('-').first).toSet().toList();
    classNames.sort();
    daftarKelas.addAll(classNames);
  }

  Future<void> fetchDataForDashboard() async {
    isLoading.value = true;
    try {
      // Jalankan semua pengambilan data secara paralel untuk efisiensi
      await Future.wait([
        _fetchSiswaData(),
        _fetchDashboardStats(),
      ]);
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data dashboard: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchSiswaData() async {
    Query query = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa');

    if (selectedKelas.value != 'Semua Kelas') {
      query = query.where('kelasId', isGreaterThanOrEqualTo: selectedKelas.value)
                   .where('kelasId', isLessThan: '${selectedKelas.value}\uf8ff');
    }

    final snapshot = await query.get();

    semuaSiswaDiFilter.assignAll(snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {}; 
      return HalaqahDashboardStudentModel(
        uid: doc.id,
        nama: data['namaLengkap'] ?? 'Tanpa Nama',
        kelasId: data['kelasId'] ?? 'N/A',
        // [ADAPTASI] Menggunakan 'grupHalaqah' bukan 'halaqahUmmi'
        grupData: data['grupHalaqah'] as Map<String, dynamic>?,
      );
    }).toList());
    
    // Analisis data siswa setelah diambil
    _analyzeSiswaData();
  }
  
  // [PENAMBAHAN BARU] Mengambil statistik agregat
  Future<void> _fetchDashboardStats() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) return;

    // 1. Hitung total grup aktif
    final groupSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup').count().get();
    totalGrupAktif.value = groupSnapshot.count ?? 0;

    // 2. Hitung siswa dalam siklus ujian (sesuai blueprint Fase 4)
    final ujianSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_ujian')
        .where('status', whereIn: ['diajukan', 'dijadwalkan'])
        .count().get();
    siswaDalamSiklusUjian.value = ujianSnapshot.count ?? 0;
  }

  void _analyzeSiswaData() {
    // Analisis sederhana: cari siswa tanpa grup
    siswaTanpaGrup.assignAll(semuaSiswaDiFilter.where((s) => !s.hasGroup).toList());
  }

  void onKelasFilterChanged(String? newValue) {
    if (newValue != null) {
      selectedKelas.value = newValue;
      fetchDataForDashboard();
    }
  }

  Future<void> runDenormalizationScript() async {
    Get.defaultDialog(
      title: "Konfirmasi",
      middleText: "Anda akan menjalankan skrip untuk sinkronisasi data grup ke semua siswa. Proses ini akan meng-update data siswa yang sudah memiliki grup. Lanjutkan?",
      textConfirm: "Jalankan",
      onConfirm: () async {
        Get.back();
        isRunningScript.value = true;
        try {
          final tahunAjaran = configC.tahunAjaranAktif.value;
          // [FIX] Inisialisasi batch pertama kali
          WriteBatch batch = _firestore.batch();
          int counter = 0;
          int batchCounter = 0;
  
          final grupSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(tahunAjaran).collection('halaqah_grup').get();
          
          if (grupSnapshot.docs.isEmpty) {
            Get.snackbar("Info", "Tidak ada grup halaqah yang ditemukan untuk disinkronkan.");
            isRunningScript.value = false;
            return;
          }
  
          for (var grupDoc in grupSnapshot.docs) {
            final grupData = grupDoc.data();
            final anggotaSnapshot = await grupDoc.reference.collection('anggota').get();
  
            for (var anggotaDoc in anggotaSnapshot.docs) {
              final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
                                .collection('siswa').doc(anggotaDoc.id);
              
              batch.update(siswaRef, {
                'grupHalaqah': {
                  'idGrup': grupDoc.id,
                  'namaGrup': grupData['namaGrup'],
                  'idPengampu': grupData['idPengampu'],
                  'namaPengampu': grupData['namaPengampu'],
                }
              });
              counter++;
              batchCounter++;
  
              // Commit setiap 400 operasi untuk efisiensi
              if (batchCounter >= 400) {
                await batch.commit();
                // [FIX KUNCI DI SINI] Buat instance batch yang BARU
                batch = _firestore.batch();
                batchCounter = 0; // Reset counter batch
              }
            }
          }
          
          // Commit sisa operasi yang belum mencapai 400
          if (batchCounter > 0) {
            await batch.commit();
          }
  
          Get.snackbar("Berhasil", "$counter data siswa telah disinkronkan.");
        } catch (e) {
          Get.snackbar("Error Skrip", e.toString());
        } finally {
          isRunningScript.value = false;
        }
      }
    );
  }

  //========================PENTING BANGET RESET========================//
  final isDeletingHistory = false.obs;
  Future<void> runCleanHalaqahHistoryScript() async {
    Get.defaultDialog(
      title: "KONFIRMASI PENGHAPUSAN",
      titleStyle: TextStyle(color: Colors.red),
      middleText: "PERINGATAN: Anda akan menghapus SELURUH riwayat tugas dan penilaian halaqah untuk SEMUA siswa. Aksi ini tidak dapat dibatalkan. Lanjutkan?",
      textConfirm: "Ya, Hapus Semua",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        isDeletingHistory.value = true;
        try {
          final siswaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').get();
          int deletedCollections = 0;
  
          for (var siswaDoc in siswaSnapshot.docs) {
            final nilaiSnapshot = await siswaDoc.reference.collection('halaqah_nilai').limit(1).get();
            if (nilaiSnapshot.docs.isNotEmpty) {
              // Hapus sub-koleksi (memerlukan Cloud Function atau panggilan rekursif)
              // Cara sederhana di klien adalah menghapus dokumen satu per satu
              final allNilaiDocs = await siswaDoc.reference.collection('halaqah_nilai').get();
              WriteBatch batch = _firestore.batch();
              for (var nilaiDoc in allNilaiDocs.docs) {
                batch.delete(nilaiDoc.reference);
              }
              await batch.commit();
              deletedCollections++;
            }
          }
          Get.snackbar("Berhasil", "Membersihkan $deletedCollections riwayat halaqah siswa.");
        } catch (e) {
          Get.snackbar("Error Skrip Hapus", e.toString());
        } finally {
          isDeletingHistory.value = false;
        }
      }
    );
  }
}