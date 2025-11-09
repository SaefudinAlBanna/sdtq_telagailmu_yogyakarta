// lib/app/modules/manajemen_penguji/controllers/manajemen_penguji_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_simple_model.dart';

class ManajemenPengujiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // State UI
  final isLoading = true.obs;
  final isSaving = false.obs;

  // State untuk Pencarian
  final searchC = TextEditingController();
  final searchQuery = "".obs;

  // State Data
  final RxList<PegawaiSimpleModel> semuaPegawai = <PegawaiSimpleModel>[].obs;
  final RxSet<String> pengujiTerpilihUids = <String>{}.obs;

  List<PegawaiSimpleModel> get filteredPegawai {
    if (searchQuery.value.isEmpty) {
      return semuaPegawai; // Tampilkan semua jika tidak ada query
    }
    final query = searchQuery.value.toLowerCase();
    return semuaPegawai.where((pegawai) {
      final nama = pegawai.nama.toLowerCase();
      final alias = pegawai.alias.toLowerCase();
      return nama.contains(query) || alias.contains(query);
    }).toList();
  }


  @override
  void onInit() {
    super.onInit();
    searchC.addListener(() {
      searchQuery.value = searchC.text;
    });
    _fetchData();
  }

  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }

  Future<void> _fetchData() async {
    isLoading.value = true;
    try {
      // 1. Ambil semua data pegawai
      final pegawaiSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('pegawai').orderBy('nama').get();
      semuaPegawai.assignAll(pegawaiSnapshot.docs.map((doc) => PegawaiSimpleModel.fromFirestore(doc)).toList());
      
      // 2. Ambil data penguji yang sudah ada
      final configDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('halaqah_config').get();

      if (configDoc.exists && configDoc.data() != null) {
        final data = configDoc.data()!;
        final Map<String, dynamic> daftarPengujiMap = data['daftarPenguji'] ?? {};
        pengujiTerpilihUids.assignAll(daftarPengujiMap.keys);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi untuk menambah/menghapus UID dari set saat checkbox ditekan
  void togglePenguji(String uid, bool isSelected) {
    if (isSelected) {
      pengujiTerpilihUids.add(uid);
    } else {
      pengujiTerpilihUids.remove(uid);
    }
  }

  Future<void> saveChanges() async {
    isSaving.value = true;
    try {
      final Map<String, String> dataToSave = {};
  
      for (String uid in pengujiTerpilihUids) {
        final pegawai = semuaPegawai.firstWhere((p) => p.uid == uid);
        
        // [REVISI KUNCI DI SINI]
        // Gunakan alias jika ada dan tidak kosong, jika tidak, gunakan nama.
        final namaTampilan = (pegawai.alias.isNotEmpty) ? pegawai.alias : pegawai.nama;
        dataToSave[uid] = namaTampilan;
      }
      
      await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('halaqah_config')
          .set({
            'daftarPenguji': dataToSave
          }, SetOptions(merge: true));
      
      Get.back();
      Get.snackbar("Berhasil", "Daftar penguji telah diperbarui.");
  
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan perubahan: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }
}