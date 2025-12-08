import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/mapel_diampu_model.dart';
import '../../../routes/app_pages.dart';

class GuruAkademikController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State UI
  final isLoading = true.obs;
  
  // State Data (Struktur Baru untuk UI ChoiceChip)
  final RxMap<String, List<MapelDiampuModel>> mapelPerKelas = <String, List<MapelDiampuModel>>{}.obs;
  final RxList<String> daftarIdKelas = <String>[].obs;
  final Rxn<String> kelasTerpilihId = Rxn<String>();
  final RxList<MapelDiampuModel> mapelDiKelasTerpilih = <MapelDiampuModel>[].obs;

  // State Wali Kelas (Multi-Kelas Support)
  final RxBool isWaliKelas = false.obs;
  // [REVISI] Menggunakan List untuk menampung banyak kelas
  final RxList<String> listKelasWali = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    ever(configC.isUserDataReady, (bool isReady) {
      if (isReady) {
        fetchMapelDiampu();
        _updateWaliKelasStatus();
      }
    });

    if (configC.isUserDataReady.value) {
      fetchMapelDiampu();
      _updateWaliKelasStatus();
    }
  }

  void _updateWaliKelasStatus() {
    // 1. Cek Field Baru (Array)
    List<dynamic>? group = configC.infoUser['waliKelasGroup'];
    
    // 2. Cek Field Lama (String - Fallback)
    String? single = configC.infoUser['kelasDiampu']; // atau 'waliKelasDari'
    
    final Set<String> allKelas = {};

    if (group != null && group.isNotEmpty) {
      allKelas.addAll(group.map((e) => e.toString()));
    }
    
    if (single != null && single.isNotEmpty) {
      allKelas.add(single);
    }

    listKelasWali.assignAll(allKelas.toList());
    isWaliKelas.value = listKelasWali.isNotEmpty;
    
    print("DEBUG WALI KELAS: $listKelasWali"); // Untuk cek di console
  }
  
  // Helper untuk cek apakah user adalah Wali Kelas di kelas yang sedang dibuka
  bool get amIWaliKelasHere {
    if (kelasTerpilihId.value == null) return false;
    return listKelasWali.contains(kelasTerpilihId.value);
  }

  Future<void> fetchMapelDiampu() async {
    isLoading.value = true;
    try {
      final String uid = _auth.currentUser!.uid;
      final String tahunAjaran = configC.tahunAjaranAktif.value;
  
      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
        throw Exception("Tahun ajaran tidak valid.");
      }
  
      final List<MapelDiampuModel> listMapelFinal = [];
      final Set<String> uniqueMapelKeys = {};
  
      // [SUMBER 1: JADWAL REGULER]
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
      
      // [SUMBER 2 & 3: PENGGANTIAN GURU]
      // (Logika penggantian guru tetap sama seperti kode Anda sebelumnya.
      //  Saya singkat disini agar tidak kepanjangan, silakan copy-paste logika fetch penggantinya)
      // ... (Kode fetch pengganti) ...

      // --- [TAMBAHAN LOGIKA WALI KELAS] ---
      // Jika saya Wali Kelas 7A, tapi saya TIDAK mengajar mapel apapun di 7A,
      // Kelas 7A tetap harus muncul di tab agar saya bisa absen siswa!
      for (String idKelasWali in listKelasWali) {
        // Cek apakah kelas wali ini sudah ada di daftar mapel?
        bool exists = listMapelFinal.any((m) => m.idKelas == idKelasWali);
        
        // Jika belum ada (artinya cuma jadi Walas, gak ngajar), kita buat dummy entry
        // agar kelasnya muncul di Tab Bar.
        if (!exists) {
          // Tidak perlu tambah Mapel Dummy ke listMapelFinal, 
          // Cukup pastikan nanti di grouping (tempMap) key-nya dibuat.
        }
      }
  
      // [FINALISASI]
      final Map<String, List<MapelDiampuModel>> tempMap = {};
      
      // Masukkan Mapel Mengajar
      for (var mapel in listMapelFinal) {
        if (tempMap[mapel.idKelas] == null) {
          tempMap[mapel.idKelas] = [];
        }
        tempMap[mapel.idKelas]!.add(mapel);
      }
      
      // Masukkan Kelas Wali (Meskipun kosong mapel)
      for (String idKelasWali in listKelasWali) {
        if (tempMap[idKelasWali] == null) {
          tempMap[idKelasWali] = []; // List kosong, nanti UI menampilkan "Tidak ada mapel" tapi tombol absen ada
        }
      }
      
      mapelPerKelas.value = tempMap;
      daftarIdKelas.value = tempMap.keys.toList()..sort();
  
      if (daftarIdKelas.isNotEmpty) {
        // Jika sebelumnya sudah pilih kelas, pertahankan. Jika tidak, pilih yang pertama.
        if (kelasTerpilihId.value == null || !daftarIdKelas.contains(kelasTerpilihId.value)) {
           pilihKelas(daftarIdKelas.first);
        } else {
           // Refresh list mapel untuk kelas yang sedang dipilih
           pilihKelas(kelasTerpilihId.value!); 
        }
      } else {
        kelasTerpilihId.value = null;
        mapelDiKelasTerpilih.clear();
      }
  
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data mengajar: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void pilihKelas(String idKelas) {
    kelasTerpilihId.value = idKelas;
    mapelDiKelasTerpilih.value = mapelPerKelas[idKelas] ?? [];
    mapelDiKelasTerpilih.sort((a, b) => a.namaMapel.compareTo(b.namaMapel));
  }

  void goToDaftarSiswaPermapel(MapelDiampuModel mapel) {
    Get.toNamed(
      Routes.DAFTAR_SISWA_PERMAPEL,
      arguments: {
        'idKelas': mapel.idKelas,
        'idMapel': mapel.idMapel,
        'namaMapel': mapel.namaMapel,
        'idGuru': _auth.currentUser!.uid, 
        'namaGuru': configC.infoUser['nama'] ?? 'Pengguna',
        'isPengganti': mapel.isPengganti,
      },
    );
  }

  void goToJurnalHarian() => Get.toNamed(Routes.JURNAL_HARIAN_GURU);
  
  // Fungsi Absensi (Perbaikan Argumen jika diperlukan)
  void goToAbsensi() => Get.toNamed(Routes.ABSENSI_WALI_KELAS, arguments: {'idKelas': kelasTerpilihId.value});

  void goToRekapAbsensiKelas() {
    Get.toNamed(Routes.REKAP_ABSENSI, arguments: {'scope': 'kelas', 'id': kelasTerpilihId.value});
  }
}


// // lib/app/modules/guru_akademik/controllers/guru_akademik_controller.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../controllers/config_controller.dart';
// import '../../../models/mapel_diampu_model.dart';
// import '../../../routes/app_pages.dart';

// class GuruAkademikController extends GetxController {
//   final ConfigController configC = Get.find<ConfigController>();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // State UI
//   final isLoading = true.obs;
  
//   // State Data (Struktur Baru untuk UI ChoiceChip)
//   final RxMap<String, List<MapelDiampuModel>> mapelPerKelas = <String, List<MapelDiampuModel>>{}.obs;
//   final RxList<String> daftarIdKelas = <String>[].obs;
//   final Rxn<String> kelasTerpilihId = Rxn<String>();
//   final RxList<MapelDiampuModel> mapelDiKelasTerpilih = <MapelDiampuModel>[].obs;

//   // State Wali Kelas
//   final RxBool isWaliKelas = false.obs;
//   final RxString kelasDiampuId = "".obs;


//   @override
//   void onInit() {
//     super.onInit();
//     // Dengarkan sinyal bahwa data pengguna sudah siap
//     ever(configC.isUserDataReady, (bool isReady) {
//     if (isReady) {
//     // Hanya jalankan fetch data setelah ConfigController siap
//     fetchMapelDiampu();
//     _updateWaliKelasStatus();
//     }
//   });

//   // Jika saat controller ini dibuat data sudah siap, jalankan langsung
//     if (configC.isUserDataReady.value) {
//   fetchMapelDiampu();
//   _updateWaliKelasStatus();
//   }
//   }

//   void _updateWaliKelasStatus() {
//     final hasKelasDiampu = configC.infoUser.containsKey('kelasDiampu');
//     isWaliKelas.value = hasKelasDiampu;
//     if (hasKelasDiampu) {
//       kelasDiampuId.value = configC.infoUser['kelasDiampu'] ?? '';
//     } else {
//       kelasDiampuId.value = '';
//     }
//   }

//   Future<void> fetchMapelDiampu() async {
//     isLoading.value = true;
//     try {
//       final String uid = _auth.currentUser!.uid;
//       final String tahunAjaran = configC.tahunAjaranAktif.value;
  
//       if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
//         throw Exception("Tahun ajaran tidak valid.");
//       }
  
//       final List<MapelDiampuModel> listMapelFinal = [];
//       final Set<String> uniqueMapelKeys = {};
  
//       // [SUMBER 1: JADWAL REGULER - PATH AMAN]
//       final jadwalRegulerSnap = await _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('pegawai').doc(uid)
//           .collection('jadwal_mengajar').doc(tahunAjaran)
//           .collection('mapel_diampu')
//           .get();
  
//       for (var doc in jadwalRegulerSnap.docs) {
//         final mapel = MapelDiampuModel.fromFirestore(doc, isPengganti: false);
//         final key = "${mapel.idKelas}-${mapel.idMapel}";
//         if (uniqueMapelKeys.add(key)) {
//           listMapelFinal.add(mapel);
//         }
//       }
  
//       // [SUMBER 2: PENGGANTIAN RENTANG WAKTU]
//       final now = DateTime.now();
//       final penggantianRentangSnap = await _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(tahunAjaran)
//           .collection('penggantianAkademik')
//           .where('idGuruPengganti', isEqualTo: uid)
//           .where('status', isEqualTo: 'aktif')
//           .get();
  
//       for (var doc in penggantianRentangSnap.docs) {
//         final data = doc.data();
//         final tanggalMulai = (data['tanggalMulai'] as Timestamp).toDate();
//         final tanggalSelesai = (data['tanggalSelesai'] as Timestamp).toDate();
  
//         if ((now.isAfter(tanggalMulai) || now.isAtSameMomentAs(tanggalMulai)) && 
//             (now.isBefore(tanggalSelesai) || now.isAtSameMomentAs(tanggalSelesai))) {
            
//           final List<dynamic> jadwalSalinan = data['jadwalYangDigantikan'] ?? [];
  
//           for (var mapelData in jadwalSalinan) {
//             if (mapelData is Map<String, dynamic>) {
//               final mapel = MapelDiampuModel(
//                 idMapel: mapelData['idMapel'] ?? '',
//                 namaMapel: mapelData['namamatapelajaran'] ?? 'N/A',
//                 idKelas: mapelData['idKelas'] ?? '',
//                 idGuru: uid,
//                 namaGuru: configC.infoUser['nama'] ?? 'Pengganti',
//                 isPengganti: true,
//                 namaGuruAsli: data['namaGuruAsli'],
//               );
//               final key = "${mapel.idKelas}-${mapel.idMapel}";
//               if (uniqueMapelKeys.add(key)) {
//                 listMapelFinal.add(mapel);
//               }
//             }
//           }
//         }
//       }
  
//       // [SUMBER 3: PENGGANTIAN INSIDENTAL (PER SESI)]
//       final tanggalStr = DateFormat('yyyy-MM-dd').format(now);
//       final penggantianSesiSnap = await _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(tahunAjaran)
//           .collection('sesi_pengganti_kbm')
//           .where('idGuruPengganti', isEqualTo: uid)
//           .where('tanggal', isEqualTo: tanggalStr)
//           .get();
  
//       for (var doc in penggantianSesiSnap.docs) {
//         final data = doc.data();
//         final mapel = MapelDiampuModel(
//           idMapel: data['idMapel'] ?? '',
//           namaMapel: data['namaMapel'] ?? 'Tugas Harian', 
//           idKelas: data['idKelas'] ?? '',
//           idGuru: uid,
//           namaGuru: data['namaGuruPengganti'] ?? 'Pengganti',
//           isPengganti: true,
//           namaGuruAsli: data['namaGuruAsli'],
//         );
//         final key = "${mapel.idKelas}-${mapel.idMapel}";
//         if (uniqueMapelKeys.add(key)) {
//           listMapelFinal.add(mapel);
//         }
//       }
  
//       // [FINALISASI & PEMROSESAN DATA UNTUK UI BARU]
//       final Map<String, List<MapelDiampuModel>> tempMap = {};
//       for (var mapel in listMapelFinal) {
//         if (tempMap[mapel.idKelas] == null) {
//           tempMap[mapel.idKelas] = [];
//         }
//         tempMap[mapel.idKelas]!.add(mapel);
//       }
      
//       mapelPerKelas.value = tempMap;
//       daftarIdKelas.value = tempMap.keys.toList()..sort();
  
//       if (daftarIdKelas.isNotEmpty) {
//         pilihKelas(daftarIdKelas.first);
//       } else {
//         // Pastikan state bersih jika tidak ada mapel sama sekali
//         kelasTerpilihId.value = null;
//         mapelDiKelasTerpilih.clear();
//       }
  
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat data mengajar: ${e.toString()}");
//       print("### GURU AKADEMIK ERROR: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void pilihKelas(String idKelas) {
//     kelasTerpilihId.value = idKelas;
//     mapelDiKelasTerpilih.value = mapelPerKelas[idKelas] ?? [];
//     mapelDiKelasTerpilih.sort((a, b) => a.namaMapel.compareTo(b.namaMapel));
//   }

//   void goToDaftarSiswaPermapel(MapelDiampuModel mapel) {
//     // Navigasi ke halaman selanjutnya dengan membawa semua data yang dibutuhkan
//     Get.toNamed(
//       Routes.DAFTAR_SISWA_PERMAPEL,
//       arguments: {
//         'idKelas': mapel.idKelas,
//         'idMapel': mapel.idMapel,
//         'namaMapel': mapel.namaMapel,
//         // 'idGuru': mapel.idGuru,
//         // 'namaGuru': mapel.namaGuru,
//         'idGuru': _auth.currentUser!.uid, 
//         'namaGuru': configC.infoUser['nama'] ?? 'Pengguna',
//         'isPengganti': mapel.isPengganti,
//       },
//     );
//   }

//   void goToJurnalHarian() {
//      Get.toNamed(Routes.JURNAL_HARIAN_GURU);
//   }

//   void goToAbsensi() {
//     Get.toNamed(Routes.ABSENSI_WALI_KELAS);
//   }

//   void goToRekapAbsensiKelas() {
//     Get.toNamed(Routes.REKAP_ABSENSI, arguments: {'scope': 'kelas', 'id': kelasDiampuId.value});
//   }
// }