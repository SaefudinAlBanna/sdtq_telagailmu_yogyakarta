import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';

class LaporanHalaqahController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // State Utama & Pencarian (Mode Siswa)
  final RxBool isLoadingSiswa = true.obs;
  final searchC = TextEditingController();
  final searchQuery = "".obs;
  final RxList<Map<String, dynamic>> semuaSiswa = <Map<String, dynamic>>[].obs;

  // [BARU] State untuk Mode Grup
  final RxBool isLoadingGrup = true.obs;
  final RxList<Map<String, dynamic>> daftarGrup = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> grupTerpilih = Rxn<Map<String, dynamic>>();
  final RxBool isDetailGrupLoading = false.obs;
  final RxList<Map<String, dynamic>> anggotaGrupTerpilih = <Map<String, dynamic>>[].obs;

  // [BARU] State untuk beralih mode
  final RxBool isModePerGrup = false.obs;
  
  // Computed property untuk memfilter siswa
  List<Map<String, dynamic>> get filteredSiswa {
    if (searchQuery.value.isEmpty) return semuaSiswa;
    return semuaSiswa.where((siswa) {
      final query = searchQuery.value.toLowerCase();
      return (siswa['namaLengkap'] as String? ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    searchC.addListener(() => searchQuery.value = searchC.text);
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Jalankan kedua fetch secara paralel
    await Future.wait([
      _fetchSemuaSiswa(),
      _fetchDaftarGrup(),
    ]);
  }
  
  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }

  Future<void> _fetchSemuaSiswa() async {
    isLoadingSiswa.value = true;
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').orderBy('namaLengkap').get();
      semuaSiswa.assignAll(snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList());
    } catch (e) { Get.snackbar("Error", "Gagal memuat data siswa: $e");
    } finally { isLoadingSiswa.value = false; }
  }

  Future<void> _fetchDaftarGrup() async {
    isLoadingGrup.value = true;
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('halaqah_grup').orderBy('namaGrup').get();
      daftarGrup.assignAll(snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
    } catch (e) { Get.snackbar("Error", "Gagal memuat daftar grup: $e");
    } finally { isLoadingGrup.value = false; }
  }

  Future<void> onGrupChanged(Map<String, dynamic>? grup) async {
    if (grup == null) {
      grupTerpilih.value = null;
      anggotaGrupTerpilih.clear();
      return;
    }
    
    grupTerpilih.value = grup;
    isDetailGrupLoading.value = true;
    try {
      // Ambil UID semua anggota dari subkoleksi
      final anggotaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('halaqah_grup').doc(grup['id']).collection('anggota').get();
      
      final List<String> anggotaUids = anggotaSnapshot.docs.map((doc) => doc.id).toList();

      // Filter dari list semuaSiswa yang sudah ada untuk efisiensi reads
      anggotaGrupTerpilih.assignAll(semuaSiswa.where((siswa) => anggotaUids.contains(siswa['uid'])).toList());

    } catch (e) { Get.snackbar("Error", "Gagal memuat anggota grup: $e");
    } finally { isDetailGrupLoading.value = false; }
  }

  void toggleMode() {
    isModePerGrup.value = !isModePerGrup.value;
    // Reset pilihan grup jika kembali ke mode siswa
    if (!isModePerGrup.value) {
      grupTerpilih.value = null;
      anggotaGrupTerpilih.clear();
    }
  }
}



// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// import '../../../controllers/config_controller.dart';
// import '../../../models/santri_halaqah_laporan_model.dart';

// class LaporanHalaqahController extends GetxController with GetTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();

//   late TabController tabController;

//   // State UI
//   final isLoading = true.obs;
//   final isDetailLoading = false.obs;

//   // State Data
//   final RxList<Map<String, dynamic>> daftarGrup = <Map<String, dynamic>>[].obs;
//   final Rxn<Map<String, dynamic>> grupTerpilih = Rxn<Map<String, dynamic>>();
//   final RxString infoPengampu = "".obs;
//   final RxInt totalSetoranGrupBulanIni = 0.obs;
//   final RxList<SantriHalaqahLaporanModel> santriDiGrup = <SantriHalaqahLaporanModel>[].obs;

//   String get tahunAjaranAktif => configC.tahunAjaranAktif.value;

//   @override
//   void onInit() {
//     super.onInit();
//     tabController = TabController(length: 2, vsync: this);
//     _initializeData();
//   }

//   @override
//   void onClose() {
//     tabController.dispose();
//     super.onClose();
//   }

//   Future<void> _initializeData() async {
//     isLoading.value = true;
//     await _fetchDaftarGrup();
//     isLoading.value = false;
//   }

//   Future<void> _fetchDaftarGrup() async {
//     final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//       .collection('tahunajaran').doc(tahunAjaranAktif)
//       .collection('halaqah_grup').orderBy('namaGrup').get();
//     daftarGrup.value = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
//   }

//   Future<void> onGrupChanged(Map<String, dynamic> grup) async {
//     if (grupTerpilih.value?['id'] == grup['id']) return;
    
//     grupTerpilih.value = grup;
//     isDetailLoading.value = true;
//     infoPengampu.value = grup['namaPengampu'] ?? 'Belum diatur';
    
//     await _fetchLaporanDetailGrup(grup['id']);

//     isDetailLoading.value = false;
//   }

//   Future<void> _fetchLaporanDetailGrup(String idGrup) async {
//     try {
//       final anggotaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(tahunAjaranAktif)
//         .collection('halaqah_grup').doc(idGrup).collection('anggota').get();

//       List<Future<SantriHalaqahLaporanModel>> futures = [];
//       final now = DateTime.now();

//       for (var anggotaDoc in anggotaSnapshot.docs) {
//         // --- [PERBAIKAN] Gunakan field 'namaSiswa' sesuai dengan sumber data ---
//         final namaSantri = anggotaDoc.data()['namaSiswa'] as String? ?? 'Santri Dihapus';
//         futures.add(_processSantriData(anggotaDoc.id, namaSantri, now));
//         // --------------------------------------------------------------------
//       }
      
//       final List<SantriHalaqahLaporanModel> tempList = await Future.wait(futures);
      
//       totalSetoranGrupBulanIni.value = tempList.fold(0, (sum, item) => sum + item.totalSetoranBulanIni);
//       tempList.sort((a, b) => a.nama.compareTo(b.nama));
//       santriDiGrup.value = tempList;

//     } catch (e) {
//       print("Error di _fetchLaporanDetailGrup: $e");
//       Get.snackbar("Error", "Gagal memuat detail laporan grup: $e");
//     }
//   }
  
//   Future<SantriHalaqahLaporanModel> _processSantriData(String uid, String nama, DateTime now) async {
//     final setoranSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//         .collection('siswa').doc(uid).collection('halaqah_nilai')
//         .orderBy('tanggalSetoran', descending: true).get();
        
//     int setoranBulanIni = 0;
//     String setoranTerakhir = "Belum ada setoran";
//     DateTime? tanggalTerakhir;

//     if (setoranSnapshot.docs.isNotEmpty) {
//       final setoranTerbaru = setoranSnapshot.docs.first.data();
//       setoranTerakhir = "${setoranTerbaru['surah']} : ${setoranTerbaru['ayat']}";
//       tanggalTerakhir = (setoranTerbaru['tanggalSetoran'] as Timestamp).toDate();

//       for (var doc in setoranSnapshot.docs) {
//         final tanggalSetoran = (doc.data()['tanggalSetoran'] as Timestamp).toDate();
//         if (tanggalSetoran.year == now.year && tanggalSetoran.month == now.month) {
//           setoranBulanIni++;
//         }
//       }
//     }
    
//     return SantriHalaqahLaporanModel(
//       uid: uid,
//       nama: nama,
//       setoranTerakhir: setoranTerakhir,
//       tanggalSetoranTerakhir: tanggalTerakhir,
//       totalSetoranBulanIni: setoranBulanIni
//     );
//   }
// }