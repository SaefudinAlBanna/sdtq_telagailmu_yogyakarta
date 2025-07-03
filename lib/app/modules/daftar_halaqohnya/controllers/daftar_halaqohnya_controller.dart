import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/siswa_halaqoh.dart'; // Sesuaikan path ke model Anda

class DaftarHalaqohnyaController extends GetxController {
  // --- STATE REAKTIF ---
  // Ini akan menyimpan info halaqoh yang sedang dibuka
  final RxString fase = ''.obs;
  final RxString namaPengampu = ''.obs;
  final Rx<String?> urlFotoPengampu = Rx<String?>(null); // State untuk foto pengampu
  final Rx<String?> idPengampu = Rx<String?>(null);
  
  // State untuk UI
  final RxBool isLoading = true.obs;
  final RxBool isDialogLoading = false.obs; // Loading khusus untuk aksi di dialog
  final RxList<SiswaHalaqoh> daftarSiswa = <SiswaHalaqoh>[].obs;

  // Stream subscription untuk auto-update daftar siswa
  StreamSubscription? _siswaSubscription;

  // --- CONTROLLER UNTUK DIALOG ---
  final TextEditingController alhusnaC = TextEditingController();
  final TextEditingController pengampuPindahC = TextEditingController();
  final TextEditingController alasanPindahC = TextEditingController();

  // Tambahkan state baru di controller
final RxList<String> siswaTerpilihUntukUpdateMassal = <String>[].obs;
final TextEditingController bulkUpdateAlhusnaC = TextEditingController();

  // --- PROPERTI LAINNYA ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final String idSekolah = 'P9984539';
  late final String idUser;
  late final String emailAdmin;

  final List<String> listLevelAlhusna = [
  "Al-Husna", "Juz i",
  "Juz 1", "Juz 2", "Juz 3", "Juz 4", "Juz 5",
  "Juz 6", "Juz 7", "Juz 8", "Juz 9", "Juz 10",
  "Juz 11", "Juz 12", "Juz 13", "Juz 14", "Juz 15",
  "Juz 16", "Juz 17", "Juz 18", "Juz 19", "Juz 20",
  "Juz 21", "Juz 22", "Juz 23", "Juz 24", "Juz 25",
  "Juz 26", "Juz 27", "Juz 28", "Juz 29", "Juz 30",
];

  
@override
void onInit() {
  super.onInit();
  
  // Ambil semua parameter
  final faseParamEncoded = Get.parameters['fase'];
  final namaPengampuParamEncoded = Get.parameters['namaPengampu'];
  // --- TERIMA PARAMETER BARU ---
  final idPengampuParam = Get.parameters['idPengampu'];

  // Lakukan decoding untuk semua parameter
  final faseParam = faseParamEncoded != null ? Uri.decodeComponent(faseParamEncoded) : null;
  final namaPengampuParam = namaPengampuParamEncoded != null ? Uri.decodeComponent(namaPengampuParamEncoded) : null;

  // Cek apakah semua parameter yang dibutuhkan ada
  if (faseParam != null && namaPengampuParam != null && idPengampuParam != null) {
    fase.value = faseParam;
    namaPengampu.value = namaPengampuParam;
    // --- SIMPAN ID PENGAMPU ---
    idPengampu.value = idPengampuParam; 
    
    // Panggil fungsi yang akan kita perbaiki
    _loadDataPengampu(); 
    _listenToDaftarSiswa();
  } else {
      // Handle jika halaman dibuka tanpa parameter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar("Error Kritis", "Parameter Fase & Pengampu tidak ditemukan.");
        Get.back();
      });
    }
  }

  // Tambahkan FUNGSI BARU ini di controller
Future<void> updateAlHusnaMassal() async {
    final String targetLevel = bulkUpdateAlhusnaC.text;
    if (targetLevel.isEmpty) {
      Get.snackbar("Peringatan", "Pilih level Al-Husna tujuan.");
      return;
    }
    if (siswaTerpilihUntukUpdateMassal.isEmpty) {
      Get.snackbar("Peringatan", "Pilih minimal satu siswa.");
      return;
    }

    isDialogLoading.value = true;
    try {
      final WriteBatch batch = firestore.batch();
      final refDaftarSiswa = await _getDaftarSiswaCollectionRef();

      // Loop untuk setiap NISN siswa yang dipilih
      for (String nisn in siswaTerpilihUntukUpdateMassal) {
        // Path ke dokumen induk
        final docRefInduk = refDaftarSiswa.doc(nisn);
        
        // Cari semester terakhir untuk siswa ini
        final semesterQuery = await docRefInduk.collection('semester')
            .orderBy('tanggalinput', descending: true)
            .limit(1).get();
            
        // Update kedua dokumen jika semester ditemukan
        if (semesterQuery.docs.isNotEmpty) {
          final docRefSemester = semesterQuery.docs.first.reference;
          batch.update(docRefInduk, {'alhusna': targetLevel});
          batch.update(docRefSemester, {'alhusna': targetLevel});
        }
      }

      await batch.commit();
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "${siswaTerpilihUntukUpdateMassal.length} siswa telah diupdate ke level $targetLevel.");

    } catch (e) {
      Get.snackbar("Error", "Gagal melakukan update massal: $e");
    } finally {
      isDialogLoading.value = false;
      siswaTerpilihUntukUpdateMassal.clear();
      bulkUpdateAlhusnaC.clear();
    }
  }

  Future<void> _loadDataPengampu() async {
  // Pastikan ID pengampu tidak null sebelum menjalankan query
  if (idPengampu.value == null) {
    print("Error: ID Pengampu tidak ada, foto tidak bisa dimuat.");
    return;
  }
  
  try {
    // Ambil dokumen pegawai LANGSUNG menggunakan ID-nya (jauh lebih cepat)
    final pegawaiDoc = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idPengampu.value!) // <-- Menggunakan ID langsung
        .get();
    
    // Jika dokumen ada, ambil URL fotonya
    if (pegawaiDoc.exists) {
      urlFotoPengampu.value = pegawaiDoc.data()?['profileImageUrl'];
    }
  } catch (e) {
    if (kDebugMode) {
      print("Gagal memuat data pengampu berdasarkan ID: $e");
    }
  }
}
  /// Mengambil daftar kelas yang fasenya sesuai
  Future<List<String>> getKelasTersedia() async {
    try {
      // Buat variabel untuk string query
    String queryFase = fase.value;

    // ---- TAMBAHKAN PRINT DI SINI ----
    print("--- DEBUG: getKelasTersedia ---");
    print("Nilai fase.value dari parameter: '${fase.value}'");
    print("Mencari dokumen di 'kelastahunajaran' dengan field 'fase' == '$queryFase'");
    // ------------------------------------

      final ref = (await _getTahunAjaranRef()).collection('kelastahunajaran');
       final snapshot = await ref.where('fase', isEqualTo: fase.value).get(); 
       // ---- TAMBAHKAN PRINT LAGI DI SINI ----
    print("Hasil query: Ditemukan ${snapshot.docs.length} dokumen.");
    // ------------------------------------
 if (snapshot.docs.isEmpty) {
      print("Query tidak menemukan dokumen apa pun. Periksa data di Firestore!");
    }

    return snapshot.docs.map((doc) => doc.id).toList();
    } catch(e) {
       print("--- ERROR di getKelasTersedia ---: $e"); // Print error juga!
      Get.snackbar("Error", "Gagal mengambil daftar kelas.");
      return [];
    }
  }

  /// Mengambil daftar siswa yang belum punya kelompok dari kelas tertentu
  Stream<QuerySnapshot<Map<String, dynamic>>> getSiswaBaruStream(String namaKelas) async* {
    final ref = (await _getTahunAjaranRef()).collection('kelastahunajaran');
    yield* ref
        .doc(namaKelas)
        .collection('daftarsiswa')
        .where('statuskelompok', isEqualTo: 'baru')
        .snapshots();
  }
  
  /// Fungsi utama untuk menambahkan siswa ke kelompok halaqoh
  Future<void> tambahSiswaKeHalaqoh(Map<String, dynamic> dataSiswa) async {
  isDialogLoading.value = true;
  try {
    // 1. Dapatkan data penting dan validasi
    final String tahunAjaranRaw = await getTahunAjaranTerakhir(); // Pastikan fungsi ini ada
    if (tahunAjaranRaw == null || tahunAjaranRaw.isEmpty) {
        throw Exception("Tidak dapat menemukan tahun ajaran aktif.");
    }
    final String idTahunAjaran = tahunAjaranRaw.replaceAll("/", "-");
    final String nisn = dataSiswa['nisn'];
    if (nisn == null || nisn.isEmpty) {
        throw Exception("NISN siswa tidak valid.");
    }
    final String idUser = auth.currentUser!.uid; // Asumsi _auth tersedia

    // 2. Siapkan semua path/referensi yang dibutuhkan
    final CollectionReference refKelompokHalaqoh = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(fase.value)
        .collection('pengampu').doc(namaPengampu.value)
        .collection('daftarsiswa');

    final refSiswaDiHalaqoh = refKelompokHalaqoh.doc(nisn);
    
    // INI PATH BARU YANG PENTING
    final refSemesterDiHalaqoh = refSiswaDiHalaqoh.collection('semester').doc('Semester I');

    final refSiswaDiKelasAkademik = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(dataSiswa['namakelas'])
        .collection('daftarsiswa').doc(nisn);

    final refRekamJejakSiswa = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('siswa').doc(nisn)
        .collection('tahunajarankelompok').doc(idTahunAjaran);

    // 3. Siapkan data yang akan ditulis
    final Map<String, dynamic> dataUntukHalaqoh = {
        'namasiswa': dataSiswa['namasiswa'], 'nisn': nisn, 'kelas': dataSiswa['namakelas'],
        'alhusna': '0', 'profileImageUrl': dataSiswa['profileImageUrl'], 'fase': fase.value,
        'namapengampu': namaPengampu.value, 'tahunajaran': tahunAjaranRaw,
        'tanggalinput': FieldValue.serverTimestamp(), 'idpenginput': idUser,
    };

    // 4. Buat WriteBatch
    WriteBatch batch = firestore.batch();
    
    // Operasi 1: Tambahkan data siswa ke daftar halaqoh
    batch.set(refSiswaDiHalaqoh, dataUntukHalaqoh);
    
    // Operasi 2: (INI SOLUSINYA) Buat dokumen semester pertama untuk siswa ini
    batch.set(refSemesterDiHalaqoh, {
      ...dataUntukHalaqoh, // Salin semua data yang relevan
      'namasemester': 'Semester I',
    });

    // Operasi 3: Update status siswa di kelas akademik
    batch.update(refSiswaDiKelasAkademik, {'statuskelompok': 'aktif'});

    // Operasi 4: Buat rekam jejak di dokumen utama siswa
    batch.set(refRekamJejakSiswa, {
      'fase': fase.value, 'nisn': nisn, 'namatahunajaran': tahunAjaranRaw,
      'namapengampu': namaPengampu.value, 'idpenginput': idUser,
      'tanggalinput': DateTime.now().toIso8601String(),
    });

    // 5. Commit semua operasi
    await batch.commit();
    Get.snackbar("Berhasil", "${dataSiswa['namasiswa']} telah ditambahkan dengan data lengkap.");

  } catch (e) {
    Get.snackbar("Error Kritis", "Gagal menambahkan siswa: ${e.toString()}", duration: const Duration(seconds: 4));
  } finally {
    isDialogLoading.value = false;
  }
}

  // --- FUNGSI UTAMA UNTUK MEMUAT DATA ---

  /// Fungsi ini membuat satu stream yang akan terus mengupdate `daftarSiswa` secara real-time
  Future<void> _listenToDaftarSiswa() async {
    isLoading.value = true;
    try {
      final ref = await _getDaftarSiswaCollectionRef();

      _siswaSubscription?.cancel(); // Batalkan listener lama jika ada
      _siswaSubscription = ref.snapshots().listen((snapshot) {
        final siswaList = snapshot.docs
            .map((doc) => SiswaHalaqoh.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList();
        daftarSiswa.assignAll(siswaList);
        isLoading.value = false; // Matikan loading setelah data pertama diterima
      }, onError: (error) {
        if (kDebugMode) print("Error mendengarkan data siswa: $error");
        Get.snackbar("Error", "Gagal memuat data siswa secara real-time.");
        isLoading.value = false;
      });
    } catch (e) {
      if (kDebugMode) print("Error setup listener: $e");
      Get.snackbar("Error", "Gagal menyiapkan listener data.");
      isLoading.value = false;
    }
  }

  /// Memindahkan siswa dari satu kelompok pengampu ke kelompok lain.
Future<void> pindahkanSiswa(SiswaHalaqoh siswa) async {
  final String pengampuTujuan = pengampuPindahC.text;
  final String alasan = alasanPindahC.text;

  if (pengampuTujuan.isEmpty) {
    Get.snackbar("Peringatan", "Pengampu tujuan harus dipilih.");
    return;
  }

  isDialogLoading.value = true;
  try {
    final WriteBatch batch = firestore.batch();
    final tahunAjaranRef = await _getTahunAjaranRef();

    // 1. Path Dokumen Siswa di Kelompok LAMA
    final refSiswaLama = tahunAjaranRef
        .collection('kelompokmengaji')
        .doc(fase.value)
        .collection('pengampu')
        .doc(namaPengampu.value) // Pengampu saat ini
        .collection('daftarsiswa')
        .doc(siswa.nisn);

    // 2. Path Dokumen Siswa di Kelompok BARU
    final refSiswaBaru = tahunAjaranRef
        .collection('kelompokmengaji')
        .doc(fase.value)
        .collection('pengampu')
        .doc(pengampuTujuan) // Pengampu tujuan
        .collection('daftarsiswa')
        .doc(siswa.nisn);

    // 3. Hapus siswa dari kelompok LAMA
    batch.delete(refSiswaLama);

    // 4. Buat data baru untuk siswa di kelompok BARU
    // Kita gunakan rawData dari siswa dan hanya update nama pengampunya
    final Map<String, dynamic> dataBaru = Map<String, dynamic>.from(siswa.rawData);
    dataBaru['namapengampu'] = pengampuTujuan;
    dataBaru['alasanpindah'] = alasan; // (Opsional) Menambah rekam jejak
    dataBaru['tanggalinput'] = FieldValue.serverTimestamp();

    batch.set(refSiswaBaru, dataBaru);

    // --- TAMBAHAN BARU: CATAT RIWAYAT PERPINDAHAN ---
    // Path ke koleksi riwayat yang baru.
    // Kita gunakan .doc() agar ID dibuat otomatis oleh Firestore.
    final refRiwayat = tahunAjaranRef.collection('riwayatPindahHalaqoh').doc();

    // Data riwayat yang akan disimpan
    batch.set(refRiwayat, {
      'nisn': siswa.nisn,
      'namaSiswa': siswa.nama,
      'fase': fase.value,
      'dariPengampu': namaPengampu.value, // Pengampu asal (saat ini)
      'kePengampu': pengampuTujuan,      // Pengampu tujuan
      'alasan': alasan.isNotEmpty ? alasan : "Tidak ada alasan",
      'tanggalPindah': FieldValue.serverTimestamp(), // Catat waktu kejadian
    });
    
    // 5. Jalankan semua operasi
    await batch.commit();

    Get.back(); // Tutup dialog
    Get.snackbar("Berhasil", "${siswa.nama} telah dipindahkan ke kelompok $pengampuTujuan.");

  } catch (e) {
    Get.snackbar("Error", "Gagal memindahkan siswa: ${e.toString()}");
  } finally {
    isDialogLoading.value = false;
    pengampuPindahC.clear();
    alasanPindahC.clear();
  }
}

/// Mengambil riwayat siswa yang pindah (keluar dari atau masuk ke) kelompok ini.
Future<List<Map<String, dynamic>>> getRiwayatPindah() async {
  try {
    final tahunAjaranRef = await _getTahunAjaranRef();
    final refRiwayat = tahunAjaranRef.collection('riwayatPindahHalaqoh');

    // Query 1: Siswa yang KELUAR dari kelompok ini
    final queryKeluar = refRiwayat
        .where('fase', isEqualTo: fase.value)
        .where('dariPengampu', isEqualTo: namaPengampu.value);

    // Query 2: Siswa yang MASUK ke kelompok ini
    final queryMasuk = refRiwayat
        .where('fase', isEqualTo: fase.value)
        .where('kePengampu', isEqualTo: namaPengampu.value);

    // Jalankan kedua query secara paralel
    final results = await Future.wait([queryKeluar.get(), queryMasuk.get()]);

    final List<QueryDocumentSnapshot> allDocs = [];
    allDocs.addAll(results[0].docs); // Hasil query keluar
    allDocs.addAll(results[1].docs); // Hasil query masuk

    // Ubah dokumen menjadi List<Map>
    final List<Map<String, dynamic>> riwayatList = allDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    // Urutkan berdasarkan tanggal, yang terbaru di atas
    riwayatList.sort((a, b) {
      final Timestamp tA = a['tanggalPindah'] ?? Timestamp.now();
      final Timestamp tB = b['tanggalPindah'] ?? Timestamp.now();
      return tB.compareTo(tA);
    });

    return riwayatList;
  } catch (e) {
    if (kDebugMode) {
      print("Error mengambil riwayat pindah: $e");
    }
    Get.snackbar("Error", "Gagal memuat riwayat perpindahan.");
    return [];
  }
}


  // --- FUNGSI AKSI (Update, Pindah, dll) ---

  /// Memperbarui data Al-Husna seorang siswa
  Future<void> updateAlHusna(String nisn) async {
    if (alhusnaC.text.isEmpty) {
      Get.snackbar("Peringatan", "Kategori Al-Husna belum dipilih.");
      return;
    }
    
    isDialogLoading.value = true;
    try {
      // 1. Siapkan referensi ke DUA dokumen yang akan diupdate
      final refSiswaInduk = (await _getDaftarSiswaCollectionRef()).doc(nisn);

      // Cari dokumen semester terakhir/aktif
      final semesterQuery = await refSiswaInduk.collection('semester')
          .orderBy('tanggalinput', descending: true)
          .limit(1).get();

      if (semesterQuery.docs.isEmpty) {
        throw Exception("Dokumen semester untuk siswa ini tidak ditemukan.");
      }
      final refSiswaSemester = semesterQuery.docs.first.reference;

      // 2. Buat WriteBatch untuk transaksi atomik
      final WriteBatch batch = firestore.batch();

      // 3. Tambahkan kedua operasi update ke dalam batch
      final String levelAlHusnaBaru = alhusnaC.text;
      batch.update(refSiswaInduk, {'alhusna': levelAlHusnaBaru});
      batch.update(refSiswaSemester, {'alhusna': levelAlHusnaBaru});
      
      // 4. Commit batch
      await batch.commit();
      
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "Data Al-Husna telah diperbarui di semua catatan.");

    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui data: ${e.toString()}");
    } finally {
      isDialogLoading.value = false;
      alhusnaC.clear();
    }
  }

  // NOTE: Fungsi `pindahkan`, `simpanSiswaKelompok` dan lainnya sangat kompleks.
  // Merefaktor semuanya di sini akan sangat panjang.
  // Saya akan berikan contoh refactor untuk `updateAlHusna` dan `getDataPengampuFase`
  // Anda bisa menerapkan pola yang sama untuk fungsi lainnya.
  
  /// Mengambil daftar pengampu lain di fase yang sama untuk dialog "Pindah Halaqoh"
  Future<List<String>> getTargetPengampu() async {
    try {
      final ref = (await _getKelompokMengajiCollectionRef())
          .doc(fase.value)
          .collection('pengampu');
          
      final snapshot = await ref.get();
      
      return snapshot.docs
          .map((doc) => doc.data()['namapengampu'] as String)
          .where((nama) => nama != namaPengampu.value) // Jangan tampilkan pengampu saat ini
          .toList();
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil daftar pengampu lain.");
      return [];
    }
  }


  // --- FUNGSI HELPER (SANGAT PENTING!) ---

  /// Helper untuk mendapatkan path TAHUN AJARAN. Mencegah duplikasi kode.
  Future<DocumentReference> _getTahunAjaranRef() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) throw Exception("Tahun Ajaran tidak ditemukan");
    return snapshot.docs.first.reference;
  }
  
  /// Helper untuk mendapatkan path KELOMPOK MENGAJI.
  Future<CollectionReference> _getKelompokMengajiCollectionRef() async {
    final tahunAjaranRef = await _getTahunAjaranRef();
    return tahunAjaranRef.collection('kelompokmengaji');
  }

  /// Helper untuk mendapatkan path DAFTAR SISWA. Ini adalah inti dari refactoring.
  Future<CollectionReference> _getDaftarSiswaCollectionRef() async {
    final kelompokMengajiRef = await _getKelompokMengajiCollectionRef();
    return kelompokMengajiRef
        .doc(fase.value)
        .collection('pengampu')
        .doc(namaPengampu.value)
        .collection('daftarsiswa');
  }
  
  /// Mendapatkan nama tahun ajaran terakhir (terbaru) dari Firestore
  Future<String> getTahunAjaranTerakhir() async {
    final snapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      throw Exception("Tahun ajaran tidak ditemukan");
    }
    return snapshot.docs.first['namatahunajaran'] as String;
  }

  @override
  void onClose() {
    // Selalu batalkan subscription untuk mencegah memory leak!
    _siswaSubscription?.cancel();
    alhusnaC.dispose();
    pengampuPindahC.dispose();
    alasanPindahC.dispose();
    bulkUpdateAlhusnaC.dispose();
    super.onClose();
  }
}