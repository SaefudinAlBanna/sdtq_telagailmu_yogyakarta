import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/siswa_laporan_model.dart';

class LaporanAkademikController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late TabController tabController;

  // State UI Utama
  final isLoading = true.obs;
  final isDetailLoading = false.obs;
  
  // State Data
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> kelasTerpilih = Rxn<Map<String, dynamic>>();
  final RxString infoWaliKelas = "".obs;
  final RxList<SiswaLaporanModel> siswaDiKelas = <SiswaLaporanModel>[].obs;
  late final Map<String, int> _bobotNilai;

  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    await _fetchBobotNilai();
    await _fetchDaftarKelas();
    isLoading.value = false;
  }
  
  Future<void> _fetchBobotNilai() async {
    final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranAktif)
        .collection('pengaturan').doc('bobot_nilai');
    final doc = await docRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      _bobotNilai = {
        'tugasHarian': data['bobotTugasHarian'] ?? 20,
        'ulanganHarian': data['bobotUlanganHarian'] ?? 20,
        'nilaiTambahan': data['bobotNilaiTambahan'] ?? 20,
        'pts': data['bobotPts'] ?? 20,
        'pas': data['bobotPas'] ?? 20,
      };
    } else {
      _bobotNilai = {'tugasHarian': 20, 'ulanganHarian': 20, 'nilaiTambahan': 20, 'pts': 20, 'pas': 20};
    }
  }

  Future<void> _fetchDaftarKelas() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaranAktif)
      .collection('kelastahunajaran').orderBy('namaKelas').get();
    daftarKelas.value = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> onKelasChanged(Map<String, dynamic> kelas) async {
    if (kelasTerpilih.value?['id'] == kelas['id']) return;
    
    kelasTerpilih.value = kelas;
    isDetailLoading.value = true;
    infoWaliKelas.value = kelas['namaWaliKelas'] ?? 'Belum diatur';
    
    await _fetchLaporanDetailKelas(kelas['id']);

    isDetailLoading.value = false;
  }
  
  Future<void> _fetchLaporanDetailKelas(String idKelas) async {
    try {
      final semester = configC.semesterAktif.value;
      final siswaSnapshot = await _firestore
          .collectionGroup('daftarsiswa')
          .where('kelasId', isEqualTo: idKelas)
          .get();

      List<SiswaLaporanModel> tempList = [];

      for (var siswaDoc in siswaSnapshot.docs) {
        final mapelSnapshot = await siswaDoc.reference.collection('matapelajaran').get();
        if (mapelSnapshot.docs.isEmpty) continue;

        double totalNilaiAkhir = 0;
        double totalRataRataHarian = 0;
        int totalPts = 0;
        int totalPas = 0;

        for (var mapelDoc in mapelSnapshot.docs) {
          final data = mapelDoc.data();
          totalNilaiAkhir += (data['nilai_akhir'] as num?)?.toDouble() ?? 0.0;
          // Di sini kita bisa tambahkan logika untuk mengambil detail nilai lain jika perlu
        }
        
        final double nilaiRapor = totalNilaiAkhir / mapelSnapshot.docs.length;

        tempList.add(SiswaLaporanModel(
          uid: siswaDoc.id,
          nama: siswaDoc.data()['namaLengkap'] ?? 'Tanpa Nama',
          nisn: siswaDoc.data()['nisn'] ?? '-',
          nilaiAkhirRapor: nilaiRapor,
          // Placeholder untuk detail, bisa dikembangkan
          rataRataHarian: 0,
          nilaiPts: 0,
          nilaiPas: 0,
        ));
      }
      
      // Urutkan berdasarkan peringkat (nilai tertinggi ke terendah)
      tempList.sort((a, b) => b.nilaiAkhirRapor.compareTo(a.nilaiAkhirRapor));
      siswaDiKelas.value = tempList;

    } catch (e) {
      print(e);
      Get.snackbar("Error", "Gagal memuat detail laporan kelas: $e");
    }
  }
}