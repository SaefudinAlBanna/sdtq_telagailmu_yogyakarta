// lib/app/modules/input_nilai_massal_akademik/controllers/input_nilai_massal_akademik_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_model.dart';

class InputNilaiMassalAkademikController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // --- DATA KONTEKS DARI ARGUMEN ---
  late String idKelas;
  late String idMapel;
  late String namaMapel;
  late String judulTugas;
  late String kategoriTugas;

  // --- STATE UI ---
  final isLoading = true.obs;
  final isSaving = false.obs;

  // --- STATE DATA & FORM ---
  final daftarSiswa = <SiswaModel>[].obs; // Sumber data utama
  final filteredSiswa = <SiswaModel>[].obs; // Untuk ditampilkan di UI
  final textControllers = <String, TextEditingController>{}.obs;
  final absentStudents = <String>{}.obs; // RxSet untuk efisiensi
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // 1. Ambil semua data argumen yang dibutuhkan
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    idKelas = args['idKelas'] ?? '';
    idMapel = args['idMapel'] ?? '';
    namaMapel = args['namaMapel'] ?? '';
    judulTugas = args['judulTugas'] ?? 'Tugas';
    kategoriTugas = args['kategoriTugas'] ?? 'Harian/PR';

    // 2. Tambahkan listener untuk fungsionalitas pencarian reaktif
    searchController.addListener(() {
      filterSiswa(searchController.text);
    });

    // 3. Mulai proses ambil data siswa
    _fetchSiswaAndPrepareForm();
  }
  
  @override
  void onClose() {
    // 4. PENTING: Hapus semua controller untuk mencegah memory leak
    searchController.dispose();
    for (var controller in textControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> _fetchSiswaAndPrepareForm() async {
    isLoading.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final String semester = configC.semesterAktif.value;

      // Ambil UID semua siswa di kelas tersebut
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('semester').doc(semester)
          .collection('daftarsiswa').get();
      
      final List<String> siswaUIDs = snapshot.docs.map((doc) => doc.data()['uid'] as String).toList();
      
      // Ambil data detail siswa menggunakan `whereIn` untuk efisiensi
      if (siswaUIDs.isNotEmpty) {
        final siswaSnapshot = await _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('siswa').where(FieldPath.documentId, whereIn: siswaUIDs).get();
        
        final allSiswa = siswaSnapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
        allSiswa.sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap)); // Urutkan berdasarkan nama

        daftarSiswa.assignAll(allSiswa);
        filteredSiswa.assignAll(allSiswa);

        // Siapkan TextEditingController untuk setiap siswa
        for (var siswa in daftarSiswa) {
          textControllers[siswa.uid] = TextEditingController();
        }
      } else {
        daftarSiswa.clear();
        filteredSiswa.clear();
      }

    } catch (e) {
      print(e);
      Get.snackbar("Error", "Gagal memuat daftar siswa: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void filterSiswa(String query) {
    if (query.isEmpty) {
      filteredSiswa.assignAll(daftarSiswa);
    } else {
      filteredSiswa.assignAll(daftarSiswa.where(
          (siswa) => siswa.namaLengkap.toLowerCase().contains(query.toLowerCase())));
    }
  }

  void toggleAbsen(String uid) {
    if (absentStudents.contains(uid)) {
      absentStudents.remove(uid);
    } else {
      absentStudents.add(uid);
    }
  }

  Future<void> simpanNilaiMassal() async {
    isSaving.value = true;
    final WriteBatch batch = _firestore.batch();
    final List<String> errorMessages = [];
    int validGradesCount = 0;

    try {
      // Loop melalui SEMUA siswa, bukan yang difilter
      for (final siswa in daftarSiswa) {
        // Lewati siswa yang ditandai absen
        if (absentStudents.contains(siswa.uid)) continue;

        final controller = textControllers[siswa.uid];
        final nilaiString = controller?.text.trim();

        // Lewati jika input nilai kosong
        if (nilaiString == null || nilaiString.isEmpty) continue;

        final int? nilai = int.tryParse(nilaiString);

        // Validasi nilai
        if (nilai == null || nilai < 0 || nilai > 100) {
          errorMessages.add("Nilai untuk ${siswa.namaLengkap} tidak valid (harus 0-100).");
          continue; // Lanjut ke siswa berikutnya
        }

        // Jika lolos validasi, tambahkan operasi ke batch
        validGradesCount++;

        // A. Tambahkan dokumen nilai harian
        final nilaiRef = _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
            .collection('kelastahunajaran').doc(idKelas)
            .collection('semester').doc(configC.semesterAktif.value)
            .collection('daftarsiswa').doc(siswa.uid)
            .collection('matapelajaran').doc(idMapel)
            .collection('nilai_harian').doc(); // Buat ID baru
            
        batch.set(nilaiRef, {
          'kategori': kategoriTugas,
          'nilai': nilai,
          'catatan': judulTugas,
          'tanggal': Timestamp.now(),
        });

        // B. Tambahkan notifikasi untuk orang tua
        final siswaDocRef = _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('siswa').doc(siswa.uid);
            
        final notifRef = siswaDocRef.collection('notifikasi').doc();
        batch.set(notifRef, {
          'judul': 'Nilai Baru: $namaMapel',
          'isi': 'Ananda ${siswa.namaLengkap} mendapatkan nilai $nilai untuk "$judulTugas".',
          'tipe': 'NILAI_MAPEL',
          'tanggal': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
        batch.set(metaRef, {'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));
      }

      // Cek hasil validasi sebelum commit
      if (errorMessages.isNotEmpty) {
        Get.snackbar("Input Tidak Valid", errorMessages.join("\n"),
            backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5));
        return;
      }
      
      if (validGradesCount == 0) {
        Get.snackbar("Informasi", "Tidak ada nilai yang diinput untuk disimpan.");
        return;
      }

      // Jika semua aman, eksekusi batch
      await batch.commit();
      Get.back(); // Kembali ke halaman daftar siswa
      Get.snackbar("Berhasil", "$validGradesCount nilai berhasil disimpan dan notifikasi terkirim.");

    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat menyimpan: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }
}