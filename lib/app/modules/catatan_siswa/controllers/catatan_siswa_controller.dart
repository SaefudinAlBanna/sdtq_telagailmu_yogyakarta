// lib/app/modules/catatan_siswa/controllers/catatan_siswa_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CatatanSiswaController extends GetxController {
  // --- Firebase & User Info ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final String currentUserId;
  final String idSekolah = "P9984539";
  String? idTahunAjaran;

  // --- State untuk Peran & UI ---
  final RxBool isLoading = true.obs;
  final RxString userRole = ''.obs;
  final RxBool isWaliKelas = false.obs;

  // --- State untuk Data ---
  final RxString selectedKelasId = ''.obs;
  final RxString selectedSiswaId = ''.obs;
  final RxList<Map<String, String>> daftarKelas = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> daftarSiswa = <Map<String, String>>[].obs;
  
  // --- Text Controllers ---
  final TextEditingController judulC = TextEditingController();
  final TextEditingController catatanC = TextEditingController();
  final TextEditingController tindakanC = TextEditingController();
  final TextEditingController tanggapanC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    currentUserId = auth.currentUser!.uid;
    _initializeUserAndData();
  }
  
  Future<void> _initializeUserAndData() async {
    isLoading.value = true;
    try {
      idTahunAjaran = await _getTahunAjaranTerakhir();
      if (idTahunAjaran == null) throw Exception("Tahun ajaran tidak ditemukan.");
      final pegawaiDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(currentUserId).get();
      if (!pegawaiDoc.exists) throw Exception("Profil pegawai tidak ditemukan.");
      userRole.value = pegawaiDoc.data()?['role'] ?? 'Peran Tidak Diketahui';
      isWaliKelas.value = userRole.value == 'Wali Kelas';
      if (isWaliKelas.value) {
        await _fetchDataForWaliKelas();
      } else if (userRole.value == 'Guru BK' || userRole.value == 'Kepala Sekolah') {
        await _fetchDataForMonitoring();
      }
    } catch (e) {
      Get.snackbar("Error Inisialisasi", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchDataForWaliKelas() async {
    final query = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran!)
        .collection('kelastahunajaran')
        .where('idwalikelas', isEqualTo: currentUserId)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final kelasDoc = query.docs.first;
      daftarKelas.assign( {'id': kelasDoc.id, 'nama': kelasDoc.id} );
      selectedKelasId.value = kelasDoc.id;
      await onKelasChanged(kelasDoc.id, isWaliKelas: true);
    }
  }

  Future<void> _fetchDataForMonitoring() async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!).collection('kelastahunajaran').get();
    final kelas = snapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.id}).toList();
    daftarKelas.assignAll(kelas);
  }

  Future<String?> _getTahunAjaranTerakhir() async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').orderBy('namatahunajaran', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data()['namatahunajaran']?.replaceAll("/", "-");
  }

  Future<void> onKelasChanged(String? kelasId, {bool isWaliKelas = false}) async {
    if (kelasId == null || kelasId.isEmpty) return;
    selectedKelasId.value = kelasId;
    selectedSiswaId.value = '';
    daftarSiswa.clear();
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!).collection('kelastahunajaran').doc(kelasId).collection('daftarsiswa').get();
    final siswa = snapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.data()['namasiswa'] as String}).toList();
    daftarSiswa.assignAll(siswa);
  }

  void onSiswaChanged(String? siswaId) {
    if (siswaId == null || siswaId.isEmpty) return;
    selectedSiswaId.value = siswaId;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCatatanSiswa() {
    if (selectedSiswaId.value.isEmpty || idTahunAjaran == null) {
      return const Stream.empty();
    }
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('siswa').doc(selectedSiswaId.value)
        .collection('tahunajaran').doc(idTahunAjaran!)
        .collection('catatansiswa').orderBy('tanggalinput', descending: true)
        .snapshots();
  }

  void openAddCatatanDialog() {
    if (!isWaliKelas.value) {
      Get.snackbar("Akses Ditolak", "Hanya Wali Kelas yang dapat membuat catatan.");
      return;
    }
    if (selectedSiswaId.value.isEmpty) {
      Get.snackbar("Peringatan", "Silakan pilih siswa terlebih dahulu.");
      return;
    }
    _clearForm();
    Get.dialog(
      AlertDialog(
        title: const Text("Buat Catatan Baru"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: judulC, decoration: const InputDecoration(labelText: 'Judul Catatan', border: OutlineInputBorder()), textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 12),
            TextField(controller: catatanC, decoration: const InputDecoration(labelText: 'Isi Catatan', border: OutlineInputBorder()), maxLines: 4, textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 12),
            TextField(controller: tindakanC, decoration: const InputDecoration(labelText: 'Tindakan Awal Wali Kelas', border: OutlineInputBorder()), textCapitalization: TextCapitalization.sentences),
          ]),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Batal")),
          ElevatedButton(onPressed: _simpanCatatan, child: const Text("Simpan")),
        ],
      ),
    );
  }

  Future<void> _simpanCatatan() async {
    if (judulC.text.isEmpty || catatanC.text.isEmpty || tindakanC.text.isEmpty) {
      Get.snackbar("Error", "Semua field harus diisi.");
      return;
    }
    try {
      final guruDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(currentUserId).get();
      final namaGuru = guruDoc.data()?['alias'];
      if (namaGuru == null) throw Exception("Data guru tidak ditemukan.");
      final docIdCatatan = firestore.collection("id").doc().id;
      final now = DateTime.now();
      final dataCatatan = {
        'idpenginput': currentUserId,
        'namapenginput': namaGuru,
        'idwalikelas': currentUserId,
        'nisn': selectedSiswaId.value,
        'namasiswa': daftarSiswa.firstWhere((s) => s['id'] == selectedSiswaId.value)['nama'],
        'kelassiswa': selectedKelasId.value,
        'judulinformasi': judulC.text,
        'informasicatatansiswa': catatanC.text,
        'tindakanawalwalikelas': tindakanC.text,
        'tanggapanwalikelas': "",
        'tanggapangurubk': "", // <-- FIELD BARU DITAMBAHKAN
        'tanggapankepalasekolah': "",
        'tanggapanorangtua': "",
        'tanggalinput': now.toIso8601String(),
        'docId': docIdCatatan,
      };
      WriteBatch batch = firestore.batch();
      final siswaPath = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(selectedSiswaId.value).collection('tahunajaran').doc(idTahunAjaran!).collection('catatansiswa').doc(docIdCatatan);
      batch.set(siswaPath, dataCatatan);
      final waliKelasPath = firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(currentUserId).collection('catatansiswawali').doc(docIdCatatan);
      batch.set(waliKelasPath, dataCatatan);
      await batch.commit();
      Get.back();
      Get.snackbar("Sukses", "Catatan berhasil disimpan.");
      _clearForm();
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan catatan: ${e.toString()}");
    }
  }

  void _clearForm() {
    judulC.clear();
    catatanC.clear();
    tindakanC.clear();
  }

  void openTanggapanDialog(Map<String, dynamic> catatan) {
    String fieldToUpdate = "";
    String dialogTitle = "";
    switch (userRole.value) {
      case "Kepala Sekolah":
        fieldToUpdate = "tanggapankepalasekolah";
        dialogTitle = "Tanggapan Kepala Sekolah";
        break;
      case "Wali Kelas":
        fieldToUpdate = "tanggapanwalikelas";
        dialogTitle = "Tindakan yang sudah dilakukan Wali Kelas"; // <-- LABEL BARU
        break;
      case "Guru BK": // <-- CASE BARU
        fieldToUpdate = "tanggapangurubk";
        dialogTitle = "Tanggapan/Tindakan Guru BK";
        break;
      default:
        Get.snackbar("Akses Ditolak", "Peran Anda (${userRole.value}) tidak dapat memberikan tanggapan.");
        return;
    }

    tanggapanC.text = catatan[fieldToUpdate] ?? '';
    Get.dialog(
      AlertDialog(
        title: Text(dialogTitle),
        content: TextField(
          controller: tanggapanC,
          decoration: const InputDecoration(labelText: 'Tulis tanggapan...', border: OutlineInputBorder()),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Batal")),
          ElevatedButton(onPressed: () => _simpanTanggapan(catatan, fieldToUpdate), child: const Text("Simpan")),
        ],
      ),
    );
  }

  Future<void> _simpanTanggapan(Map<String, dynamic> catatan, String fieldToUpdate) async {
    if (tanggapanC.text.isEmpty) {
      Get.snackbar("Peringatan", "Tanggapan tidak boleh kosong.");
      return;
    }
    try {
      final docIdCatatan = catatan['docId'];
      final idSiswa = catatan['nisn'];
      if (idSiswa == null || docIdCatatan == null || idTahunAjaran == null) {
        throw Exception("Informasi siswa atau catatan tidak lengkap untuk update.");
      }
      final catatanDocRef = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('siswa').doc(idSiswa)
          .collection('tahunajaran').doc(idTahunAjaran!)
          .collection('catatansiswa').doc(docIdCatatan);
      await catatanDocRef.update({
        fieldToUpdate: tanggapanC.text,
      });
      Get.back();
      Get.snackbar("Sukses", "Tanggapan berhasil disimpan.");
      tanggapanC.clear();
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan tanggapan: ${e.toString()}");
    }
  }
}