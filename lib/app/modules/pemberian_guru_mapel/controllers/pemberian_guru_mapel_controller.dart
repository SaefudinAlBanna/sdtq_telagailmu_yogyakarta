import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';
class PemberianGuruMapelController extends GetxController {
  final String idSekolah = 'P9984539';
  
  // --- State Management Reaktif ---
  late String namaKelas;
  late String idTahunAjaran;
  
  var isLoading = true.obs;
  var daftarGuru = <Map<String, String>>[].obs; // Menyimpan nama dan UID guru
  var daftarMapel = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    namaKelas = Get.arguments as String;
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      isLoading.value = true;
      await _fetchTahunAjaran();
      await Future.wait([
        _fetchDaftarGuru(),
        _fetchDaftarMapel(),
      ]);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data awal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // --- Fungsi-fungsi Fetching Data (Lebih Efisien) ---
  Future<void> _fetchTahunAjaran() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) throw Exception('Tahun Ajaran tidak ditemukan');
    idTahunAjaran = snapshot.docs.first.id;
  }

  Future<void> _fetchDaftarGuru() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Sekolah').doc(idSekolah).collection('pegawai')
        .where('role', whereIn: ['Pengampu', 'Guru Kelas']).get();
    
    final guruList = snapshot.docs.map((doc) => {
      'uid': doc.id,
      'nama': doc.data()['alias'] as String? ?? 'Tanpa Nama',
    }).toList();
    
    daftarGuru.assignAll(guruList);
  }
  
  Future<void> _fetchDaftarMapel() async {
     final snapshot = await FirebaseFirestore.instance
        .collection('Sekolah').doc(idSekolah).collection('matapelajaran')
        .get();
     daftarMapel.assignAll(snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- Stream untuk Mendapatkan Mapel yang Sudah Dipilih (Real-time) ---
  Stream<QuerySnapshot<Map<String, dynamic>>> getAssignedMapelStream() {
    return FirebaseFirestore.instance
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelasmapel').doc(namaKelas)
        .collection('matapelajaran')
        .snapshots();
  }

  // --- Fungsi Aksi (Lebih Aman dengan WriteBatch) ---
  // Future<void> assignGuruToMapel(String idGuru, String namaGuru, String namaMapel) async {
  //   try {
  //     Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

  //     WriteBatch batch = FirebaseFirestore.instance.batch();
      
  //     // 1. Path utama ke dokumen mapel di dalam kelas
  //     final docRef = FirebaseFirestore.instance
  //         .collection('Sekolah').doc(idSekolah)
  //         .collection('tahunajaran').doc(idTahunAjaran)
  //         .collection('kelasmapel').doc(namaKelas)
  //         .collection('matapelajaran').doc(namaMapel);

  //     // Cek apakah sudah ada guru untuk mapel ini
  //     final docSnap = await docRef.get();
  //     if (docSnap.exists) {
  //       throw Exception('Mata pelajaran ini sudah memiliki guru.');
  //     }

  //     // 2. Siapkan data untuk ditulis
  //     final data = {
  //       'namamatapelajaran': namaMapel,
  //       'guru': namaGuru,
  //       'idGuru': idGuru,
  //       'idKelas': namaKelas,
  //       'idTahunAjaran': idTahunAjaran,
  //       'diinputPada': Timestamp.now(),
  //     };
      
  //     // Tambahkan operasi tulis ke batch
  //     batch.set(docRef, data);

  //     // (Opsional) Jika Anda masih perlu menulis di tempat lain, tambahkan di sini
  //     // contoh: final guruRef = ...; batch.update(guruRef, {...});
      
  //     // 3. Commit batch (semua operasi tulis terjadi bersamaan)
  //     await batch.commit();
      
  //     Get.back(); // Tutup dialog loading
  //     Get.snackbar('Berhasil', '$namaMapel telah diberikan kepada $namaGuru');
  //   } catch (e) {
  //     Get.back(); // Tutup dialog loading
  //     Get.snackbar('Gagal', e.toString().replaceAll('Exception: ', ''));
  //   }
  // }

  Future<void> assignGuruToMapel(String idGuru, String namaGuru, String namaMapel) async {
  try {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    WriteBatch batch = FirebaseFirestore.instance.batch();
    
    // ================== PATH PERTAMA (TETAP SAMA) ==================
    // Path ke: /kelasmapel/{namaKelas}/matapelajaran/{namaMapel}
    final kelasMapelRef = FirebaseFirestore.instance
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelasmapel').doc(namaKelas)
        .collection('matapelajaran').doc(namaMapel);

    // Cek duplikasi sebelum melanjutkan
    final docSnap = await kelasMapelRef.get();
    if (docSnap.exists) {
      throw Exception('Mata pelajaran ini sudah memiliki guru.');
    }

    // ================== PATH KEDUA (YANG ANDA MINTA) ==================
    // Path ke: /pegawai/{idGuru}/tahunajaran/{idTahunAjaran}/kelasnya/{namaKelas}/matapelajaran/{namaMapel}
    final pegawaiMapelRef = FirebaseFirestore.instance
        .collection('Sekolah').doc(idSekolah)
        .collection('pegawai').doc(idGuru)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelasnya').doc(namaKelas)
        .collection('matapelajaran').doc(namaMapel);

    // Siapkan data yang akan ditulis. Bisa sama atau berbeda.
    // Kita gunakan data yang sama untuk konsistensi.
    final dataToSave = {
      'namamatapelajaran': namaMapel,
      'guru': namaGuru,
      'idGuru': idGuru,
      'idKelas': namaKelas,
      'idTahunAjaran': idTahunAjaran,
      'diinputPada': Timestamp.now(),
    };
    
    // --- Menambahkan kedua operasi tulis ke dalam satu batch ---
    batch.set(kelasMapelRef, dataToSave);   // Operasi 1
    batch.set(pegawaiMapelRef, dataToSave); // Operasi 2
    
    // Commit batch: kedua operasi akan berhasil, atau keduanya akan gagal.
    await batch.commit();
    
    Get.back(); // Tutup dialog loading
    Get.snackbar('Berhasil', '$namaMapel telah diberikan kepada $namaGuru');
  } catch (e) {
    Get.back(); // Tutup dialog loading
    Get.snackbar('Gagal', e.toString().replaceAll('Exception: ', ''));
  }
}

  // Future<void> removeGuruFromMapel(String namaMapel) async {
  //   try {
  //     Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
  //     // Path ke dokumen yang akan dihapus
  //     final docRef = FirebaseFirestore.instance
  //         .collection('Sekolah').doc(idSekolah)
  //         .collection('tahunajaran').doc(idTahunAjaran)
  //         .collection('kelasmapel').doc(namaKelas)
  //         .collection('matapelajaran').doc(namaMapel);

  //     await docRef.delete();
      
  //     Get.back();
  //     Get.snackbar('Berhasil', 'Guru untuk $namaMapel telah dihapus');
  //   } catch (e) {
  //     Get.back();
  //     Get.snackbar('Gagal', 'Gagal menghapus: $e');
  //   }
  // }

  Future<void> removeGuruFromMapel(String namaMapel) async {
  try {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    // ================== PATH PERTAMA (SAMA SEPERTI SEBELUMNYA) ==================
    // Path ke: /kelasmapel/{namaKelas}/matapelajaran/{namaMapel}
    final kelasMapelRef = FirebaseFirestore.instance
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelasmapel').doc(namaKelas)
        .collection('matapelajaran').doc(namaMapel);

    // --- LOGIKA BARU: BACA DULU UNTUK DAPATKAN ID GURU ---
    final doc = await kelasMapelRef.get();
    if (!doc.exists) {
      // Jika dokumennya tidak ada, anggap sudah terhapus dan hentikan proses.
      Get.back();
      Get.snackbar("Info", "Data sudah tidak ditemukan.",
          backgroundColor: Colors.yellow, colorText: Colors.black);
      return;
    }
    
    // Ambil idGuru dari data yang ada
    final String? idGuru = doc.data()?['idGuru'] as String?;
    if (idGuru == null) {
      // Ini sebagai pengaman jika data tidak konsisten
      throw Exception('ID Guru tidak ditemukan, tidak bisa menghapus data terkait.');
    }

    // ================== PATH KEDUA (YANG DIBUTUHKAN UNTUK HAPUS) ==================
    // Path ke: /pegawai/{idGuru}/.../matapelajaran/{namaMapel}
    final pegawaiMapelRef = FirebaseFirestore.instance
        .collection('Sekolah').doc(idSekolah)
        .collection('pegawai').doc(idGuru)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelasnya').doc(namaKelas)
        .collection('matapelajaran').doc(namaMapel);

    // Gunakan WriteBatch untuk penghapusan atomik
    WriteBatch batch = FirebaseFirestore.instance.batch();

    batch.delete(kelasMapelRef);   // Operasi 1: Hapus dari kelasmapel
    batch.delete(pegawaiMapelRef); // Operasi 2: Hapus dari data pegawai

    // Commit batch untuk menghapus keduanya secara bersamaan
    await batch.commit();

    Get.back();
    Get.snackbar('Berhasil', 'Guru untuk $namaMapel telah dihapus dari semua lokasi terkait.');
  } catch (e) {
    Get.back();
    Get.snackbar('Gagal', e.toString().replaceAll('Exception: ', ''));
  }
}
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';

// class PemberianGuruMapelController extends GetxController {
//   var argumenKelas = Get.arguments;

//   TextEditingController idPegawaiC = TextEditingController();
//   TextEditingController guruMapelC = TextEditingController();

//   FirebaseAuth auth = FirebaseAuth.instance;
//   FirebaseFirestore firestore = FirebaseFirestore.instance;

//   String idUser = FirebaseAuth.instance.currentUser!.uid;
//   String idSekolah = 'P9984539';
//   String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

//   Future<String> getTahunAjaranTerakhir() async {
//     CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran');
//     QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
//         await colTahunAjaran.get();
//     List<Map<String, dynamic>> listTahunAjaran =
//         snapshotTahunAjaran.docs.map((e) => e.data()).toList();
//     String tahunAjaranTerakhir =
//         listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
//     return tahunAjaranTerakhir;
//   }

//   Future<List<String>> getDataGuruMapel() async {
//     List<String> guruPengajar = [];

//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     QuerySnapshot<Map<String, dynamic>> snapKelas =
//         await firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('tahunajaran')
//             .doc(idTahunAjaran)
//             .collection('kelastahunajaran')
//             .get();

//     // String namaGuruMapel =
//     //     snapKelas.docs.isNotEmpty
//     //         ? snapKelas.docs.first.data()['walikelas']
//     //         : '';

//     await firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('pegawai')
//         // .where('alias', isNotEqualTo: namaGuruMapel)
//         .get()
//         .then((querySnapshot) {
//           for (var docSnapshot in querySnapshot.docs.where(
//             (doc) => doc['role'] == 'Pengampu' || doc['role'] == "Guru Kelas",
//           )) {
//             guruPengajar.add(docSnapshot.data()['alias']);
//           }
//         });
//     return guruPengajar;
//   }

//   Future<QuerySnapshot<Map<String, dynamic>>> tampilkanMapel() async {
//     try {
//       return await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('matapelajaran')
//           .get();
//     } catch (e) {
//       throw Exception(
//         'Data Matapelajaran tidak bisa diakses, silahkan ulangi lagi',
//       );
//     }
//   }

//   // final _streamController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
//   // Stream<QuerySnapshot<Map<String, dynamic>>> get stream => _streamController.stream;

//   Future<void> simpanMapel(String namaMapel) async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
//     String kelasNya = argumenKelas.substring(0, 1);
//     String faseNya =
//         (kelasNya == '1' || kelasNya == '2')
//             ? "Fase A"
//             : (kelasNya == '3' || kelasNya == '4')
//             ? "Fase B"
//             : "Fase C";

//     QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok =
//         await firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('pegawai')
//             .where('alias', isEqualTo: guruMapelC.text)
//             .get();
//     if (querySnapshotKelompok.docs.isNotEmpty) {
//       Map<String, dynamic> dataGuru = querySnapshotKelompok.docs.first.data();
//       String idGuru = dataGuru['uid'];

//       CollectionReference<Map<String, dynamic>> colKelasAktif = firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelasaktif');

//       // DocumentReference<Map<String, dynamic>> docKelasAktif = colKelasAktif.doc(argumenKelas);

//       QuerySnapshot<Map<String, dynamic>> snapKelasAktif =
//           await colKelasAktif.where('namakelas', isEqualTo: argumenKelas).get();
//       if (snapKelasAktif.docs.isEmpty) {
//         Get.snackbar(
//           "Error",
//           "Kelas tidak ditemukan. silahkan input kelas dulu",
//         );
//         // throw Exception('Kelas tidak ditemukan');
//       }

//       CollectionReference<Map<String, dynamic>> colMapelKelas = firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelasmapel')
//           .doc(argumenKelas)
//           .collection('matapelajaran');

//       DocumentReference<Map<String, dynamic>> docMapel = colMapelKelas.doc(
//         namaMapel,
//       );

//       QuerySnapshot<Map<String, dynamic>> snapMapel =
//           await colMapelKelas
//               .where('namamatapelajaran', isEqualTo: namaMapel)
//               .get();
//       if (snapMapel.docs.isNotEmpty) {
//         // Jika ada dokumen dengan namaMapel yang sama, tampilkan pesan error
//         Get.snackbar("Error", "Mata pelajaran dengan nama ini sudah ada.");
//         return;
//       } else {
//         // Jika tidak ada dokumen dengan namaMapel yang sama, simpan data

//         DocumentReference<Map<String, dynamic>> docTahunAjaranGuru = firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('pegawai')
//             .doc(idGuru)
//             .collection('tahunajaran')
//             .doc(idTahunAjaran);

//         DocumentSnapshot<Map<String, dynamic>> snapTahunAjaranGuru =
//             await docTahunAjaranGuru.get();
//         if (snapTahunAjaranGuru.exists) {
//           // Map<String , dynamic> dataTahunAjaranGuru = snapTahunAjaranGuru.data();
//           // dataTahunAjaranGuru['mapel'] = FieldValue.arrayUnion([nama Mapel]);
//           await docTahunAjaranGuru.update({
//             'tahunajaran': tahunajaranya,
//             'emailpenginputMapel': emailAdmin,
//             'idpenginputMapel': idUser,
//           });
//         } else {
//           // Map<String , dynamic> dataTahunAjaranGuru = {
//           //   'mapel' : [namaMapel]
//           await docTahunAjaranGuru.set({
//             'tahunajaran': tahunajaranya,
//             'emailpenginputMapel': emailAdmin,
//             'idpenginputMapel': idUser,
//           });
//         }
//         // Simpan data disini
//         // await firestore
//         //     .collection('Sekolah')
//         //     .doc(idSekolah)
//         //     .collection('pegawai')
//         //     .doc(idGuru)
//         //     .collection('tahunajaran')
//         //     .doc(idTahunAjaran)
//         //     .update({
//         //       'tahunajaran': tahunajaranya,
//         //       'emailpenginputMapel': emailAdmin,
//         //       'idpenginputMapel': idUser,
//         //     });



//         DocumentReference<Map<String, dynamic>> docGuruKelas = firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('pegawai')
//             .doc(idGuru)
//             .collection('tahunajaran')
//             .doc(idTahunAjaran)
//             .collection('kelasnya')
//             .doc(argumenKelas);

//             DocumentSnapshot<Map<String, dynamic>> snapGuruKelas = await docGuruKelas.get();
//         if (snapGuruKelas.exists) {
//           // Map<String , dynamic> dataTahunAjaranGuru = snapTahunAjaranGuru.data();
//           // dataTahunAjaranGuru['mapel'] = FieldValue.arrayUnion([nama Mapel]);
//           await docGuruKelas.update({
//             'tahunajaran': tahunajaranya,
//           'emailpenginputMapel': emailAdmin,
//           'idpenginputMapel': idUser,
//           'fase': faseNya,
//           });
//         } else {
//           // Map<String , dynamic> dataTahunAjaranGuru = {
//           //   'mapel' : [namaMapel]
//           await docGuruKelas.set({
//             'tahunajaran': tahunajaranya,
//           'emailpenginputMapel': emailAdmin,
//           'idpenginputMapel': idUser,
//           'fase': faseNya,
//           });
//         }

//         // colGuru.doc(argumenKelas).update({
//         //   'tahunajaran': tahunajaranya,
//         //   'emailpenginputMapel': emailAdmin,
//         //   'idpenginputMapel': idUser,
//         //   'fase': faseNya,
//         // });

//         DocumentReference<Map<String, dynamic>> docGuruKelasMapel = docGuruKelas.collection('matapelajaran').doc(namaMapel);

//         DocumentSnapshot<Map<String, dynamic>> snapGuruKelasMapel = await docGuruKelasMapel.get();

//         if (snapGuruKelasMapel.exists) {
//           // Map<String , dynamic> dataTahunAjaranGuru = snapTahunAjaranGuru.data();
//           // dataTahunAjaranGuru['mapel'] = FieldValue.arrayUnion([nama Mapel]);
//           await docGuruKelas.update({
//               'tahunajaran': tahunajaranya,
//               'emailpenginputMapel': emailAdmin,
//               'idpenginputMapel': idUser,
//               'namaMapel': namaMapel,
//               'idKelas': argumenKelas,
//               'idSekolah': idSekolah,
//               'idGuru': idGuru,
//               'idTahunAjaran': idTahunAjaran,
//               'fase': faseNya,
//           });
//         } else {
//           // Map<String , dynamic> dataTahunAjaranGuru = {
//           //   'mapel' : [namaMapel]
//           await docGuruKelas.set({
//               'tahunajaran': tahunajaranya,
//               'emailpenginputMapel': emailAdmin,
//               'idpenginputMapel': idUser,
//               // 'namaMapel': namaMapel,
//               'idKelas': argumenKelas,
//               'idSekolah': idSekolah,
//               'idGuru': idGuru,
//               'idTahunAjaran': idTahunAjaran,
//               'fase': faseNya,
//           });
//         }

//         docGuruKelasMapel.set({
//           'tahunajaran': tahunajaranya,
//               'emailpenginputMapel': emailAdmin,
//               'idpenginputMapel': idUser,
//               'namaMapel': namaMapel,
//               'idKelas': argumenKelas,
//               'idSekolah': idSekolah,
//               'idGuru': idGuru,
//               'idTahunAjaran': idTahunAjaran,
//               'fase': faseNya,
//         });

//         // colGuruk
//         //     .doc(argumenKelas)
//         //     .collection('matapelajaran')
//         //     .doc(namaMapel)
//         //     .update({
//         //       'tahunajaran': tahunajaranya,
//         //       'emailpenginputMapel': emailAdmin,
//         //       'idpenginputMapel': idUser,
//         //       'namaMapel': namaMapel,
//         //       'idKelas': argumenKelas,
//         //       'idSekolah': idSekolah,
//         //       'idGuru': idGuru,
//         //       'idTahunAjaran': idTahunAjaran,
//         //       'fase': faseNya,
//         //     });

//         docMapel.set({
//           'fase': faseNya,
//           'namamatapelajaran': namaMapel,
//           'guru': guruMapelC.text,
//           'idGuru': idGuru,
//           'idSekolah': idSekolah,
//           'idTahunAjaran': idTahunAjaran,
//           'idKelas': argumenKelas,
//           'idMapel': namaMapel,
//           // 'idSiswa': '',
//           // 'idGuruMapel': '',
//           'status': 'aktif',
//           'idPenginputMapel': idUser,
//           'tanggalinputMapel': DateTime.now().toIso8601String(),
//           // 'updateinput': DateTime.now().toIso8601String(),
//         });

//         firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('tahunajaran')
//             .doc(idTahunAjaran)
//             .collection('kelasmapel')
//             .doc(argumenKelas)
//             .set({
//               'tahunajaran': tahunajaranya,
//               'emailpenginputMapel': emailAdmin,
//               'idpenginputMapel': idUser,
//               'fase': faseNya,
//               'tanggalinputMapel': DateTime.now().toIso8601String(),
//               'namakelas': argumenKelas,
//             });

//         colMapelKelas.doc(namaMapel).set({
//           'fase': faseNya,
//           'namamatapelajaran': namaMapel,
//           'guru': guruMapelC.text,
//           'idGuru': idGuru,
//           'idSekolah': idSekolah,
//           'idTahunAjaran': idTahunAjaran,
//           'idKelas': argumenKelas,
//           'idMapel': namaMapel,
//           'status': 'aktif',
//           'idPenginputMapel': idUser,
//           'tanggalinputMapel': DateTime.now().toIso8601String(),
//           // 'updateinput': DateTime.now().toIso8601String(),
//         });

//         Get.snackbar("Berhasil", "Mata pelajaran berhasil disimpan.");
//         // tampilkan();
//       }
//     }
//   }

//   Future<void> refreshTampilan() async {
//     tampilkan();
//   }

//   Stream<QuerySnapshot<Map<String, dynamic>>> tampilkan() async* {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     yield* firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         .collection('kelasmapel')
//         .doc(argumenKelas)
//         .collection('matapelajaran')
//         .snapshots();
//   }
// }
