// lib/app/modules/editor_jadwal/controllers/editor_jadwal_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';

class EditorJadwalController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  late Worker _statusWorker;

  late Worker _tahunAjaranWorker;

  final isLoading = true.obs;
  final isLoadingJadwal = false.obs;
  final isSaving = false.obs;

  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarJam = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarMapelTersedia = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarGuruTersedia = <Map<String, dynamic>>[].obs;

  final Rxn<String> selectedKelasId = Rxn<String>();
  final RxString selectedHari = 'Senin'.obs;
  final RxMap<String, RxList<Map<String, dynamic>>> jadwalPelajaran = <String, RxList<Map<String, dynamic>>>{}.obs;
  final List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  
  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

   @override
  void onInit() {
    super.onInit();
    for (var hari in daftarHari) { jadwalPelajaran[hari] = <Map<String, dynamic>>[].obs; }

    // Worker ini akan "mengawasi" status di ConfigController.
    _statusWorker = ever(configC.status, (appStatus) {
      if (appStatus == AppStatus.authenticated && isLoading.value) {
        _initializeData();
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    if (configC.status.value == AppStatus.authenticated && isLoading.value) {
      _initializeData();
    }
  }

  @override
  void onClose() {
    _statusWorker.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    await _fetchDaftarKelas();
    isLoading.value = false;
  }

  Future<void> _fetchDaftarKelas() async {
    if (tahunAjaranAktif.isEmpty || tahunAjaranAktif.contains("TIDAK DITEMUKAN")) {
      Get.snackbar("Kesalahan Konfigurasi", "Tahun ajaran aktif tidak ditemukan.");
      daftarKelas.clear();
      return;
    }
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaranAktif).orderBy('namaKelas').get();
    daftarKelas.value = snapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.data()['namaKelas'] ?? doc.id}).toList();
  }

  // Sisa controller tidak ada perubahan...
  Future<void> onKelasChanged(String? kelasId) async {
    if (kelasId == null) return;
    selectedKelasId.value = kelasId;
    _clearJadwal();
    isLoadingJadwal.value = true;
    await Future.wait([ _fetchJadwal(), _fetchDaftarJam(), _fetchGuruDanMapel() ]);
    isLoadingJadwal.value = false;
  }
  
  Future<void> _fetchJadwal() async {
    if (selectedKelasId.value == null) return;
    try {
      final docSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('jadwalkelas').doc(selectedKelasId.value!).get();
      _clearJadwal();
      if (docSnap.exists && docSnap.data() != null) {
        final dataJadwal = docSnap.data() as Map<String, dynamic>;
        dataJadwal.forEach((hari, listData) {
          if (jadwalPelajaran.containsKey(hari) && listData is List) {
            jadwalPelajaran[hari]!.value = List<Map<String, dynamic>>.from(listData);
          }
        });
      }
    } catch (e) { Get.snackbar('Error', 'Gagal memuat jadwal: ${e.toString()}'); }
  }

  Future<void> _fetchDaftarJam() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('jampelajaran').orderBy('urutan').get();
    daftarJam.value = snapshot.docs.map((doc) => {
      'id': doc.id, 'label': "${doc.data()['namaKegiatan']} (${doc.data()['jampelajaran']})", 'waktu': doc.data()['jampelajaran'],
    }).toList();
  }

  Future<void> _fetchGuruDanMapel() async {
    if (selectedKelasId.value == null) return;
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran')
                            .doc(tahunAjaranAktif).collection('penugasan').doc(selectedKelasId.value!)
                            .collection('matapelajaran').get();

      daftarMapelTersedia.clear();
      daftarGuruTersedia.clear();
      final Set<String> uniqueMapelIds = {};

      for(var doc in snapshot.docs) {
        final data = doc.data();
        daftarGuruTersedia.add({'uid': data['idGuru'], 'nama': data['guru'], 'idMapel': data['idMapel']});
        if (uniqueMapelIds.add(data['idMapel'])) {
          daftarMapelTersedia.add({'idMapel': data['idMapel'], 'nama': data['namamatapelajaran']});
        }
      }
    } catch(e) { Get.snackbar("Error", "Gagal memuat data guru & mapel: $e"); } 
  }

  void _clearJadwal() { 
    for (var hari in daftarHari) { 
      jadwalPelajaran[hari]?.clear(); 
    } 
  }
  
  void tambahPelajaran() {
    jadwalPelajaran[selectedHari.value]?.add({
      'jam': null, 'idMapel': null, 'namaMapel': null, 'idGuru': null, 'namaGuru': null,
    });
  }

  void hapusPelajaran(int index) {
    jadwalPelajaran[selectedHari.value]?.removeAt(index);
  }

  void updatePelajaran(int index, String key, dynamic value) {
    final pelajaran = jadwalPelajaran[selectedHari.value]![index];
    if (key == 'idMapel') {
      final mapel = daftarMapelTersedia.firstWhere((m) => m['idMapel'] == value, orElse: () => {});
      pelajaran['idMapel'] = value;
      pelajaran['namaMapel'] = mapel['nama'];
      pelajaran['idGuru'] = null; // Reset guru
      pelajaran['namaGuru'] = null;
    } else if (key == 'idGuru') {
      final guru = daftarGuruTersedia.firstWhere((g) => g['uid'] == value, orElse: () => {});
      pelajaran['idGuru'] = value;
      pelajaran['namaGuru'] = guru['nama'];
    } else {
      pelajaran[key] = value;
    }
    jadwalPelajaran[selectedHari.value]!.refresh();
  }

  Future<void> simpanJadwal() async {
    if (selectedKelasId.value == null) return;
    isSaving.value = true;
    
    final String? errorMessage = await _validateGuruClash();
    if (errorMessage != null) {
      Get.snackbar('Jadwal Bentrok!', errorMessage, backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5));
      isSaving.value = false;
      return;
    }

    try {
      Map<String, List<Map<String, dynamic>>> dataToSave = {};
      jadwalPelajaran.forEach((hari, list) { dataToSave[hari] = list.toList(); });
      
      await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('jadwalkelas').doc(selectedKelasId.value!).set(dataToSave);
      Get.snackbar('Berhasil', 'Jadwal pelajaran berhasil disimpan.');
    } catch (e) { Get.snackbar('Error', 'Gagal menyimpan jadwal: ${e.toString()}'); } 
    finally { isSaving.value = false; }
  }

  Future<String?> _validateGuruClash() async {
    final otherSchedulesSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaranAktif).collection('jadwalkelas').where(FieldPath.documentId, isNotEqualTo: selectedKelasId.value!).get();
    final Map<String, String> guruBookings = {};

    for (var doc in otherSchedulesSnapshot.docs) {
      final idKelasLain = doc.id;
      doc.data().forEach((hari, listPelajaran) {
        if (listPelajaran is List) {
          for (var pelajaran in listPelajaran) {
            final jam = pelajaran['jam'] as String?;
            final idGuru = pelajaran['idGuru'] as String?;
            if (jam != null && idGuru != null) {
              guruBookings['$idGuru-$hari-$jam'] = daftarKelas.firstWhere((k) => k['id'] == idKelasLain, orElse: () => {'nama': '?'})['nama'];
            }
          }
        }
      });
    }

    for (var hari in jadwalPelajaran.keys) {
      for (var slot in jadwalPelajaran[hari]!) {
        final jam = slot['jam'] as String?;
        final idGuru = slot['idGuru'] as String?;
        if (jam == null || idGuru == null) continue;

        final key = '$idGuru-$hari-$jam';
        if (guruBookings.containsKey(key)) {
          final namaGuru = daftarGuruTersedia.firstWhere((g) => g['uid'] == idGuru, orElse: () => {'nama': '?'})['nama'];
          return "Bentrok: $namaGuru sudah terjadwal di Kelas ${guruBookings[key]} pada hari $hari, jam $jam.";
        }
      }
    }
    return null;
  }
}