// lib/app/modules/daftar_siswa_permapel/controllers/daftar_siswa_permapel_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/tugas_simple_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';

class DaftarSiswaPermapelController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String idKelas, namaMapel, idMapel, idGuru, namaGuru;
  final isLoading = true.obs;
  final isDialogLoading = false.obs;
  final isTugasDialogLoading = false.obs;

  final RxList<SiswaModel> daftarSiswa = <SiswaModel>[].obs;
  final TextEditingController judulTugasC = TextEditingController();
  final TextEditingController deskripsiTugasC = TextEditingController();

  late bool isGuruPengganti;
  bool get isPengganti => isGuruPengganti;

  @override
  void onInit() {
    super.onInit();
    final Map<String, dynamic> args = Get.arguments ?? {};
    idKelas = args['idKelas'] ?? '';
    namaMapel = args['namaMapel'] ?? '';
    idMapel = args['idMapel'] ?? '';
    idGuru = args['idGuru'] ?? '';
    namaGuru = args['namaGuru'] ?? '';
    isGuruPengganti = args['isPengganti'] ?? false; 
    fetchSiswa();
  }
  
  @override
  void onClose() {
    judulTugasC.dispose();
    deskripsiTugasC.dispose();
    super.onClose();
  }

  Future<void> fetchSiswa() async {
    isLoading.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      if (tahunAjaran.isEmpty || tahunAjaran.contains("ERROR")) throw Exception("Tahun Ajaran tidak valid.");

      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('semester').doc(configC.semesterAktif.value)
          .collection('daftarsiswa').orderBy('namasiswa').get();
      
      final List<String> siswaUIDs = snapshot.docs.map((doc) => doc.data()['uid'] as String).toList();
      
      if (siswaUIDs.isNotEmpty) {
        final siswaSnapshot = await _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('siswa').where(FieldPath.documentId, whereIn: siswaUIDs).get();
        daftarSiswa.assignAll(siswaSnapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
        daftarSiswa.sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));
      } else {
        daftarSiswa.clear();
      }

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar siswa: ${e.toString()}");
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showPilihTugasDialog() async {
    isTugasDialogLoading.value = true;
    // Tampilkan dialog loading sementara mengambil data
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final List<TugasSimpleModel> daftarTugas = await _fetchTugasUntukDialog();
      Get.back(); // Tutup dialog loading

      if (daftarTugas.isEmpty) {
        Get.defaultDialog(
          title: "Belum Ada Tugas",
          middleText: "Belum ada tugas/ulangan yang pernah Anda buat untuk mata pelajaran ini. Silakan buat terlebih dahulu.",
          textConfirm: "OK",
          onConfirm: Get.back,
        );
        return;
      }

      // Tampilkan dialog dengan daftar tugas
      Get.defaultDialog(
        title: "Pilih Penilaian",
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        content: SizedBox(
          width: Get.width * 0.8,
          height: Get.height * 0.4,
          child: ListView.builder(
            itemCount: daftarTugas.length,
            itemBuilder: (context, index) {
              final tugas = daftarTugas[index];
              return Card(
                child: ListTile(
                  leading: Icon(tugas.kategori == "PR" ? Icons.assignment_outlined : Icons.quiz_outlined),
                  title: Text(tugas.judul),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(tugas.tanggalDibuat)),
                  onTap: () {
                    Get.back(); // Tutup dialog pilihan
                    _goToInputNilaiMassal(tugas);
                  },
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      Get.back(); // Tutup dialog loading jika ada error
      Get.snackbar("Error", "Gagal memuat daftar tugas: $e");
    } finally {
      isTugasDialogLoading.value = false;
    }
  }

  Future<List<TugasSimpleModel>> _fetchTugasUntukDialog() async {
    final String tahunAjaran = configC.tahunAjaranAktif.value;
    final ref = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(configC.semesterAktif.value)
        .collection('tugas_ulangan')
        .where('idMapel', isEqualTo: idMapel) // Filter berdasarkan mapel
        .orderBy('tanggal_dibuat', descending: true); // Urutkan terbaru di atas

    final snapshot = await ref.get();
    return snapshot.docs.map((doc) => TugasSimpleModel.fromFirestore(doc)).toList();
  }

  void _goToInputNilaiMassal(TugasSimpleModel tugas) {
    Get.toNamed(
      Routes.INPUT_NILAI_MASSAL_AKADEMIK, // <-- Panggil route baru kita
      arguments: {
        'idKelas': idKelas,
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idTugas': tugas.id, // <-- Kirim ID Tugas
        'judulTugas': tugas.judul,
        'kategoriTugas': tugas.kategori,
      },
    );
  }

  // --- FUNGSI DIPERBAIKI DENGAN LOGIKA NOTIFIKASI ---
  Future<void> buatTugasBaru(String kategori) async {
    if (judulTugasC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Judul tidak boleh kosong."); return;
    }
    isDialogLoading.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final ref = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(configC.semesterAktif.value)
        .collection('tugas_ulangan');

      // 1. Buat dokumen tugas/ulangan terlebih dahulu
      final newTugasRef = await ref.add({
        'judul': judulTugasC.text.trim(),
        'kategori': kategori,
        'deskripsi': deskripsiTugasC.text.trim(),
        'tanggal_dibuat': Timestamp.now(),
        'status': 'diumumkan',
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idGuru': idGuru,
      });

      // 2. Kirim notifikasi ke semua siswa di kelas ini
      final WriteBatch notifBatch = _firestore.batch();
      final String judulNotif = (kategori == "PR") ? "PR Baru: $namaMapel" : "Ulangan Baru: $namaMapel";
      final String isiNotif = "Ananda mendapatkan tugas baru: '${judulTugasC.text.trim()}'.";

      for (var siswa in daftarSiswa) {
        final siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
        
        // Buat dokumen notifikasi baru
        notifBatch.set(siswaDocRef.collection('notifikasi').doc(), {
          'judul': judulNotif,
          'isi': isiNotif,
          'tipe': (kategori == "PR") ? 'TUGAS_BARU' : 'ULANGAN_BARU',
          'tanggal': FieldValue.serverTimestamp(),
          'isRead': false,
          'deepLink': '/akademik/tugas/${newTugasRef.id}',
        });

        // Update counter di sub-koleksi 'notifikasi_meta'
        final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
        notifBatch.set(metaRef, {'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));
      }
      
      await notifBatch.commit();
      
      Get.back();
      Get.snackbar("Berhasil", "$kategori baru telah dibuat dan notifikasi dikirim.");
    } catch(e) {
      Get.snackbar("Error", "Gagal membuat tugas: $e"); 
    } finally { 
      isDialogLoading.value = false; 
      judulTugasC.clear(); 
      deskripsiTugasC.clear(); 
    }
  }
  
  void goToInputNilaiSiswa(SiswaModel siswa) {
    // Jika pengguna adalah guru pengganti, blokir akses.
    if (isGuruPengganti) {
      Get.snackbar(
        "Akses Ditolak", 
        "Hanya guru asli mata pelajaran yang dapat mengedit nilai siswa secara individual.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white
      );
      return; // Hentikan eksekusi fungsi
    }

    // Jika bukan guru pengganti, lanjutkan navigasi seperti biasa.
    Get.toNamed(
      Routes.INPUT_NILAI_SISWA,
      arguments: {
        'idKelas': idKelas,
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idGuru': idGuru,
        'namaGuru': namaGuru,
        'siswa': siswa,
      },
    );
  }
}