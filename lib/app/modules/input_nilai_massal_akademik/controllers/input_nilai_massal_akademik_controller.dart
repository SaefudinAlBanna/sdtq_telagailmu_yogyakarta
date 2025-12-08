import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/siswa_model.dart';
import '../../manajemen_tugas/controllers/manajemen_tugas_controller.dart';

class InputNilaiMassalAkademikController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController _authController = Get.find<AuthController>();

  // --- DATA KONTEKS DARI ARGUMEN ---
  late String idKelas;
  late String idMapel;
  late String namaMapel;
  late String judulTugas;
  late String kategoriTugas;
  String? idTugasUlangan; // Bisa null jika ini "Input Manual Bebas"

  // --- STATE UI ---
  final isLoading = true.obs;
  final isSaving = false.obs;

  // --- STATE DATA & FORM ---
  final daftarSiswa = <SiswaModel>[].obs;
  final filteredSiswa = <SiswaModel>[].obs;
  final textControllers = <String, TextEditingController>{}.obs;
  final absentStudents = <String>{}.obs;
  final searchController = TextEditingController();

  late String idGuruPencatat;
  late String namaGuruPencatat;
  late String aliasGuruPencatat;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    
    // Validasi Argumen Minimal
    if (args['idKelas'] == null || args['idMapel'] == null) {
      Get.snackbar("Error", "Data kelas atau mapel tidak valid.");
      isLoading.value = false;
      return;
    }

    idKelas = args['idKelas'];
    idMapel = args['idMapel'];
    namaMapel = args['namaMapel'] ?? 'Mapel Tanpa Nama';
    judulTugas = args['judulTugas'] ?? 'Tugas Harian';
    kategoriTugas = args['kategoriTugas'] ?? 'Harian/PR';
    idTugasUlangan = args['idTugasUlangan'];

    // Ambil Data Guru Pencatat (Yang Sedang Login)
    final currentUser = _authController.auth.currentUser;
    if (currentUser != null) {
      idGuruPencatat = currentUser.uid;
      namaGuruPencatat = configC.infoUser['nama'] ?? 'Guru';
      aliasGuruPencatat = configC.infoUser['alias'] ?? namaGuruPencatat;
    }

    searchController.addListener(() => filterSiswa(searchController.text));

    if (configC.isUserDataReady.value) {
      _fetchSiswaAndPrepareForm();
    } else {
      ever(configC.isUserDataReady, (isReady) {
        if (isReady) _fetchSiswaAndPrepareForm();
      });
    }
  }

  @override
  void onClose() {
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
      if (tahunAjaran.isEmpty) throw Exception("Tahun ajaran tidak aktif.");
  
      // 1. Ambil daftar siswa dari kelas (Optimized Query)
      final siswaSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('daftarsiswa')
          .orderBy('namaLengkap')
          .get();
      
      final allSiswa = siswaSnap.docs.map((doc) => 
          SiswaModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      
      daftarSiswa.assignAll(allSiswa);
      filteredSiswa.assignAll(allSiswa);
  
      if (daftarSiswa.isEmpty) {
        isLoading.value = false;
        return;
      }
  
      // 2. Siapkan text controller
      for (var siswa in daftarSiswa) {
        textControllers[siswa.uid] = TextEditingController();
      }
  
      // 3. LOGIKA POPULATE NILAI (PENTING!)
      // Jika ini adalah input untuk TUGAS TERTENTU (idTugasUlangan ada),
      // maka kita wajib mengambil nilai yang sudah pernah diinput sebelumnya (jika ada).
      if (idTugasUlangan != null) {
        // Kita gunakan 'Future.wait' agar semua request berjalan paralel (Lebih Cepat)
        final List<Future<void>> tasks = daftarSiswa.map((siswa) async {
          try {
            // Langsung tembak ke ID Dokumen (Deterministic ID)
            // Karena di simpanNilaiMassal kita pakai .doc(idTugasUlangan)
            final docRef = _firestore
                .collection('Sekolah').doc(configC.idSekolah)
                .collection('tahunajaran').doc(tahunAjaran)
                .collection('kelastahunajaran').doc(idKelas)
                .collection('daftarsiswa').doc(siswa.uid)
                .collection('semester').doc(configC.semesterAktif.value)
                .collection('matapelajaran').doc(idMapel)
                .collection('nilai_harian').doc(idTugasUlangan);

            final docSnap = await docRef.get();
            if (docSnap.exists) {
               final val = docSnap.data()?['nilai'];
               if (val != null) {
                 textControllers[siswa.uid]?.text = val.toString();
               }
            }
          } catch (e) {
            print("Error fetch nilai siswa ${siswa.namaLengkap}: $e");
          }
        }).toList();

        await Future.wait(tasks);
      }
      
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data: ${e.toString()}");
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
      // Jika batal absen (hadir kembali), kosongkan nilai atau kembalikan nilai lama?
      // Saat ini dibiarkan apa adanya (tetap ada teks jika sudah diketik)
    } else {
      absentStudents.add(uid);
      textControllers[uid]?.clear(); // Hapus nilai jika ditandai absen
    }
  }

  Future<void> simpanNilaiMassal() async {
    // Validasi Awal
    if (idKelas.isEmpty || idMapel.isEmpty) return;

    isSaving.value = true;
    final WriteBatch batch = _firestore.batch();
    int validGradesCount = 0; 
    
    // Persiapan Path Dasar
    final String pathBase = '/Sekolah/${configC.idSekolah}/tahunajaran/${configC.tahunAjaranAktif.value}/kelastahunajaran/$idKelas/daftarsiswa';

    try {
      for (final siswa in daftarSiswa) {
        if (absentStudents.contains(siswa.uid)) continue; 

        final controller = textControllers[siswa.uid];
        final nilaiString = controller?.text.trim();  

        if (nilaiString == null || nilaiString.isEmpty) continue; 

        final int? nilai = int.tryParse(nilaiString); 

        if (nilai == null || nilai < 0 || nilai > 100) {
          Get.snackbar("Error", "Nilai ${siswa.namaLengkap} tidak valid (0-100).");
          isSaving.value = false;
          return;
        } 

        validGradesCount++; 

        // Referensi Dokumen Mapel Siswa
        final siswaMapelRef = _firestore.doc('$pathBase/${siswa.uid}/semester/${configC.semesterAktif.value}/matapelajaran/$idMapel');
        
        // 1. Update Metadata Mapel (Pastikan dokumen mapel ada)
        batch.set(siswaMapelRef, {
          'idMapel': idMapel, 
          'namaMapel': namaMapel, 
          // Kita update info guru pengampu terakhir
          'idGuru': idGuruPencatat,
          'namaGuru': namaGuruPencatat, 
          'aliasGuruPencatatAkhir': aliasGuruPencatat,
        }, SetOptions(merge: true));  

        // 2. Tentukan Referensi Dokumen Nilai
        DocumentReference nilaiRef;
        if (idTugasUlangan != null && idTugasUlangan!.isNotEmpty) {
          // [AMAN] Gunakan ID Tugas sebagai ID Dokumen (Anti Duplikat)
          nilaiRef = siswaMapelRef.collection('nilai_harian').doc(idTugasUlangan);
        } else {
          // [MANUAL] Buat ID baru. 
          // Catatan: Ini akan membuat duplikat jika ditekan Simpan berkali-kali untuk tugas manual yang sama.
          // Tapi karena ini fitur "Input Massal" bebas, ini perilaku yang diharapkan.
          nilaiRef = siswaMapelRef.collection('nilai_harian').doc();
        }
        
        // 3. Simpan Data Nilai
        batch.set(nilaiRef, {
          'kategori': kategoriTugas, 
          'nilai': nilai, 
          'catatan': judulTugas,
          'tanggal': Timestamp.now(), 
          'idGuruPencatat': idGuruPencatat,
          'namaGuruPencatat': namaGuruPencatat, 
          'aliasGuruPencatat': aliasGuruPencatat,
          'idTugasUlangan': idTugasUlangan,
          'idSekolah': configC.idSekolah,
          'idMapel': idMapel,
          'kelasId': idKelas,
          'semester': int.parse(configC.semesterAktif.value),
        }, SetOptions(merge: true));

        // 4. Notifikasi
        // (Opsional: Bisa dinonaktifkan jika merasa terlalu spam 30 notif sekaligus)
        final notifRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid).collection('notifikasi').doc();
        batch.set(notifRef, {
          'judul': 'Nilai Baru: $namaMapel',
          'isi': 'Nilai untuk "$judulTugas" adalah $nilai.',
          'tipe': 'NILAI_MAPEL',
          'tanggal': FieldValue.serverTimestamp(),
          'isRead': false,
          'idSekolah': configC.idSekolah,
        }); 
        
        // Update Counter Notif
        final metaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid).collection('notifikasi_meta').doc('metadata');
        batch.set(metaRef, {'unreadCount': FieldValue.increment(1), 'idSekolah': configC.idSekolah}, SetOptions(merge: true));
      } 

      if (validGradesCount == 0) {
        Get.snackbar("Info", "Tidak ada nilai yang diisi.");
        isSaving.value = false;
        return;
      } 

      await batch.commit();
      
      // Refresh controller tugas jika ada (untuk update statistik pengumpulan)
      if (Get.isRegistered<ManajemenTugasController>()) {
        Get.find<ManajemenTugasController>().fetchTugas();
      }
      
      Get.back();   
      Get.snackbar("Sukses", "$validGradesCount nilai berhasil disimpan.");  

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan: $e");
    } finally {
      isSaving.value = false;
    }
  }
}


// // lib/app/modules/input_nilai_massal_akademik/controllers/input_nilai_massal_akademik_controller.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../../controllers/auth_controller.dart';
// import '../../../controllers/config_controller.dart';
// import '../../../models/siswa_model.dart';
// import '../../manajemen_tugas/controllers/manajemen_tugas_controller.dart';

// class InputNilaiMassalAkademikController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();
//   final AuthController _authController = Get.find<AuthController>();

//   // --- DATA KONTEKS DARI ARGUMEN ---
//   late String idKelas;
//   late String idMapel;
//   late String namaMapel;
//   late String judulTugas;
//   late String kategoriTugas;
//   String? idTugasUlangan;

//   // --- STATE UI ---
//   final isLoading = true.obs;
//   final isSaving = false.obs;

//   // --- STATE DATA & FORM ---
//   final daftarSiswa = <SiswaModel>[].obs;
//   final filteredSiswa = <SiswaModel>[].obs;
//   final textControllers = <String, TextEditingController>{}.obs;
//   final absentStudents = <String>{}.obs;
//   final searchController = TextEditingController();

//   late String idGuruPencatat;
//   late String namaGuruPencatat;
//   late String aliasGuruPencatat;

//   @override
//   void onInit() {
//     super.onInit();
//     final args = Get.arguments as Map<String, dynamic>? ?? {};
//     idKelas = args['idKelas'] ?? '';
//     idMapel = args['idMapel'] ?? '';
//     namaMapel = args['namaMapel'] ?? '';
//     judulTugas = args['judulTugas'] ?? 'Tugas';
//     kategoriTugas = args['kategoriTugas'] ?? 'Harian/PR';
//     idTugasUlangan = args['idTugasUlangan'];

//     idGuruPencatat = _authController.auth.currentUser!.uid;
//     namaGuruPencatat = configC.infoUser['nama'] ?? 'Guru Tidak Dikenal';
//     aliasGuruPencatat = configC.infoUser['alias'] ?? namaGuruPencatat;

//     searchController.addListener(() => filterSiswa(searchController.text));

//     ever(configC.isUserDataReady, (isReady) {
//       if (isReady) _fetchSiswaAndPrepareForm();
//     });
//     if (configC.isUserDataReady.value) {
//       _fetchSiswaAndPrepareForm();
//     }
//   }

//   @override
//   void onClose() {
//     searchController.dispose();
//     for (var controller in textControllers.values) {
//       controller.dispose();
//     }
//     super.onClose();
//   }

//   Future<void> _fetchSiswaAndPrepareForm() async {
//     isLoading.value = true;
//     try {
//       final String tahunAjaran = configC.tahunAjaranAktif.value;
//       if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
//         throw Exception("Tahun ajaran tidak aktif.");
//       }
  
//       // --- MULAI REVISI ---
//       // 1. Ambil daftar siswa dari kelas (HANYA SATU QUERY)
//       // Query ini sekarang mengambil data yang sudah diperkaya dari subkoleksi daftarsiswa
//       final siswaSnap = await _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(tahunAjaran)
//           .collection('kelastahunajaran').doc(idKelas)
//           .collection('daftarsiswa')
//           .orderBy('namaLengkap')
//           .get();
      
//       // Langsung ubah hasilnya menjadi model, tidak perlu query kedua.
//       final allSiswa = siswaSnap.docs.map((doc) => 
//           SiswaModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
//           .toList();
//       // --- SELESAI REVISI ---
      
//       daftarSiswa.assignAll(allSiswa);
//       filteredSiswa.assignAll(allSiswa);
  
//       // Jika tidak ada siswa, hentikan proses lebih awal.
//       if (daftarSiswa.isEmpty) {
//         isLoading.value = false;
//         return;
//       }
  
//       // 2. Siapkan text controller untuk setiap siswa
//       for (var siswa in daftarSiswa) {
//         textControllers[siswa.uid] = TextEditingController();
//       }
  
//       // 3. Jika ini adalah penilaian untuk tugas spesifik, ambil nilai terakhir
//       if (idTugasUlangan != null) {
//         final Map<String, int> nilaiTerakhirSiswa = {};
  
//         // Query untuk setiap siswa untuk mendapatkan nilai terakhirnya untuk tugas ini
//         // NOTE: Loop ini melakukan banyak pembacaan, tapi tidak ada cara yang lebih efisien
//         // untuk 'JOIN' di Firestore. Ini adalah perilaku yang bisa diterima.
//         for (final siswa in daftarSiswa) {
//           final nilaiSnap = await _firestore
//               .collection('Sekolah').doc(configC.idSekolah)
//               .collection('tahunajaran').doc(tahunAjaran)
//               .collection('kelastahunajaran').doc(idKelas)
//               .collection('daftarsiswa').doc(siswa.uid)
//               .collection('semester').doc(configC.semesterAktif.value)
//               .collection('matapelajaran').doc(idMapel)
//               .collection('nilai_harian')
//               .where('idTugasUlangan', isEqualTo: idTugasUlangan)
//               .orderBy('tanggal', descending: true)
//               .limit(1)
//               .get();
          
//           if (nilaiSnap.docs.isNotEmpty) {
//             nilaiTerakhirSiswa[siswa.uid] = nilaiSnap.docs.first.data()['nilai'] as int;
//           }
//         }
  
//         // 4. Isi text controller dengan nilai yang sudah ada
//         for (var siswa in daftarSiswa) {
//           if (nilaiTerakhirSiswa.containsKey(siswa.uid)) {
//             textControllers[siswa.uid]?.text = nilaiTerakhirSiswa[siswa.uid].toString();
//           }
//         }
//       }
  
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat data siswa: ${e.toString()}");
//       print("### ERROR FETCH SISWA MASSAL: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void filterSiswa(String query) {
//     if (query.isEmpty) {
//       filteredSiswa.assignAll(daftarSiswa);
//     } else {
//       filteredSiswa.assignAll(daftarSiswa.where(
//           (siswa) => siswa.namaLengkap.toLowerCase().contains(query.toLowerCase())));
//     }
//   }

//   void toggleAbsen(String uid) {
//     if (absentStudents.contains(uid)) {
//       absentStudents.remove(uid);
//     } else {
//       absentStudents.add(uid);
//     }
//   }

//   Future<void> simpanNilaiMassal() async {
//     isSaving.value = true;
//     final WriteBatch batch = _firestore.batch();
//     int validGradesCount = 0; 

//     try {
//       for (final siswa in daftarSiswa) {
//         // 1. Lewati siswa yang ditandai absen/tidak dinilai
//         if (absentStudents.contains(siswa.uid)) continue; 

//         final controller = textControllers[siswa.uid];
//         final nilaiString = controller?.text.trim();  

//         // 2. Lewati jika input kosong
//         if (nilaiString == null || nilaiString.isEmpty) continue; 

//         final int? nilai = int.tryParse(nilaiString); 

//         if (nilai == null || nilai < 0 || nilai > 100) {
//           Get.snackbar("Input Tidak Valid", "Nilai untuk ${siswa.namaLengkap} tidak valid (harus 0-100).");
//           isSaving.value = false;
//           return;
//         } 

//         validGradesCount++; 

//         // --- REFERENSI PATH ---
//         final siswaMapelRef = _firestore
//             .collection('Sekolah').doc(configC.idSekolah)
//             .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
//             .collection('kelastahunajaran').doc(idKelas)
//             .collection('daftarsiswa').doc(siswa.uid)
//             .collection('semester').doc(configC.semesterAktif.value)
//             .collection('matapelajaran').doc(idMapel);
        
//         // Update Metadata Mapel (Safe Update)
//         batch.set(siswaMapelRef, {
//           'idMapel': idMapel, 'namaMapel': namaMapel, 'idGuru': idGuruPencatat,
//           'namaGuru': namaGuruPencatat, 'aliasGuruPencatatAkhir': aliasGuruPencatat,
//         }, SetOptions(merge: true));  

//         // --- [PERBAIKAN UTAMA: LOGIKA ID DETERMINISTIK] ---
//         DocumentReference nilaiRef;

//         if (idTugasUlangan != null && idTugasUlangan!.isNotEmpty) {
//           // A. JIKA DARI TUGAS/ULANGAN:
//           // Gunakan ID Tugas sebagai ID Dokumen Nilai.
//           // Ini MENJAMIN 1 Tugas hanya punya 1 Nilai per Siswa (Anti-Duplikat).
//           nilaiRef = siswaMapelRef.collection('nilai_harian').doc(idTugasUlangan);
//         } else {
//           // B. JIKA MANUAL (TANPA TUGAS):
//           // Gunakan ID acak (biarkan behavior lama untuk input manual bebas)
//           nilaiRef = siswaMapelRef.collection('nilai_harian').doc();
//         }
        
//         // Simpan Data Nilai
//         batch.set(nilaiRef, {
//           'kategori': kategoriTugas, 
//           'nilai': nilai, 
//           'catatan': judulTugas,
//           'tanggal': Timestamp.now(), 
//           'idGuruPencatat': idGuruPencatat,
//           'namaGuruPencatat': namaGuruPencatat, 
//           'aliasGuruPencatat': aliasGuruPencatat,
//           'idTugasUlangan': idTugasUlangan, // Bisa null, tidak masalah
//           'idSekolah': configC.idSekolah,
//           'idMapel': idMapel,
//           'kelasId': idKelas,
//           'semester': int.parse(configC.semesterAktif.value),
//         }, SetOptions(merge: true)); // Merge agar aman saat update

//         // --- NOTIFIKASI (OPSIONAL: Hanya kirim jika nilai baru/berubah) ---
//         // Untuk efisiensi di batch write, kita tetap kirim notif agar siswa tau ada update nilai.
//         final siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
//         final notifRef = siswaDocRef.collection('notifikasi').doc();
        
//         batch.set(notifRef, {
//           'judul': 'Nilai Baru/Update: $namaMapel',
//           'isi': 'Nilai untuk "$judulTugas" adalah $nilai.',
//           'tipe': 'NILAI_MAPEL',
//           'tanggal': FieldValue.serverTimestamp(),
//           'isRead': false,
//           'idSekolah': configC.idSekolah,
//         }); 

//         final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
//         batch.set(metaRef, {'unreadCount': FieldValue.increment(1), 'idSekolah': configC.idSekolah}, SetOptions(merge: true));
//       } 

//       if (validGradesCount == 0) {
//         Get.snackbar("Informasi", "Tidak ada nilai untuk disimpan.", backgroundColor: Colors.blueAccent, colorText: Colors.white);
//         isSaving.value = false;
//         return;
//       } 

//       await batch.commit();
      
//       // Refresh data di controller sebelumnya jika ada
//       if (Get.isRegistered<ManajemenTugasController>()) {
//         final mtController = Get.find<ManajemenTugasController>();
//         mtController.fetchTugas(); // Opsional: refresh list tugas
//       }
      
//       Get.back();   
//       Get.snackbar("Berhasil", "$validGradesCount nilai berhasil disimpan/diupdate.", backgroundColor: Colors.green, colorText: Colors.white);  

//     } catch (e) {
//       Get.snackbar("Error", "Terjadi kesalahan saat menyimpan: ${e.toString()}", backgroundColor: Colors.red, colorText: Colors.white);
//     } finally {
//       isSaving.value = false;
//     }
//   }
// }