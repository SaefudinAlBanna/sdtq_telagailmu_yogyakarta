// lib/app/modules/pemberian_kelas_siswa/controllers/pemberian_kelas_siswa_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_model.dart';

class PemberianKelasSiswaController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Worker _statusWorker;

  final isLoading = true.obs;
  final isProcessing = false.obs;
  final isWaliKelasLoading = false.obs;

  final RxList<DocumentSnapshot> daftarKelas = <DocumentSnapshot>[].obs;
  final Rxn<DocumentSnapshot> kelasTerpilih = Rxn<DocumentSnapshot>();

  final RxList<SiswaModel> siswaDiKelas = <SiswaModel>[].obs;
  final RxList<SiswaModel> siswaTanpaKelas = <SiswaModel>[].obs;
  
  final RxList<PegawaiModel> daftarGuru = <PegawaiModel>[].obs;
  final RxString searchQueryGuru = "".obs;
  final RxSet<String> assignedWaliKelasUids = <String>{}.obs;

  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;
  String get semesterAktif => configC.semesterAktif.value;
  
  @override
  void onInit() {
    super.onInit();
    _statusWorker = ever(configC.status, (appStatus) {
      if (appStatus == AppStatus.authenticated && isLoading.value) {
        _initializeData();
      }
    });
    if (configC.status.value == AppStatus.authenticated) {
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
    await Future.wait([
      fetchKelas(),
      fetchSiswaTanpaKelas(),
      fetchDaftarGuru(),
    ]);
    isLoading.value = false;
  }

  Future<void> fetchKelas() async {
    if (tahunAjaranAktif.isEmpty || tahunAjaranAktif.contains("TIDAK")) return;
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaranAktif).get();
    daftarKelas.assignAll(snapshot.docs);
    
    final uids = snapshot.docs.map((doc) => (doc.data() as Map<String, dynamic>)['waliKelasUid'] as String?)
        .where((uid) => uid != null && uid.isNotEmpty).cast<String>().toSet();
    assignedWaliKelasUids.assignAll(uids);
  }

  Future<void> fetchSiswaTanpaKelas() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').where('kelasId', isNull: true).get();
    siswaTanpaKelas.assignAll(snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
  }

  Future<void> fetchDaftarGuru() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('pegawai').where('role', isEqualTo: 'Guru Kelas').get();
    daftarGuru.assignAll(snapshot.docs.map((doc) => PegawaiModel.fromFirestore(doc)).toList());
  }

  Future<void> pilihKelas(DocumentSnapshot kelasDoc) async {
    kelasTerpilih.value = kelasDoc;
    siswaDiKelas.clear();
    final dataKelas = kelasDoc.data() as Map<String, dynamic>;
    final List<String> siswaUids = List<String>.from(dataKelas['siswaUids'] ?? []);
    if (siswaUids.isNotEmpty) {
      final siswaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').where(FieldPath.documentId, whereIn: siswaUids).get();
      siswaDiKelas.assignAll(siswaSnapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
    }
  }

  // --- FUNGSI DIPERBAIKI DENGAN DENORMALISASI ---
  Future<void> addSiswaToKelas(SiswaModel siswa) async {
    if (kelasTerpilih.value == null) return;
    isProcessing.value = true;
    
    final kelasDoc = kelasTerpilih.value!;
    final kelasRef = kelasDoc.reference;
    final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
    
    final kelasTahunAjaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaranAktif)
      .collection('kelastahunajaran').doc(kelasRef.id);
      
    final semesterSiswaRef = kelasTahunAjaranRef.collection('semester').doc(semesterAktif).collection('daftarsiswa').doc(siswa.uid);

    WriteBatch batch = _firestore.batch();
    
    batch.update(kelasRef, {'siswaUids': FieldValue.arrayUnion([siswa.uid])});
    batch.update(siswaRef, {'kelasId': kelasRef.id, 'statusSiswa': 'Aktif'});
    batch.set(semesterSiswaRef, {'uid': siswa.uid, 'nisn': siswa.nisn, 'namasiswa': siswa.namaLengkap});
    
    await batch.commit();
    
    siswaTanpaKelas.removeWhere((s) => s.uid == siswa.uid);
    siswaDiKelas.add(siswa);
    isProcessing.value = false;
  }

  // --- FUNGSI DIPERBAIKI DENGAN DENORMALISASI ---
  Future<void> removeSiswaFromKelas(SiswaModel siswa) async {
    if (kelasTerpilih.value == null) return;
    isProcessing.value = true;

    final kelasRef = kelasTerpilih.value!.reference;
    final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
    final semesterSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaranAktif).collection('kelastahunajaran')
      .doc(kelasRef.id).collection('semester').doc(semesterAktif).collection('daftarsiswa').doc(siswa.uid);

    WriteBatch batch = _firestore.batch();
    
    batch.update(kelasRef, {'siswaUids': FieldValue.arrayRemove([siswa.uid])});
    batch.update(siswaRef, {'kelasId': FieldValue.delete(), 'statusSiswa': 'Tidak Aktif'});
    batch.delete(semesterSiswaRef);

    await batch.commit();
    
    siswaDiKelas.removeWhere((s) => s.uid == siswa.uid);
    siswaTanpaKelas.add(siswa);
    isProcessing.value = false;
  }

  // --- FUNGSI LAINNYA TIDAK BERUBAH ---
  void showBuatKelasDialog() {
    final TextEditingController namaKelasC = TextEditingController();
    Get.defaultDialog(
      title: "Buat Kelas Baru",
      content: TextField(controller: namaKelasC, autofocus: true, decoration: const InputDecoration(labelText: "Nama Kelas (contoh: 1A)")),
      actions: [ OutlinedButton(onPressed: () => Get.back(), child: const Text("Batal")), ElevatedButton(onPressed: () { Get.back(); _buatKelas(namaKelasC.text.trim().toUpperCase()); }, child: const Text("Buat"))]);
  }

  Future<void> _buatKelas(String namaKelas) async {
    if (namaKelas.isEmpty) return;
    final kelasId = "$namaKelas-$tahunAjaranAktif";
    final fase = _getFaseFromNamaKelas(namaKelas);
    await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').doc(kelasId).set({
      'namaKelas': namaKelas, 'tahunAjaran': tahunAjaranAktif, 'fase': fase, 'waliKelasUid': null, 'waliKelasNama': null, 'siswaUids': [],
    });
    fetchKelas();
  }

  String _getFaseFromNamaKelas(String namaKelas) {
    if (namaKelas.startsWith('1') || namaKelas.startsWith('2')) return "Fase A";
    if (namaKelas.startsWith('3') || namaKelas.startsWith('4')) return "Fase B";
    if (namaKelas.startsWith('5') || namaKelas.startsWith('6')) return "Fase C";
    return "Fase Tidak Diketahui";
  }

  Future<void> assignWaliKelas(PegawaiModel guru) async {
    if (kelasTerpilih.value == null) return;
    isWaliKelasLoading.value = true;
    
    final kelasDoc = kelasTerpilih.value!;
    final kelasRef = kelasDoc.reference;
    final guruBaruRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(guru.uid);
    final String? guruLamaUid = (kelasDoc.data() as Map<String, dynamic>)['waliKelasUid'];
  
    WriteBatch batch = _firestore.batch();
    
    // Hapus status wali kelas dari guru yang lama (jika ada)
    if (guruLamaUid != null && guruLamaUid.isNotEmpty) {
      final guruLamaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(guruLamaUid);
      batch.update(guruLamaRef, {'waliKelasDari': FieldValue.delete()});
    }
  
    // Tetapkan status wali kelas ke guru yang baru
    batch.update(guruBaruRef, {'waliKelasDari': kelasRef.id});
  
    // Perbarui dokumen di koleksi /kelas
    final namaUntukDitampilkan = guru.alias ?? guru.nama;
    batch.update(kelasRef, {'waliKelasUid': guru.uid, 'waliKelasNama': namaUntukDitampilkan});
    
    // --- [LOGIKA BARU & PENTING] ---
    // Buat atau perbarui dokumen di /kelastahunajaran untuk sinkronisasi
    final kelasTahunAjaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaranAktif)
      .collection('kelastahunajaran').doc(kelasRef.id);
      
    batch.set(kelasTahunAjaranRef, {
      'idWaliKelas': guru.uid,
      'namaWaliKelas': namaUntukDitampilkan,
      'namaKelas': (kelasDoc.data() as Map<String, dynamic>)['namaKelas'],
    }, SetOptions(merge: true)); // Gunakan merge agar tidak menimpa data siswa
  
    await batch.commit();
  
    // Muat ulang data untuk me-refresh UI
    await fetchKelas();
    kelasTerpilih.value = await kelasRef.get();
    isWaliKelasLoading.value = false;
    Get.back(); // Tutup dialog
  }
}
