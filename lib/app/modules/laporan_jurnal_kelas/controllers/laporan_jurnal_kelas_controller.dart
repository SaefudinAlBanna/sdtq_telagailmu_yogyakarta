// lib/app/modules/laporan_jurnal_kelas/controllers/laporan_jurnal_kelas_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/jurnal_laporan_item_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/kelas_simple_model.dart';

import '../../../services/pdf_export_service.dart';

class LaporanJurnalKelasController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final RxBool isLoading = false.obs;
  final RxBool isKelasLoading = true.obs;
  final RxList<JurnalLaporanItem> daftarLaporan = <JurnalLaporanItem>[].obs;
  
  // State untuk filter
  final Rx<DateTime> tanggalMulai = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> tanggalSelesai = DateTime.now().obs;
  final RxList<KelasSimpleModel> daftarKelas = <KelasSimpleModel>[].obs;
  final Rxn<KelasSimpleModel> kelasTerpilih = Rxn<KelasSimpleModel>();

  @override
  void onInit() {
    super.onInit();
    _fetchDaftarKelas();
  }

  Future<void> _fetchDaftarKelas() async {
    isKelasLoading.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaran).orderBy('namaKelas').get();
      
      daftarKelas.assignAll(snapshot.docs.map((doc) => 
        KelasSimpleModel(id: doc.id, nama: doc.data()['namaKelas'])
      ).toList());
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar kelas: $e");
    } finally {
      isKelasLoading.value = false;
    }
  }

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
    if (kelasTerpilih.value == null) {
      Get.snackbar("Peringatan", "Silakan pilih kelas terlebih dahulu.", backgroundColor: Colors.orange);
      return;
    }

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
       final String tahunAjaran = configC.tahunAjaranAktif.value;
       final String semester = configC.semesterAktif.value;
       final String idKelas = kelasTerpilih.value!.id;

           // [TAHAP 1: AMBIL DATA JURNAL]
       final jurnalSnapshot = await _firestore
           .collection('Sekolah').doc(configC.idSekolah)
           .collection('tahunajaran').doc(tahunAjaran)
           .collection('jurnal')
           .where('idKelas', isEqualTo: idKelas)
           .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(tanggalMulai.value))
           .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(tanggalSelesai.value.add(const Duration(days: 1))))
           .orderBy('timestamp', descending: false)
           .get();

           if (jurnalSnapshot.docs.isEmpty) {
         Get.snackbar("Informasi", "Tidak ada data jurnal yang ditemukan.");
         isLoading.value = false;
         return;
       }

           // [TAHAP 2: EKSTRAK TANGGAL & AMBIL DATA ABSENSI]
       final Set<String> tanggalUnik = jurnalSnapshot.docs.map((doc) => doc.data()['tanggal'] as String).toSet();
       final Map<String, String> petaAbsensi = {};
       for (String tanggalStr in tanggalUnik) {
         final absensiDoc = await _firestore
             .collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran)
             .collection('kelastahunajaran').doc(idKelas).collection('semester').doc(semester)
             .collection('absensi').doc(tanggalStr).get();

         if (absensiDoc.exists && absensiDoc.data() != null) {
           final rekap = absensiDoc.data()!['rekap'] as Map<String, dynamic>?;
           if (rekap != null) {
             // --- [PERBAIKAN KUNCI DI SINI] Sesuaikan key dengan data di Firestore (lowercase) ---
             petaAbsensi[tanggalStr] = "H: ${rekap['hadir'] ?? 0}, S: ${rekap['sakit'] ?? 0}, I: ${rekap['izin'] ?? 0}, A: ${rekap['alfa'] ?? 0}";
           }
         }
       }

           // [TAHAP 3: GABUNGKAN DATA & BUAT MODEL]
       final List<JurnalLaporanItem> result = [];
       for (var doc in jurnalSnapshot.docs) {
         final data = doc.data();
         final tanggalDoc = data['tanggal'] as String;

         result.add(JurnalLaporanItem(
           tanggal: (data['timestamp'] as Timestamp).toDate(),
           namaMapel: data['namaMapel'] ?? 'N/A',
           idKelas: data['idKelas'] ?? 'N/A',
           materi: data['materi'] ?? '',
           catatan: data['catatan'],
           isPengganti: data['isPengganti'] ?? false,
           jamKe: data['jamKe'] ?? 'N/A',
           namaGuru: data['namaGuru'] ?? 'N/A',
           rekapAbsensi: petaAbsensi[tanggalDoc],
         ));
       }
       daftarLaporan.assignAll(result);

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
        judulLaporan: "Laporan Jurnal Mengajar Kelas ${kelasTerpilih.value!.nama}",
        rentangTanggal: "${DateFormat('dd MMM yyyy', 'id_ID').format(tanggalMulai.value)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(tanggalSelesai.value)}",
        laporanData: daftarLaporan,
        isLaporanPimpinan: true, // Penting!
      );
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat PDF: $e");
    } finally {
      Get.back(); // Tutup dialog loading
    }
  }
}