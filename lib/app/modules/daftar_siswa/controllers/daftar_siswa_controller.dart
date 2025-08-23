// lib/app/modules/daftar_siswa/controllers/daftar_siswa_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';

class DaftarSiswaController extends GetxController {
  // --- DEPENDENSI ---
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- STATE ---
  final isLoading = true.obs;
  final RxList<SiswaModel> _semuaSiswa = <SiswaModel>[].obs;
  final RxList<SiswaModel> daftarSiswaFiltered = <SiswaModel>[].obs;
  
  final TextEditingController searchC = TextEditingController();
  final searchQuery = "".obs;
  late TextEditingController passAdminC;

  // --- PERBAIKAN DI SINI ---
  // Getter Hak Akses disamakan dengan logika di PegawaiController yang sudah benar.
  bool get canManageSiswa {
    final role = configC.infoUser['role'];
    // Peran yang diizinkan untuk mengelola data siswa
    const allowedRoles = ['Admin', 'TU', 'Tata Usaha', 'Kepala Sekolah']; 
    // SuperAdmin (via peranSistem) ATAU peran yang diizinkan akan mengembalikan true.
    return configC.infoUser['peranSistem'] == 'superadmin' || allowedRoles.contains(role);
  }

  @override
  void onInit() {
    super.onInit();
    passAdminC = TextEditingController();
    fetchSiswa();
    ever(searchQuery, (_) => _filterData());
  }

  @override
  void onClose() {
    searchC.dispose();
    passAdminC.dispose();
    super.onClose();
  }

  Future<void> fetchSiswa() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('Sekolah')
          .doc(configC.idSekolah)
          .collection('siswa')
          .orderBy('namaLengkap')
          .get();
      
      _semuaSiswa.assignAll(snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
      daftarSiswaFiltered.assignAll(_semuaSiswa);
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil data siswa: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void _filterData() {
    String query = searchQuery.value.toLowerCase();
    if (query.isEmpty) {
      daftarSiswaFiltered.assignAll(_semuaSiswa);
    } else {
      daftarSiswaFiltered.assignAll(_semuaSiswa.where((siswa) {
        return siswa.namaLengkap.toLowerCase().contains(query) || siswa.nisn.contains(query);
      }).toList());
    }
  }

  // --- Navigasi ---
  void goToImportSiswa() => Get.toNamed(Routes.IMPORT_SISWA);
  
  void goToTambahSiswa() async {
    final result = await Get.toNamed(Routes.UPSERT_SISWA);
    if (result == true) fetchSiswa();
  }

  void goToEditSiswa(SiswaModel siswa) async {
    final result = await Get.toNamed(Routes.UPSERT_SISWA, arguments: siswa);
    if (result == true) fetchSiswa();
  }
}