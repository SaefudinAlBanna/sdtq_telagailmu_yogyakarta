// lib/app/modules/absensi_wali_kelas/controllers/absensi_wali_kelas_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_simple_model.dart';

import '../../../controllers/auth_controller.dart';

class AbsensiWaliKelasController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  // State
  final isLoading = true.obs;
  final isSaving = false.obs;
  final RxList<SiswaSimpleModel> daftarSiswa = <SiswaSimpleModel>[].obs;
  
  // State Absensi
  final RxMap<String, String> statusAbsensi = <String, String>{}.obs;
  final RxMap<String, TextEditingController> keteranganControllers = <String, TextEditingController>{}.obs;
  final catatanHarianC = TextEditingController();
  
  // State Rekap Real-time
  final RxInt totalSiswa = 0.obs;
  final RxInt totalHadir = 0.obs;
  final RxInt totalSakit = 0.obs;
  final RxInt totalIzin = 0.obs;
  final RxInt totalAlfa = 0.obs;

  late String kelasDiampu;
  late String tanggalHariIni;

  @override
  void onInit() {
    super.onInit();
    kelasDiampu = configC.infoUser['kelasDiampu'] ?? '';
    tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      await _fetchDaftarSiswa();
      await _fetchAbsensiHariIni();
      _calculateRekap(); // Hitung rekap awal
    } catch (e) { Get.snackbar("Error", "Gagal memuat data: $e"); } 
    finally { isLoading.value = false; }
  }

  Future<void> _fetchDaftarSiswa() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').where('kelasId', isEqualTo: kelasDiampu).get();
    
    final siswaList = snapshot.docs.map((doc) => SiswaSimpleModel.fromFirestore(doc)).toList();
    siswaList.sort((a, b) => a.nama.compareTo(b.nama));
    daftarSiswa.assignAll(siswaList);

    // Inisialisasi state untuk setiap siswa
    for (var siswa in daftarSiswa) {
      statusAbsensi[siswa.uid] = 'H'; // Default semua Hadir
      keteranganControllers[siswa.uid] = TextEditingController();
    }
    totalSiswa.value = daftarSiswa.length;
  }

  Future<void> _fetchAbsensiHariIni() async {
    final docRef = _getAbsensiDocRef();
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final Map<String, dynamic> siswaAbsen = data['siswa'] ?? {};
      
      siswaAbsen.forEach((uid, detail) {
        if (statusAbsensi.containsKey(uid)) {
          statusAbsensi[uid] = detail['status'];
          keteranganControllers[uid]?.text = detail['keterangan'] ?? '';
        }
      });
      catatanHarianC.text = data['catatanHarian'] ?? '';
    }
  }

  void setStatusAbsensi(String uid, String status) {
    if (statusAbsensi[uid] == status) {
      statusAbsensi[uid] = 'H'; // Jika tombol yang sama ditekan lagi, kembalikan ke Hadir
    } else {
      statusAbsensi[uid] = status;
    }
    _calculateRekap();
  }

  void _calculateRekap() {
    int hadir = 0, sakit = 0, izin = 0, alfa = 0;
    statusAbsensi.forEach((uid, status) {
      switch (status) {
        case 'H': hadir++; break;
        case 'S': sakit++; break;
        case 'I': izin++; break;
        case 'A': alfa++; break;
      }
    });
    totalHadir.value = hadir;
    totalSakit.value = sakit;
    totalIzin.value = izin;
    totalAlfa.value = alfa;
  }

  Future<void> simpanAbsensi() async {
    isSaving.value = true;
    try {
      final docRef = _getAbsensiDocRef();
      final Map<String, dynamic> siswaData = {};
      
      statusAbsensi.forEach((uid, status) {
        if (status != 'H') {
          siswaData[uid] = {
            'status': status,
            'keterangan': keteranganControllers[uid]?.text.trim() ?? '',
            'nama': daftarSiswa.firstWhere((s) => s.uid == uid).nama,
          };
        }
      });

      await docRef.set({
        'tanggal': Timestamp.now(),
        // --- [FIX] Ambil UID dari sumber yang benar ---
        'idWaliKelas': authC.auth.currentUser!.uid, 
        'namaWaliKelas': configC.infoUser['nama'],
        'rekap': {
          'hadir': totalHadir.value, 'sakit': totalSakit.value,
          'izin': totalIzin.value, 'alfa': totalAlfa.value,
        },
        'catatanHarian': catatanHarianC.text.trim(),
        'siswa': siswaData,
      });

      Get.back();
      Get.snackbar("Berhasil", "Data absensi untuk hari ini telah disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) { Get.snackbar("Error", "Gagal menyimpan absensi: $e"); } 
    finally { isSaving.value = false; }
  }

  DocumentReference _getAbsensiDocRef() {
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('kelastahunajaran').doc(kelasDiampu)
        .collection('semester').doc(configC.semesterAktif.value)
        .collection('absensi').doc(tanggalHariIni);
  }

  @override
  void onClose() {
    catatanHarianC.dispose();
    keteranganControllers.forEach((_, controller) => controller.dispose());
    super.onClose();
  }
}