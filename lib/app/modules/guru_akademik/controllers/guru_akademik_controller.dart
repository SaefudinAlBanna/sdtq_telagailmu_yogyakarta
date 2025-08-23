// lib/app/modules/guru_akademik/controllers/guru_akademik_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/mapel_diampu_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';

class GuruAkademikController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final isLoading = true.obs;
  final RxList<MapelDiampuModel> daftarMapelDiampu = <MapelDiampuModel>[].obs;

 final RxBool isWaliKelas = false.obs;
  // --- [DIUBAH] Gunakan RxString untuk nama kelas yang diampu ---
  final RxString kelasDiampuId = "".obs;

  @override
  void onInit() {
    super.onInit();
    // --- [BARU] Tambahkan listener untuk memantau perubahan pada infoUser ---
    // Ini akan dieksekusi setiap kali ConfigController selesai sinkronisasi
    ever(configC.infoUser, (_) => _updateWaliKelasStatus());
  }

  @override
  void onReady() {
    super.onReady();
    // onReady lebih aman karena menunggu ConfigController siap
    fetchMapelDiampu();
    _updateWaliKelasStatus();
  }

  void _updateWaliKelasStatus() {
    final hasKelasDiampu = configC.infoUser.containsKey('kelasDiampu');
    isWaliKelas.value = hasKelasDiampu;
    
    // --- [DEBUG 5] ---
    print(">> DEBUG AKADEMIK: Status Wali Kelas dicek. Hasil: $hasKelasDiampu");

    if (hasKelasDiampu) {
      kelasDiampuId.value = configC.infoUser['kelasDiampu'] ?? '';
    } else {
      kelasDiampuId.value = '';
    }
  }

  Future<void> fetchMapelDiampu() async {
    isLoading.value = true;
    try {
      final String uid = _auth.currentUser!.uid;
      final String tahunAjaran = configC.tahunAjaranAktif.value;

      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
        daftarMapelDiampu.clear();
        throw Exception("Tahun ajaran tidak valid.");
      }

      final List<MapelDiampuModel> listMapelFinal = [];
      final Set<String> uniqueMapelKeys = {};

      // [SUMBER 1: JADWAL REGULER]
      // Tidak ada perubahan di sini. Ini memastikan guru yang tidak digantikan tetap aman.
      final jadwalRegulerSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('pegawai').doc(uid)
          .collection('jadwal_mengajar').doc(tahunAjaran)
          .collection('mapel_diampu')
          .get();

      for (var doc in jadwalRegulerSnap.docs) {
        final mapel = MapelDiampuModel.fromFirestore(doc, isPengganti: false);
        final key = "${mapel.idKelas}-${mapel.idMapel}";
        if (uniqueMapelKeys.add(key)) {
          listMapelFinal.add(mapel);
        }
      }

      // [SUMBER 2: PENGGANTIAN RENTANG WAKTU]
      final now = DateTime.now();
      final penggantianRentangSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('penggantianAkademik')
          .where('idGuruPengganti', isEqualTo: uid)
          .where('status', isEqualTo: 'aktif')
          .get();

      for (var doc in penggantianRentangSnap.docs) {
        final data = doc.data();
        final tanggalMulai = (data['tanggalMulai'] as Timestamp).toDate();
        final tanggalSelesai = (data['tanggalSelesai'] as Timestamp).toDate();

        if ((now.isAfter(tanggalMulai) || now.isAtSameMomentAs(tanggalMulai)) && 
            (now.isBefore(tanggalSelesai) || now.isAtSameMomentAs(tanggalSelesai))) {
            
          final List<dynamic> jadwalSalinan = data['jadwalYangDigantikan'] ?? [];

          for (var mapelData in jadwalSalinan) {
            if (mapelData is Map<String, dynamic>) {
              final mapel = MapelDiampuModel(
                idMapel: mapelData['idMapel'] ?? '',
                namaMapel: mapelData['namamatapelajaran'] ?? 'N/A',
                idKelas: mapelData['idKelas'] ?? '',
                idGuru: uid,
                namaGuru: configC.infoUser['nama'] ?? 'Pengganti',
                isPengganti: true,
                // --- [PERBAIKAN KUNCI] Ambil namaGuruAsli dari dokumen mandat ---
                namaGuruAsli: data['namaGuruAsli'],
              );
              final key = "${mapel.idKelas}-${mapel.idMapel}";
              if (uniqueMapelKeys.add(key)) {
                listMapelFinal.add(mapel);
              }
            }
          }
        }
      }

      // [SUMBER 3: PENGGANTIAN INSIDENTAL (PER SESI)]
      final tanggalStr = DateFormat('yyyy-MM-dd').format(now);
      final penggantianSesiSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('sesi_pengganti_kbm')
          .where('idGuruPengganti', isEqualTo: uid)
          .where('tanggal', isEqualTo: tanggalStr)
          .get();

      for (var doc in penggantianSesiSnap.docs) {
        final data = doc.data();
        final mapel = MapelDiampuModel(
          idMapel: data['idMapel'] ?? '',
          // --- [PERBAIKAN KUNCI] Baca namaMapel dari dokumen sesi ---
          namaMapel: data['namaMapel'] ?? 'Tugas Harian', 
          idKelas: data['idKelas'] ?? '',
          idGuru: uid,
          namaGuru: data['namaGuruPengganti'] ?? 'Pengganti',
          isPengganti: true,
          // --- [PERBAIKAN KUNCI] Baca namaGuruAsli dari dokumen sesi ---
          namaGuruAsli: data['namaGuruAsli'],
        );
        final key = "${mapel.idKelas}-${mapel.idMapel}";
        if (uniqueMapelKeys.add(key)) {
          listMapelFinal.add(mapel);
        }
      }

      // [FINALISASI]
      listMapelFinal.sort((a, b) {
        int kelasCompare = a.idKelas.compareTo(b.idKelas);
        if (kelasCompare != 0) return kelasCompare;
        return a.namaMapel.compareTo(b.namaMapel);
      });

      daftarMapelDiampu.assignAll(listMapelFinal);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data mengajar: ${e.toString()}");
      print("### GURU AKADEMIK ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void goToDaftarSiswaPermapel(MapelDiampuModel mapel) {
    // Navigasi ke halaman selanjutnya dengan membawa semua data yang dibutuhkan
    Get.toNamed(
      Routes.DAFTAR_SISWA_PERMAPEL,
      arguments: {
        'idKelas': mapel.idKelas,
        'idMapel': mapel.idMapel,
        'namaMapel': mapel.namaMapel,
        // 'idGuru': mapel.idGuru,
        // 'namaGuru': mapel.namaGuru,
        'idGuru': _auth.currentUser!.uid, 
        'namaGuru': configC.infoUser['nama'] ?? 'Pengguna',
        'isPengganti': mapel.isPengganti,
      },
    );
  }

  void goToAbsensi() {
    Get.toNamed(Routes.ABSENSI_WALI_KELAS);
  }

  void goToRekapAbsensiKelas() {
    Get.toNamed(Routes.REKAP_ABSENSI, arguments: {'scope': 'kelas', 'id': kelasDiampuId.value});
  }
}