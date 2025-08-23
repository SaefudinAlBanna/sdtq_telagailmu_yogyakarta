// lib/app/modules/ekskul_pendaftaran_management/controllers/ekskul_pendaftaran_management_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/ekskul_model.dart';

class EkskulPendaftaranManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final Rxn<DocumentSnapshot> pendaftaranAktif = Rxn<DocumentSnapshot>();
  final RxList<EkskulModel> daftarEkskulDitawarkan = <EkskulModel>[].obs;

  final judulC = TextEditingController();
  final Rxn<DateTime> tanggalBuka = Rxn<DateTime>();
  final Rxn<DateTime> tanggalTutup = Rxn<DateTime>();

  late CollectionReference pendaftaranRef;

  @override
  void onInit() {
    super.onInit();
    final tahunAjaran = configC.tahunAjaranAktif.value;
    pendaftaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran).collection('ekskul_pendaftaran');
    
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      final snapshot = await pendaftaranRef.where('status', isEqualTo: 'Dibuka').limit(1).get();
      
      if (snapshot.docs.isNotEmpty) {
        pendaftaranAktif.value = snapshot.docs.first;
        await _fetchEkskulDitawarkan();
      } else {
        pendaftaranAktif.value = null;
      }
    } catch (e) { Get.snackbar("Error", "Gagal memuat data pendaftaran: $e"); } 
    finally { isLoading.value = false; }
  }

  Future<void> _fetchEkskulDitawarkan() async {
    final ekskulSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('ekskul_ditawarkan')
        .where('tahunAjaran', isEqualTo: configC.tahunAjaranAktif.value)
        .where('semester', isEqualTo: configC.semesterAktif.value)
        .get();
    daftarEkskulDitawarkan.assignAll(ekskulSnap.docs.map((d) => EkskulModel.fromFirestore(d)).toList());
  }

  void pickDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (range != null) {
      tanggalBuka.value = range.start;
      tanggalTutup.value = range.end;
    }
  }

  Future<void> bukaPendaftaran() async {
    if (judulC.text.trim().isEmpty || tanggalBuka.value == null || tanggalTutup.value == null) {
      Get.snackbar("Peringatan", "Semua field wajib diisi."); return;
    }
    isSaving.value = true;
    try {
      await pendaftaranRef.add({
        'judul': judulC.text.trim(),
        'tanggalBuka': Timestamp.fromDate(tanggalBuka.value!),
        'tanggalTutup': Timestamp.fromDate(tanggalTutup.value!),
        'status': 'Dibuka',
        'ekskulDipilih': {},
        'tahunAjaran': configC.tahunAjaranAktif.value,
        'semester': configC.semesterAktif.value,
      });
      Get.snackbar("Berhasil", "Periode pendaftaran telah dibuka.", backgroundColor: Colors.green, colorText: Colors.white);
      loadInitialData();
    } catch (e) { Get.snackbar("Error", "Gagal membuka pendaftaran: $e"); } 
    finally { isSaving.value = false; }
  }

  Future<void> tutupPendaftaran() async {
    if (pendaftaranAktif.value == null) return;
    
    Get.defaultDialog(
      title: "Konfirmasi",
      middleText: "Apakah Anda yakin ingin menutup periode pendaftaran ini? Setelah ditutup, orang tua tidak bisa lagi memilih ekskul.",
      textConfirm: "Ya, Tutup Pendaftaran",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        isSaving.value = true;
        try {
          await pendaftaranAktif.value!.reference.update({'status': 'Ditutup'});
          Get.snackbar("Berhasil", "Periode pendaftaran telah ditutup.");
          loadInitialData();
        } catch (e) { Get.snackbar("Error", "Gagal menutup pendaftaran: $e"); } 
        finally { isSaving.value = false; }
      },
    );
  }
}