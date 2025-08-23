// lib/app/modules/laporan_jurnal_pribadi/controllers/laporan_jurnal_pribadi_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/jurnal_laporan_item_model.dart';
import '../../../services/pdf_export_service.dart';

class LaporanJurnalPribadiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  final RxBool isLoading = false.obs;
  final RxList<JurnalLaporanItem> daftarLaporan = <JurnalLaporanItem>[].obs;
  
  // State untuk filter tanggal
  final Rx<DateTime> tanggalMulai = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> tanggalSelesai = DateTime.now().obs;

  void pickDate(BuildContext context, {required bool isMulai}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isMulai ? tanggalMulai.value : tanggalSelesai.value,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isMulai) {
        tanggalMulai.value = picked;
      } else {
        tanggalSelesai.value = picked;
      }
    }
  }

  Future<void> fetchLaporan() async {
    // Validasi rentang tanggal
    if (tanggalSelesai.value.difference(tanggalMulai.value).inDays > 31) {
      Get.snackbar("Peringatan", "Rentang waktu maksimal adalah 31 hari.", backgroundColor: Colors.orange);
      return;
    }
    if (tanggalMulai.value.isAfter(tanggalSelesai.value)) {
      Get.snackbar("Peringatan", "Tanggal mulai tidak boleh setelah tanggal selesai.", backgroundColor: Colors.orange);
      return;
    }

    isLoading.value = true;
    daftarLaporan.clear();
    try {
      final String uid = authC.auth.currentUser!.uid;
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('jurnal')
          .where('idGuru', isEqualTo: uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(tanggalMulai.value))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(tanggalSelesai.value.add(const Duration(days: 1)))) // Inklusif
          .orderBy('timestamp', descending: true)
          .get();

      final List<JurnalLaporanItem> result = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        result.add(JurnalLaporanItem(
          tanggal: (data['timestamp'] as Timestamp).toDate(),
          namaMapel: data['namaMapel'] ?? 'N/A',
          idKelas: data['idKelas'] ?? 'N/A',
          materi: data['materi'] ?? '',
          catatan: data['catatan'],
          isPengganti: data['isPengganti'] ?? false,
          jamKe: data['jamKe'] ?? 'N/A',
          namaGuru: data['namaGuru'] ?? 'N/A',
        ));
      }
      daftarLaporan.assignAll(result);

      if (result.isEmpty) {
        Get.snackbar("Informasi", "Tidak ada data jurnal yang ditemukan pada rentang tanggal tersebut.");
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil laporan: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportToPdf() async {
    if (daftarLaporan.isEmpty) {
      Get.snackbar("Peringatan", "Tidak ada data untuk diekspor.");
      return;
    }
    
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      final pdfService = PdfExportService();
      await pdfService.generateAndPreviewPdf(
        judulLaporan: "Laporan Jurnal Mengajar Pribadi",
        rentangTanggal: "${DateFormat('dd MMM yyyy', 'id_ID').format(tanggalMulai.value)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(tanggalSelesai.value)}",
        laporanData: daftarLaporan,
        isLaporanPimpinan: false, // Penting!
      );
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat PDF: $e");
    } finally {
      Get.back(); // Tutup dialog loading
    }
  }
}