// lib/app/modules/manajemen_tingkatan_siswa/controllers/manajemen_tingkatan_siswa_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_with_tingkatan_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/utils/halaqah_utils.dart';

class ManajemenTingkatanSiswaController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isModeMassal = false.obs; // Default ke mode 'Per Siswa'

  final RxList<SiswaWithTingkatanModel> semuaSiswa = <SiswaWithTingkatanModel>[].obs;
  final searchC = TextEditingController();
  final searchQuery = "".obs;

  // State untuk Mode Massal
  final Rxn<String> tingkatanTerpilihMassal = Rxn<String>();
  final RxSet<String> siswaTerpilihMassalUids = <String>{}.obs;

  List<SiswaWithTingkatanModel> get filteredSiswa {
    if (searchQuery.value.isEmpty) return semuaSiswa;
    final query = searchQuery.value.toLowerCase();
    return semuaSiswa.where((s) => s.nama.toLowerCase().contains(query)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    searchC.addListener(() => searchQuery.value = searchC.text);
    _fetchSiswa();
  }

  Future<void> _fetchSiswa() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').orderBy('namaLengkap').get();
      
      semuaSiswa.assignAll(snapshot.docs.map((doc) {
        final data = doc.data();
        return SiswaWithTingkatanModel(
          uid: doc.id,
          nama: data['namaLengkap'] ?? 'Tanpa Nama',
          tingkatanSaatIni: data['halaqahTingkatan'] as Map<String, dynamic>?,
        );
      }).toList());
    } catch (e) { Get.snackbar("Error", "Gagal memuat data siswa: ${e.toString()}");
    } finally { isLoading.value = false; }
  }

  void toggleMode() => isModeMassal.value = !isModeMassal.value;

  Future<void> updateTingkatanSatuSiswa(String uid, String namaTingkatan) async {
    isSaving.value = true;
    try {
      final dataToSave = {
        'nama': namaTingkatan,
        'warna': HalaqahUtils.getWarnaTingkatan(namaTingkatan).value.toRadixString(16),
      };
      await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(uid)
          .update({'halaqahTingkatan': dataToSave});
      
      // Update data di UI secara lokal
      final index = semuaSiswa.indexWhere((s) => s.uid == uid);
      if (index != -1) {
        semuaSiswa[index] = SiswaWithTingkatanModel(uid: uid, nama: semuaSiswa[index].nama, tingkatanSaatIni: dataToSave);
      }
      Get.snackbar("Berhasil", "Tingkatan telah diperbarui.");
    } catch (e) { Get.snackbar("Error", "Gagal menyimpan: ${e.toString()}");
    } finally { isSaving.value = false; }
  }

  // --- Logika untuk Mode Massal ---
  void toggleSiswaSelection(String uid, bool isSelected) {
    if (isSelected) siswaTerpilihMassalUids.add(uid);
    else siswaTerpilihMassalUids.remove(uid);
  }

  void selectAll(bool isSelected) {
    if (isSelected) {
      siswaTerpilihMassalUids.addAll(filteredSiswa.map((s) => s.uid));
    } else {
      siswaTerpilihMassalUids.clear();
    }
  }

  Future<void> saveTingkatanMassal() async {
    if (tingkatanTerpilihMassal.value == null) {
      Get.snackbar("Peringatan", "Silakan pilih tingkatan target terlebih dahulu."); return;
    }
    if (siswaTerpilihMassalUids.isEmpty) {
      Get.snackbar("Peringatan", "Tidak ada siswa yang dipilih."); return;
    }
    isSaving.value = true;
    try {
      WriteBatch batch = _firestore.batch();
      int counter = 0;
      final dataToSave = {
        'nama': tingkatanTerpilihMassal.value!,
        'warna': HalaqahUtils.getWarnaTingkatan(tingkatanTerpilihMassal.value!).value.toRadixString(16),
      };

      for (String uid in siswaTerpilihMassalUids) {
        final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(uid);
        batch.update(siswaRef, {'halaqahTingkatan': dataToSave});
        counter++;
        if (counter >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          counter = 0;
        }
      }
      if (counter > 0) await batch.commit();

      Get.back();
      Get.snackbar("Berhasil", "${siswaTerpilihMassalUids.length} data tingkatan siswa telah disimpan.");
      _fetchSiswa(); // Muat ulang data
    } catch (e) { Get.snackbar("Error", "Gagal menyimpan massal: ${e.toString()}");
    } finally { isSaving.value = false; }
  }

  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }
}