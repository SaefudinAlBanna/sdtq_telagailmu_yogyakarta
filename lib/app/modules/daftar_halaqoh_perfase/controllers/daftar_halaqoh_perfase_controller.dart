import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../models/pengampu_info.dart';

class DaftarHalaqohPerfaseController extends GetxController {
  // --- STATE REAKTIF BARU ---
  // Menyimpan fase yang sedang dipilih. Null berarti belum ada yang dipilih.
  final Rx<String?> selectedFase = Rx<String?>(null);

  // isLoading sekarang default-nya false, karena kita baru loading setelah user memilih.
  final RxBool isLoading = false.obs; 
  
  final RxList<PengampuInfo> daftarPengampu = <PengampuInfo>[].obs;

  // Daftar pilihan statis untuk dropdown
  final List<String> listPilihanFase = ["A", "B", "C"];
  
  // --- Properti yang tidak berubah ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String idSekolah = 'P9984539';

  // onInit dan onReady tidak lagi dibutuhkan untuk membaca parameter.
  // Biarkan kosong atau hapus saja.

  /// Fungsi ini akan dipanggil oleh Dropdown di View setiap kali user memilih fase baru.
  void onFaseChanged(String? newValue) {
    // Jika user memilih nilai yang valid dan berbeda dari sebelumnya
    if (newValue != null && newValue != selectedFase.value) {
      selectedFase.value = newValue;
      daftarPengampu.clear(); // Kosongkan daftar lama sebelum memuat yang baru
      loadDataPengampu(); // Panggil fungsi untuk memuat data
    }
  }

  // di dalam DaftarHalaqohPerfaseController.dart

Future<void> loadDataPengampu() async {
  // Jangan lakukan apa-apa jika tidak ada fase yang terpilih
  if (selectedFase.value == null) return;

  isLoading.value = true;
  try {
    String tahunAjaran = await _getTahunAjaranTerakhir();
    String idTahunAjaran = tahunAjaran.replaceAll("/", "-");
    String namaDokumenFase = "Fase ${selectedFase.value}";

    // Query awal untuk mendapatkan daftar pengampu
    final snapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(namaDokumenFase)
        .collection('pengampu')
        .get();

    if (snapshot.docs.isNotEmpty) {
      // 1. Buat list awal dari data pengampu yang ada (tanpa foto)
      final List<PengampuInfo> pengampuListAwal = snapshot.docs
          .map((doc) => PengampuInfo.fromFirestore(doc))
          .toList();

      // 2. Siapkan daftar 'Future' untuk mengambil foto profil setiap pengampu secara paralel
      final List<Future<PengampuInfo>> futures = pengampuListAwal.map((pengampu) async {
  String? profileImageUrl;
  int jumlahSiswa = 0; // Default 0

  try {
    // Ambil foto dan JUMLAH SISWA secara bersamaan jika bisa
    final docRef = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('pegawai').doc(pengampu.idPengampu);

    final siswaSnapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran) // idTahunAjaran dari scope luar
        .collection('kelompokmengaji').doc("Fase ${selectedFase.value}")
        .collection('pengampu').doc(pengampu.namaPengampu) // Gunakan nama pengampu sebagai ID di path ini
        .collection('daftarsiswa').get();

    jumlahSiswa = siswaSnapshot.docs.length; // Hitung jumlahnya

    final pegawaiDoc = await docRef.get();
    if (pegawaiDoc.exists) {
      profileImageUrl = pegawaiDoc.data()?['profileImageUrl'];
    }
  } catch (e) {
    if (kDebugMode) print("Error ambil detail pengampu: $e");
  }

  // Gunakan copyWith untuk membuat objek baru yang lengkap
  return pengampu.copyWith(
    profileImageUrl: profileImageUrl,
    jumlahSiswa: jumlahSiswa,
  );
}).toList();

      // 3. Jalankan semua Future secara bersamaan dan tunggu sampai semuanya selesai
      final List<PengampuInfo> pengampuListLengkap = await Future.wait(futures);

      // 4. Update state reaktif dengan daftar pengampu yang sudah lengkap
      daftarPengampu.assignAll(pengampuListLengkap);

    } else {
      // Jika tidak ada pengampu di fase ini, kosongkan daftar
      daftarPengampu.clear();
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error saat memuat data pengampu: $e");
    }
    daftarPengampu.clear(); // Pastikan daftar kosong jika terjadi error utama
  } finally {
    isLoading.value = false;
  }
}

  Future<String> _getTahunAjaranTerakhir() async {
    final snapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception("Tahun Ajaran tidak ditemukan");
    }
    return snapshot.docs.first.data()['namatahunajaran'];
  }
}