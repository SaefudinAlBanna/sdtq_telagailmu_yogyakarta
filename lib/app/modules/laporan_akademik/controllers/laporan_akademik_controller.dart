import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/siswa_laporan_model.dart';
import '../../../models/rapor_model.dart'; // [PENTING] Import RaporModel
import '../../../routes/app_pages.dart';

class LaporanAkademikController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late TabController tabController;

  final isLoading = true.obs;
  final isDetailLoading = false.obs;
  
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> kelasTerpilih = Rxn<Map<String, dynamic>>();
  final RxString infoWaliKelas = "".obs;
  final RxList<SiswaLaporanModel> siswaDiKelas = <SiswaLaporanModel>[].obs;

  // State Detail
  final Rxn<SiswaLaporanModel> siswaTerpilihDetail = Rxn<SiswaLaporanModel>();
  // Kita simpan detail nilai mapel dalam bentuk List Map
  final RxList<Map<String, dynamic>> detailNilaiSiswa = <Map<String, dynamic>>[].obs;

  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    await _fetchDaftarKelas();
    isLoading.value = false;
  }
  
  Future<void> _fetchDaftarKelas() async {
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranAktif)
        .collection('kelastahunajaran').orderBy('namaKelas').get();
      
      daftarKelas.value = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar kelas.");
    }
  }

  Future<void> onKelasChanged(Map<String, dynamic> kelas) async {
    if (kelasTerpilih.value?['id'] == kelas['id']) return;
    
    kelasTerpilih.value = kelas;
    isDetailLoading.value = true;
    infoWaliKelas.value = kelas['namaWaliKelas'] ?? 'Belum diatur';
    
    siswaTerpilihDetail.value = null;
    detailNilaiSiswa.clear();
    tabController.animateTo(0);

    await _fetchLaporanDetailKelas(kelas['id']);

    isDetailLoading.value = false;
  }
  
  // [REVISI TOTAL: Menggunakan Data Rapor yang Sudah Digenerate]
  Future<void> _fetchLaporanDetailKelas(String idKelas) async {
    try {
      final semester = configC.semesterAktif.value;

      // 1. Ambil Data Siswa (untuk referensi nama & NISN)
      final siswaSnapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('daftarsiswa')
          .get();

      if (siswaSnapshot.docs.isEmpty) {
        siswaDiKelas.clear(); return;
      }

      // Map Siswa Awal (Nilai 0 dulu)
      final Map<String, SiswaLaporanModel> siswaMap = {
        for (var doc in siswaSnapshot.docs)
          doc.id: SiswaLaporanModel(
            uid: doc.id,
            nama: doc.data()['namaLengkap'] ?? 'Tanpa Nama',
            nisn: doc.data()['nisn'] ?? '-',
            // [BARU] Ambil URL Foto
            fotoProfilUrl: doc.data()['fotoProfilUrl'], 
          )
      };

      // 2. Ambil Dokumen Rapor (Hanya field penting untuk hemat bandwidth)
      // Path: /Sekolah/{id}/tahun/{id}/kelas/{id}/rapor/{uid_semester}
      final raporSnapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('rapor')
          .where('semester', isEqualTo: semester)
          .get();

      // 3. Update Nilai Rata-rata dari Rapor
      for (var doc in raporSnapshot.docs) {
        final data = doc.data();
        final uidSiswa = data['idSiswa'];
        final rataRata = (data['nilaiRataRata'] as num?)?.toDouble() ?? 0.0;

        if (siswaMap.containsKey(uidSiswa)) {
          siswaMap[uidSiswa]!.nilaiAkhirRapor = rataRata;
        }
      }

      // 4. Konversi ke List & Sort Ranking
      final tempList = siswaMap.values.toList();
      tempList.sort((a, b) => b.nilaiAkhirRapor.compareTo(a.nilaiAkhirRapor));
      
      siswaDiKelas.value = tempList;

    } catch (e) {
      print("### Error fetch Laporan Kelas: $e");
      Get.snackbar("Error", "Gagal memuat data peringkat kelas.");
    }
  }

  Future<void> onSiswaTapped(SiswaLaporanModel siswa) async {
    siswaTerpilihDetail.value = siswa;
    tabController.animateTo(1); 
    
    // Ambil detail nilai per mapel dari dokumen rapor siswa tersebut
    await _fetchDetailNilaiSiswa(siswa.uid);
  }

  // [REVISI: Ambil Detail dari RaporModel]
  Future<void> _fetchDetailNilaiSiswa(String uidSiswa) async {
    try {
      final semester = configC.semesterAktif.value;
      final idKelas = kelasTerpilih.value!['id'];
      
      // Construct ID Rapor
      final raporId = "${uidSiswa}_$semester";

      final doc = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('rapor').doc(raporId)
          .get();
      
      if (!doc.exists) {
        detailNilaiSiswa.clear();
        Get.snackbar("Info", "Rapor siswa ini belum digenerate oleh Wali Kelas.");
        return;
      }

      // Parse RaporModel
      final rapor = RaporModel.fromFirestore(doc);
      
      // Ambil daftar nilai mapel
      final List<Map<String, dynamic>> listNilai = rapor.daftarNilaiMapel.map((m) => {
        'mapel': m.namaMapel,
        'nilai_akhir': m.nilaiAkhir,
        'deskripsi': m.deskripsiCapaian
      }).toList();

      // Sort mapel by nilai tertinggi
      listNilai.sort((a, b) => (b['nilai_akhir'] as double).compareTo(a['nilai_akhir'] as double));
      
      detailNilaiSiswa.assignAll(listNilai);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat rincian nilai: $e");
    }
  }

  void goToGuruAkademik() {
     Get.toNamed(Routes.GURU_AKADEMIK);
  }
  
  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}