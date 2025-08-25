// lib/app/modules/input_nilai_siswa/controllers/input_nilai_siswa_controller.dart (FINAL & TERINTEGRASI)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/atp_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/nilai_harian_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_model.dart';

class InputNilaiSiswaController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data Konteks
  late String idKelas, namaMapel, idMapel, idGuru, namaGuru;
  late SiswaModel siswa;
  late String idTahunAjaran, semesterAktif;
  late DocumentReference siswaMapelRef;

  // State UI
  final isLoading = true.obs;
  final isSaving = false.obs;
  final RxBool isWaliKelas = false.obs;

  // State Data Nilai
  final RxList<NilaiHarianModel> daftarNilaiHarian = <NilaiHarianModel>[].obs;
  final RxMap<String, int> bobotNilai = <String, int>{}.obs;
  final Rxn<int> nilaiPTS = Rxn<int>();
  final Rxn<int> nilaiPAS = Rxn<int>();
  final Rxn<double> nilaiAkhir = Rxn<double>();
  final RxList<Map<String, dynamic>> rekapNilaiMapelLain = <Map<String, dynamic>>[].obs;

  // State Kurikulum Merdeka
  final Rxn<AtpModel> atpModel = Rxn<AtpModel>();
  final RxMap<String, String> capaianTpSiswa = <String, String>{}.obs;
  final TextEditingController deskripsiCapaianC = TextEditingController();

  // State Form Dialog
  final TextEditingController nilaiC = TextEditingController();
  final TextEditingController catatanC = TextEditingController();
  final harianC = TextEditingController(), ulanganC = TextEditingController(), 
        ptsC = TextEditingController(), pasC = TextEditingController(), 
        tambahanC = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    if (Get.arguments == null) {
      Get.snackbar("Error", "Argumen halaman tidak valid.");
      isLoading.value = false;
      return;
    }
    _initializeArguments();
    loadInitialData();
  }

  void _initializeArguments() {
    final Map<String, dynamic> args = Get.arguments ?? {};
    idKelas = args['idKelas'] ?? '';
    namaMapel = args['namaMapel'] ?? '';
    idMapel = args['idMapel'] ?? '';
    idGuru = args['idGuru'] ?? '';
    namaGuru = args['namaGuru'] ?? '';
    siswa = args['siswa'];

    idTahunAjaran = configC.tahunAjaranAktif.value;
    semesterAktif = configC.semesterAktif.value;

    siswaMapelRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(idTahunAjaran)
      .collection('kelastahunajaran').doc(idKelas)
      .collection('semester').doc(semesterAktif)
      .collection('daftarsiswa').doc(siswa.uid)
      .collection('matapelajaran').doc(idMapel);
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchBobotNilai(),
        fetchNilaiDanDeskripsiSiswa(),
        fetchNilaiHarian(),
        checkIsWaliKelas(),
        _fetchAtp(),
      ]);
      hitungNilaiAkhir();
    } catch (e) { Get.snackbar("Error", "Gagal memuat data nilai siswa: $e"); } 
    finally { isLoading.value = false; }
  }

  Future<void> checkIsWaliKelas() async {
    // Gunakan data dari ConfigController yang sudah ada & efisien
    if (configC.infoUser['kelasDiampu'] == idKelas) {
      isWaliKelas.value = true;
      fetchRekapNilaiMapelLain(); 
    }
  }

   Future<void> fetchRekapNilaiMapelLain() async {
      try {
        // Parent dari siswaMapelRef adalah .../daftarsiswa/{uid}/matapelajaran
        final snapshot = await siswaMapelRef.parent.get();

        final List<Map<String, dynamic>> rekapList = [];
        for (var doc in snapshot.docs) {
          // Kecualikan mapel yang sedang dibuka
          if (doc.id == idMapel) continue;

          // Cast Object? ke Map<String, dynamic>
          final data = doc.data() as Map<String, dynamic>?;

          if (data != null) {
            rekapList.add({
              'mapel': data['namaMapel'] ?? doc.id,
              'guru': data['namaGuru'] ?? 'N/A',
              'nilai_akhir': (data['nilai_akhir'] as num?)?.toDouble() ?? 0.0,
            });
          }
        }

        rekapNilaiMapelLain.assignAll(rekapList);
      } catch (e) {
        Get.snackbar("Error", "Gagal memuat rekap nilai mapel lain: $e");
      }
    }


  // --- [FUNGSI YANG DIPERBARUI] ---
  Future<void> _fetchAtp() async {
    try {
      // final kelasAngka = int.tryParse(idKelas.split('-').first) ?? 0;
      final kelasString = idKelas.split('-').first.replaceAll(RegExp(r'[^0-9]'), '');
      final kelasAngka = int.tryParse(kelasString) ?? 0;
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('atp')
          .where('idTahunAjaran', isEqualTo: idTahunAjaran)
          .where('namaMapel', isEqualTo: namaMapel)
          .where('kelas', isEqualTo: kelasAngka).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        atpModel.value = AtpModel.fromJson(snapshot.docs.first.data());
      } else {
        atpModel.value = null; // Pastikan null jika tidak ditemukan
      }
    } catch (e) { Get.snackbar("Info ATP", "Gagal memuat data ATP: $e"); atpModel.value = null; }
  }

  Future<void> fetchNilaiDanDeskripsiSiswa() async {
    final doc = await siswaMapelRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      nilaiPTS.value = data['nilai_pts'];
      nilaiPAS.value = data['nilai_pas'];
      deskripsiCapaianC.text = data['deskripsi_capaian'] ?? '';
      // --- [PERBAIKAN] Ganti nama 'capaianSiswa' menjadi 'capaianTpSiswa' ---
      if (data['capaian_tp'] != null) capaianTpSiswa.value = Map<String, String>.from(data['capaian_tp']);
    }
  }

  // --- [FUNGSI BARU] Menggantikan simpanCapaianTP lama ---
  void setCapaianTp(String tp, String status) {
    if (capaianTpSiswa[tp] == status) { capaianTpSiswa.remove(tp); } 
    else { capaianTpSiswa[tp] = status; }
  }

  Future<void> simpanSemuaCapaian() async {
    isSaving.value = true;
    try {
      await siswaMapelRef.set({
        'deskripsi_capaian': deskripsiCapaianC.text.trim(),
        'capaian_tp': capaianTpSiswa
      }, SetOptions(merge: true));
      Get.snackbar("Berhasil", "Capaian pembelajaran berhasil disimpan.");
    } catch (e) { Get.snackbar("Error", "Gagal menyimpan capaian: $e"); } 
    finally { isSaving.value = false; }
  }

  Future<void> fetchBobotNilai() async {
    // Path baru yang terpusat
    final docRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('pengaturan').doc('bobot_nilai');

    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Mengisi state dengan data dari Firestore
        bobotNilai.value = {
          'tugasHarian': data['bobotTugasHarian'] ?? 20,
          'ulanganHarian': data['bobotUlanganHarian'] ?? 20,
          'nilaiTambahan': data['bobotNilaiTambahan'] ?? 20,
          'pts': data['bobotPts'] ?? 20,
          'pas': data['bobotPas'] ?? 20,
        };
      } else {
        // --- [IMPLEMENTASI DEFAULT] ---
        // Jika dokumen tidak ada, gunakan default 20%
        bobotNilai.value = {
          'tugasHarian': 20,
          'ulanganHarian': 20,
          'nilaiTambahan': 20,
          'pts': 20,
          'pas': 20,
        };
      }
    } catch (e) {
      print("### Gagal fetch bobot nilai, menggunakan default. Error: $e");
      // Fallback jika terjadi error
      bobotNilai.value = {
        'tugasHarian': 20, 'ulanganHarian': 20, 'nilaiTambahan': 20,
        'pts': 20, 'pas': 20,
      };
    }
  }

  Future<void> fetchNilaiHarian() async {
    final snapshot = await siswaMapelRef.collection('nilai_harian').orderBy('tanggal', descending: true).get();
    daftarNilaiHarian.assignAll(snapshot.docs.map((doc) => NilaiHarianModel.fromFirestore(doc)).toList());
  }


  Future<void> simpanNilaiHarian(String kategori) async {
    int? nilai = int.tryParse(nilaiC.text.trim());
    if (nilai == null || nilai < 0 || nilai > 100) { Get.snackbar("Peringatan", "Nilai harus angka 0-100."); return; }
    isSaving.value = true;
    try {
      WriteBatch batch = _firestore.batch();
      final refNilaiBaru = siswaMapelRef.collection('nilai_harian').doc();
      batch.set(refNilaiBaru, {'kategori': kategori, 'nilai': nilai, 'catatan': catatanC.text.trim(), 'tanggal': Timestamp.now()});
      
      final siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
      batch.set(siswaDocRef.collection('notifikasi').doc(), {
          'judul': 'Nilai Baru: $namaMapel', 'isi': 'Ananda ${siswa.namaLengkap} mendapatkan nilai $nilai untuk $kategori.',
          'tipe': 'NILAI_MAPEL', 'tanggal': FieldValue.serverTimestamp(), 'isRead': false,
      });
      final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
      batch.set(metaRef, {'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));
      
      await batch.commit();
      await fetchNilaiHarian();
      hitungNilaiAkhir();
      Get.back();
    } catch(e) { Get.snackbar("Error", "Gagal menyimpan nilai: $e"); } 
    finally { isSaving.value = false; }
  }

  Future<void> updateNilaiHarian(String idNilai) async {
    int? nilai = int.tryParse(nilaiC.text.trim());
    if (nilai == null || nilai < 0 || nilai > 100) { Get.snackbar("Peringatan", "Nilai harus berupa angka 0-100."); return; }
    isSaving.value = true;
    try {
      await siswaMapelRef.collection('nilai_harian').doc(idNilai).update({'nilai': nilai, 'catatan': catatanC.text.trim()});
      await fetchNilaiHarian();
      hitungNilaiAkhir();
      Get.back();
      Get.snackbar("Berhasil", "Nilai berhasil diperbarui.");
    } catch (e) { Get.snackbar("Error", "Gagal memperbarui nilai: $e"); } 
    finally { isSaving.value = false; }
  }

  Future<void> deleteNilaiHarian(String idNilai) async {
    try {
      await siswaMapelRef.collection('nilai_harian').doc(idNilai).delete();
      daftarNilaiHarian.removeWhere((item) => item.id == idNilai);
      hitungNilaiAkhir();
      Get.snackbar("Berhasil", "Nilai harian telah dihapus.");
    } catch (e) { Get.snackbar("Error", "Gagal menghapus nilai: $e"); }
  }

  Future<void> simpanNilaiUtama(String jenisNilai, int nilai) async {
    isSaving.value = true;
    try {
      await siswaMapelRef.set({jenisNilai: nilai}, SetOptions(merge: true));
      await fetchNilaiDanDeskripsiSiswa();
      hitungNilaiAkhir();
      Get.back();
    } catch(e) { Get.snackbar("Error", "Gagal menyimpan nilai: $e"); }
    finally { isSaving.value = false; }
  }

  void hitungNilaiAkhir() {
    if (bobotNilai.isEmpty) return;
    
    // 1. Hitung rata-rata & total dari setiap kategori
    double avgTugasHarian = _calculateAverage("Harian/PR");
    double avgUlanganHarian = _calculateAverage('Ulangan Harian');
    double totalNilaiTambahan = _calculateSum('Nilai Tambahan');
    int pts = nilaiPTS.value ?? 0;
    int pas = nilaiPAS.value ?? 0;

    // 2. Ambil bobot dari state (dengan fallback 0 jika tidak ada)
    int bobotTugas = bobotNilai['tugasHarian'] ?? 0;
    int bobotUlangan = bobotNilai['ulanganHarian'] ?? 0;
    int bobotTambahan = bobotNilai['nilaiTambahan'] ?? 0;
    int bobotPTS = bobotNilai['pts'] ?? 0;
    int bobotPAS = bobotNilai['pas'] ?? 0;
    
    // 3. Hitung total pembagi (jumlah semua bobot)
    int totalBobot = bobotTugas + bobotUlangan + bobotTambahan + bobotPTS + bobotPAS;
    if (totalBobot == 0) {
      nilaiAkhir.value = 0;
      return;
    }
    
    // 4. Hitung skor akhir dengan formula pembobotan yang benar
    double finalScore = 
        ((avgTugasHarian * bobotTugas) +
        (avgUlanganHarian * bobotUlangan) +
        (pts * bobotPTS) +
        (pas * bobotPAS) +
        (totalNilaiTambahan)) / totalBobot; // Nilai tambahan tidak dibobot, tapi dijumlahkan

    // 5. Pastikan nilai tidak melebihi 100
    nilaiAkhir.value = finalScore > 100.0 ? 100.0 : finalScore;
    
    // 6. Simpan nilai akhir ke Firestore
    siswaMapelRef.set({
      'nilai_akhir': nilaiAkhir.value,
      'namaMapel': namaMapel,
      'namaGuru': namaGuru, // Disimpan untuk referensi
      'idGuru': idGuru,
    }, SetOptions(merge: true));
  }
  
  double _calculateAverage(String kategori) {
    var listNilai = daftarNilaiHarian.where((n) {
      if (kategori == "Harian/PR") return n.kategori == "Harian/PR" || n.kategori == "PR";
      return n.kategori == kategori;
    }).toList();
    if (listNilai.isEmpty) return 0;
    return listNilai.fold(0, (sum, item) => sum + item.nilai) / listNilai.length;
  }
  
  double _calculateSum(String kategori) {
    var listNilai = daftarNilaiHarian.where((n) => n.kategori == kategori).toList();
    if (listNilai.isEmpty) return 0;
    return listNilai.fold(0, (sum, item) => sum + item.nilai).toDouble();
  }
}