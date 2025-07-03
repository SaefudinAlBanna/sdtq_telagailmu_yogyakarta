import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InputNilaiSiswaController extends GetxController {
  // Controllers untuk form input
  late TextEditingController namaPenilaianC;
  late TextEditingController nilaiC;
  late TextEditingController deskripsiC;
  RxString jenisNilai = "Sumatif".obs; // Default ke Sumatif, .obs agar reaktif

  // Ambil argumen dari halaman sebelumnya
  final Map<String, dynamic> args;
   InputNilaiSiswaController({required this.args});

   var isReady = false.obs;
  
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String idSekolah = "P9984539"; // Sebaiknya diambil dari data login guru

  // Variabel untuk menyimpan path yang sering digunakan
  late String _idTahunAjaran;
  late String _idSemester;
  late CollectionReference<Map<String, dynamic>> _nilaiCollectionRef;

 @override
  void onInit() {
    super.onInit();
    // Pindahkan logic async ke method terpisah
    _initializeController();
  }

   // Method baru untuk menangani inisialisasi async
  Future<void> _initializeController() async {
    namaPenilaianC = TextEditingController();
    nilaiC = TextEditingController();
    deskripsiC = TextEditingController();

    // Proses async
    String tahunAjaran = await getTahunAjaranTerakhir();
    _idTahunAjaran = tahunAjaran.replaceAll("/", "-");
    _idSemester = await getSemesterTerakhir();

    // Inisialisasi collection reference
    _nilaiCollectionRef = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(_idTahunAjaran)
        .collection('kelastahunajaran').doc(args['idKelas'])
        .collection('daftarsiswa').doc(args['idSiswa'])
        .collection('semester').doc(_idSemester)
        .collection('matapelajaran').doc(args['idMapel'])
        .collection('nilai');
    
    // ---> SETELAH SEMUA SIAP, UBAH STATUS <---
    isReady.value = true;
  }

  @override
  void onClose() {
    namaPenilaianC.dispose();
    nilaiC.dispose();
    deskripsiC.dispose();
    super.onClose();
  }


  // Fungsi untuk mengambil daftar nilai yang sudah ada (menggunakan Stream)
  Stream<QuerySnapshot<Map<String, dynamic>>> getDaftarNilai() {
    // diurutkan berdasarkan tanggal terbaru
    return _nilaiCollectionRef.orderBy('tanggal', descending: true).snapshots();
  }

  // Fungsi untuk menambahkan nilai baru ke Firestore
  void addNilai() async {
    if (namaPenilaianC.text.isNotEmpty && nilaiC.text.isNotEmpty) {
      try {
        await _nilaiCollectionRef.add({
          "jenisNilai": jenisNilai.value,
          "namaPenilaian": namaPenilaianC.text,
          "nilai": int.tryParse(nilaiC.text) ?? 0,
          "deskripsi": deskripsiC.text,
          "tanggal": Timestamp.now(),
        });

        // Tutup bottom sheet setelah berhasil
        Get.back(); 
        Get.snackbar("Berhasil", "Nilai berhasil ditambahkan.");
        // Bersihkan form
        namaPenilaianC.clear();
        nilaiC.clear();
        deskripsiC.clear();

      } catch (e) {
        Get.snackbar("Error", "Gagal menambahkan nilai: $e");
      }
    } else {
      Get.snackbar("Peringatan", "Nama Penilaian dan Nilai wajib diisi.");
    }
  }
  
  // Fungsi helper (Anda bisa pindahkan ini ke controller utama/parent)
  Future<String> getTahunAjaranTerakhir() async { /* ... kode Anda ... */ return "2024/2025"; }
  Future<String> getSemesterTerakhir() async { /* ... kode Anda ... */ return "Semester I"; }
}