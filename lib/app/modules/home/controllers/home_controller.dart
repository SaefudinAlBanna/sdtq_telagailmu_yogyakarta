// lib/app/modules/home/controllers/home_controller.dart

import 'dart:io'; // <-- TAMBAHKAN IMPORT INI
import 'package:image_picker/image_picker.dart'; // <-- TAMBAHKAN IMPORT INI
import '../../../controllers/storage_controller.dart'; // <-- TAMBAHKAN 
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

// Pindahkan halaman-halaman ke file mereka sendiri di dalam folder `pages` atau `widgets`
import '../../../models/event_kalender_model.dart';
import '../pages/home_page.dart';
import '../pages/marketplace_page.dart';
import '../pages/profile_page.dart';

import 'package:sdtq_telagailmu_yogyakarta/app/models/jurnal_model.dart';

class HomeController extends GetxController {

  // --- INJEKSI CONTROLLER LAIN ---
  // final AuthController authC = Get.find<AuthController>();
  final StorageController storageC = Get.find<StorageController>(); // <-- TAMBAHKAN INI
  
  // --- Firebase & User Info (final, lebih aman) ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final String idUser;
  late final String emailAdmin;
  final String idSekolah = "P9984539";
  Set<String> hariLiburSet = {}; // <-- TAMBAHKAN INI (Set lebih cepat untuk cek)

  Map<String, Map<String, dynamic>> jurnalOtomatisConfig = {}; // <-- TAMBAHKAN INI UNTUK KEGIATAN JAM RUTIN

  // --- UI State ---
  final RxBool isLoading = true.obs; // Satu state loading untuk inisialisasi awal
  final RxString jamPelajaranDocId = 'Memuat jam...'.obs;
  final Rx<String?> userRole = Rx<String?>(null);
  final RxString pesanAkhirSekolahKustom = "".obs;
  final RxString pesanLiburKustom = "".obs;
  final Rx<DateTime?> tanggalUpdatePesanAkhirSekolah = Rx<DateTime?>(null); 

  // --- Data yang di-cache setelah dimuat ---
  String? idTahunAjaran;
  List<DocumentSnapshot<Map<String, dynamic>>> kelasAktifList = [];
  List<Map<String, dynamic>> jadwalPelajaranList = [];

  // --- TextEditingControllers (Hanya jika benar-benar perlu) ---
  // Jika hanya untuk dialog sementara, bisa dibuat langsung di dialog.
  // Jika sering dipakai, biarkan di sini.
  final TextEditingController kelasSiswaC = TextEditingController();
  final TextEditingController tahunAjaranBaruC = TextEditingController();

  // --- Persistent Bottom Nav Bar ---
  final PersistentTabController tabController = PersistentTabController(initialIndex: 0);
  final List<Widget> navBarScreens = [
    HomePage(),
    MarketplacePage(),
    ProfilePage(),
  ];

  // --- Lainnya ---
  Timer? _timer;
  StreamSubscription? _configListener;

 @override
  void onInit() {
    super.onInit();
    // PENTING: Inisialisasi idUser di sini, sekali saja.
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      // Jika tidak ada user, lakukan sesuatu (misal: redirect ke login)
      Get.offAllNamed('/login'); // Ganti dengan rute login Anda
      return;
    }
    idUser = currentUser.uid;
    _initializeData();
  }


  @override
  void onClose() {
    _timer?.cancel();
    _configListener?.cancel(); 
    tabController.dispose();
    kelasSiswaC.dispose();
    tahunAjaranBaruC.dispose();
    super.onClose();
  }

//   void _listenToConfigChanges() {
//   if (idTahunAjaran == null) return;

//   final docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!);

//   // Batalkan listener lama jika ada untuk mencegah duplikasi
//   _configListener?.cancel(); 

//   // Mulai "menonton siaran langsung" dari dokumen ini
//   _configListener = docRef.snapshots().listen((snapshot) {
//     if (snapshot.exists && snapshot.data() != null) {
//       final data = snapshot.data()!;
      
//       // Update pesan libur kustom
//       if (data.containsKey('pesanLiburConfig')) {
//         final config = data['pesanLiburConfig'] as Map<String, dynamic>;
//         pesanLiburKustom.value = (config['pesan'] as String?) ?? "";
//       } else {
//         pesanLiburKustom.value = ""; // Reset jika config dihapus
//       }

//       // Update pesan akhir sekolah kustom
//       if (data.containsKey('pesanAkhirSekolahConfig')) {
//         final config = data['pesanAkhirSekolahConfig'] as Map<String, dynamic>;
//         pesanAkhirSekolahKustom.value = (config['pesan'] as String?) ?? "";
//       } else {
//         pesanAkhirSekolahKustom.value = ""; // Reset jika config dihapus
//       }

//       print("DEBUG: Pesan config terupdate -> ${pesanAkhirSekolahKustom.value}");

//     }
//   }, onError: (error) {
//     print("Error mendengarkan config: $error");
//   });
// }


void _listenToConfigChanges() {
  if (idTahunAjaran == null) return;

  final docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!);

  _configListener?.cancel(); 

  _configListener = docRef.snapshots().listen((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      
      // ... (kode pesanLiburKustom sudah benar, biarkan saja)

      // --- MODIFIKASI BAGIAN INI ---
      // Update pesan akhir sekolah kustom
      if (data.containsKey('pesanAkhirSekolahConfig')) {
        final config = data['pesanAkhirSekolahConfig'] as Map<String, dynamic>;
        pesanAkhirSekolahKustom.value = (config['pesan'] as String?) ?? "";
        
        // Ambil timestamp, konversi ke DateTime, dan simpan di state
        if (config['tanggalUpdate'] != null) {
          final timestamp = config['tanggalUpdate'] as Timestamp;
          tanggalUpdatePesanAkhirSekolah.value = timestamp.toDate();
        } else {
          tanggalUpdatePesanAkhirSekolah.value = null; // Reset jika tidak ada tanggal
        }
        
      } else {
        // Jika config dihapus, reset pesan dan tanggalnya
        pesanAkhirSekolahKustom.value = ""; 
        tanggalUpdatePesanAkhirSekolah.value = null;
      }
      // --- AKHIR MODIFIKASI ---

      print("DEBUG: Pesan config terupdate -> ${pesanAkhirSekolahKustom.value} pada ${tanggalUpdatePesanAkhirSekolah.value}");

    }
  }, onError: (error) {
    print("Error mendengarkan config: $error");
  });
}

// Buat FUNGSI BARU untuk menyimpan pesan
Future<void> simpanPesanAkhirSekolah(String pesanBaru) async {
  if (idTahunAjaran == null) {
    Get.snackbar("Error", "Tahun ajaran tidak aktif.");
    return;
  }
  
  final userDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
  final namaKepsek = userDoc.data()?['nama'] ?? 'Admin';

  try {
    isLoading.value = true;
    final docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!);
    
    await docRef.update({
      'pesanAkhirSekolahConfig': {
        'pesan': pesanBaru,
        'diubahOleh': namaKepsek,
        'terakhirDiubah': FieldValue.serverTimestamp(),
        'tanggalUpdate': Timestamp.now(),
      }
    });
    Get.snackbar("Berhasil", "Pesan akhir sekolah berhasil diperbarui.");
  } catch (e) {
    Get.snackbar("Error", "Gagal menyimpan pesan: $e");
  } finally {
    isLoading.value = false;
  }
}

  Future<void> _fetchUserRole() async {
  try {
    final doc = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('pegawai').doc(idUser)
        .get();
    if (doc.exists) {
      // Ambil field 'role' dari dokumen, jika tidak ada, defaultnya null.
      userRole.value = doc.data()?['role'];
    }
  } catch (e) {
    print("Gagal mengambil role pengguna: $e");
    // Biarkan role null jika terjadi error
  }
}

  void _showSafeSnackbar(String title, String message, {bool isError = false}) {
    // Memastikan snackbar hanya ditampilkan setelah frame UI selesai digambar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      Get.snackbar(
        title,
        message,
        backgroundColor: isError ? Colors.red : Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

   /// Menyediakan stream data PENGGUNA (PEGAWAI) yang sedang login
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream() {
    // Path ini sekarang menggunakan idUser dan idSekolah dari controller ini sendiri
    return firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .snapshots();
  }


  /// Mengorkestrasi seluruh proses: pilih gambar, upload, dan simpan URL.
  Future<void> pickAndUploadProfilePicture() async {
    final user = auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'Sesi tidak valid. Silakan login ulang.');
      return;
    }

    try {
      // 1. Pilih gambar dari galeri
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Tampilkan dialog loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        
        // 2. Upload gambar ke Supabase menggunakan StorageController
        // final String? imageUrl = await storageC.uploadProfilePicture(imageFile, user.uid);
         final String? imageUrl = await storageC.uploadProfilePicture(imageFile, user.uid);

        // 3. Jika upload berhasil, simpan URL ke Firestore
        if (imageUrl != null) {
          // await _updateProfileUrlInFirestore(imageUrl, user.uid);
          await _updateProfileUrlInFirestore(imageUrl, user.uid);
          Get.back(); // Tutup dialog loading
          Get.snackbar('Sukses', 'Foto profil berhasil diperbarui!', backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.back(); // Tutup dialog loading jika upload gagal
        }
      }
    } catch (e) {
      Get.back(); // Pastikan dialog loading ditutup jika ada error
      // Menggunakan snackbar yang aman
          _showSafeSnackbar('Sukses', 'Foto profil berhasil diperbarui!');
      // Get.snackbar('Error', 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Fungsi private untuk menyimpan URL ke Firestore
  Future<void> _updateProfileUrlInFirestore(String imageUrl, String uid) async {
    try {
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(uid)
          .update({'profileImageUrl': imageUrl});
    } catch (e) {
      throw Exception('Gagal menyimpan URL ke Firestore: $e');
    }
  }

  // =========================================================================
  // LOGIKA INISIALISASI UTAMA
  // =========================================================================
  Future<void> _initializeData() async {
    isLoading.value = true;
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw Exception("Sesi tidak valid, silakan login ulang.");
      }
      // idUser = currentUser.uid;
      emailAdmin = currentUser.email!;

      // 1. Ambil Tahun Ajaran Aktif (harus selesai dulu)
      idTahunAjaran = await _fetchTahunAjaranTerakhir();

        _listenToConfigChanges();

      // 2. Jalankan sisa pengambilan data secara bersamaan untuk efisiensi
      await Future.wait([
        _fetchJadwalPelajaran(),
        _fetchKelasAktif(),
        _fetchJurnalOtomatisConfig(),
         _fetchHariLibur(),
        //  _fetchPesanLiburKustom(),
         _fetchUserRole(),
        //  _fetchPesanAkhirSekolahKustom()
      ]);

      // 3. Set jam pelajaran awal dan mulai timer
      _updateCurrentJamPelajaran();
      _startTimerForClock();
    } catch (e) {
       _showSafeSnackbar("Kesalahan Inisialisasi", "Gagal memuat data awal: ${e.toString()}", isError: true);
       print("error kesalahan inisialisasi: $e");
      // Get.snackbar("Kesalahan Inisialisasi", "Gagal memuat data awal: ${e.toString()}",
          // backgroundColor: Colors.red, colorText: Colors.white);
      jamPelajaranDocId.value = "Error memuat data";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchPesanLiburKustom() async {
  if (idTahunAjaran == null) return;
  try {
    final doc = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('pesanLiburConfig')) {
      final config = doc.data()!['pesanLiburConfig'] as Map<String, dynamic>;
      final pesan = config['pesan'] as String?;
      if (pesan != null && pesan.isNotEmpty) {
        pesanLiburKustom.value = pesan;
      }
    }
  } catch (e) {
    print("Gagal mengambil pesan libur kustom: $e");
  }
}

  // --- FUNGSI BARU ---
  Future<void> _fetchHariLibur() async {
    if (idTahunAjaran == null) return;
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran!).collection('kalender_akademik')
        .where('is_libur', isEqualTo: true) // Hanya ambil yang libur
        .get();
    
    for (var doc in snapshot.docs) {
      // Simpan tanggal dalam format yyyy-MM-dd
      hariLiburSet.add(doc.id); 
    }
    // print("DEBUG: Hari libur dimuat: $hariLiburSet");
  }

  // --- FUNGSI BARU ---
bool isHariSekolahAktif(DateTime tanggal) {
  // 1. Cek apakah hari Sabtu (6) atau Minggu (7)
  if (tanggal.weekday == DateTime.saturday || tanggal.weekday == DateTime.sunday) {
    return false;
  }

  // 2. Cek apakah tanggal ada di daftar hari libur nasional/sekolah
  String formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
  if (hariLiburSet.contains(formattedDate)) {
    return false;
  }
  
  // 3. Jika lolos semua, berarti hari sekolah aktif
  return true;
}


  // --- FUNGSI BARU UNTUK OTOMATISASI JAM KEGIATAN RUTIN (PERSIAPAN, ISTIRAHAT DLL)---
  Future<void> _fetchJurnalOtomatisConfig() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('konfigurasi_jurnal_otomatis').get();
    
    for (var doc in snapshot.docs) {
      jurnalOtomatisConfig[doc.id] = doc.data();
    }
    // print("DEBUG: Konfigurasi Jurnal Otomatis dimuat: $jurnalOtomatisConfig");
  }


  // =========================================================================
  // LOGIKA PENGAMBILAN DATA (FETCHING)
  // =========================================================================

  Future<String> _fetchTahunAjaranTerakhir() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) throw Exception("Tidak ada data tahun ajaran.");
    return snapshot.docs.first.id;
  }

  // Future<void> _fetchJadwalPelajaran() async {
  //   final snapshot = await firestore
  //       .collection('Sekolah').doc(idSekolah).collection('jampelajaran').get();
  //   jadwalPelajaranList = snapshot.docs.map((doc) {
  //     final data = doc.data();
  //     return {'id': doc.id, 'start': data['start'], 'end': data['end']};
  //   }).toList();
  // }

  Future<void> _fetchJadwalPelajaran() async {
  final snapshot = await firestore
      .collection('Sekolah').doc(idSekolah).collection('jampelajaran').get();
  
  jadwalPelajaranList = snapshot.docs.map((doc) {
    final data = doc.data();
    
    // Asumsi di Firestore ada field 'jampelajaran' berisi "HH.mm-HH.mm"
    final String jamString = data['jampelajaran'] ?? doc.id;
    
    // Pecah string jam menjadi bagian start dan end
    final parts = jamString.split('-');
    
    String startTime = "00.00";
    String endTime = "00.00";

    if (parts.length == 2) {
      startTime = parts[0]; // contoh: "23.25"
      endTime = parts[1];   // contoh: "23.59"
    } else {
      // Sebagai fallback jika formatnya tidak sesuai, agar tidak crash
      print("Peringatan: Format jam pelajaran salah untuk dokumen ID: ${doc.id}. Menggunakan waktu default.");
    }
    
    // Kembalikan Map dengan format yang benar
    return {'id': doc.id, 'start': startTime, 'end': endTime};
  }).toList();

  // (Optional) Tambahkan print untuk memastikan hasilnya benar
  print("DEBUG: Jadwal Pelajaran yang dimuat: $jadwalPelajaranList");
}

  Future<void> _fetchKelasAktif() async {
    if (idTahunAjaran == null) return;
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran!).collection('kelasaktif').get();
    kelasAktifList = snapshot.docs;
  }

  // =========================================================================
  // LOGIKA JAM PELAJARAN
  // =========================================================================

  void _startTimerForClock() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCurrentJamPelajaran();
    });
  }

  void _updateCurrentJamPelajaran() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    String newJam = 'Tidak ada jam pelajaran';

    for (final jadwal in jadwalPelajaranList) {
      try {
        final startMinutes = _parseTimeToMinutes(jadwal['start']);
        final endMinutes = _parseTimeToMinutes(jadwal['end']);
        if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
          newJam = jadwal['id'];
          break; // Keluar setelah menemukan yang cocok
        }
      } catch (_) {
        continue; // Abaikan jadwal dengan format salah
      }
    }
    if (jamPelajaranDocId.value != newJam) {
      jamPelajaranDocId.value = newJam;
    }
  }

  int _parseTimeToMinutes(String? hhmm) {
    if (hhmm == null) throw const FormatException("Waktu null");
    final parts = hhmm.split('.');
    if (parts.length != 2) throw const FormatException("Format waktu salah");
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // =========================================================================
  // STREAMS UNTUK DATA REAL-TIME
  // =========================================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile() {
    return firestore.collection('Sekolah').doc(idSekolah)
                   .collection('pegawai').doc(idUser).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamInformasiSekolah() {
    if (idTahunAjaran == null) return const Stream.empty();
    return firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran!).collection('informasisekolah')
        .orderBy('tanggalinput', descending: true).limit(10).snapshots(); // Batasi 10 info terbaru
  }

  // Tambahkan deklarasi events di atas fungsi ini, misal:
  // Map<DateTime, List<EventKalenderModel>> events = {};

  // Jika events perlu diisi dari Firestore, tambahkan logika pengisian pada _fetchHariLibur atau fungsi lain yang sesuai.

  Map<DateTime, List<EventKalenderModel>> events = {};

  // di HomeController (Aplikasi Guru)

Stream<JurnalModel?> streamJurnalDetail(String idKelas) {
  final jamId = jamPelajaranDocId.value;
  if (idTahunAjaran == null || jamId.isEmpty || jamId.contains('...')) {
    return Stream.value(null);
  }

  final now = DateTime.now();
  
  // --- LOGIKA LIBUR BARU (YANG SUDAH LENGKAP) ---
  if (!isHariSekolahAktif(now)) {
    // --- DEFINISI YANG HILANG ---
    // Cari event spesifik untuk hari ini dari data kalender yang sudah dimuat.
    // Ini diperlukan untuk mendapatkan keterangan seperti "Libur Idul Fitri".
    final dateUtc = DateTime.utc(now.year, now.month, now.day);
    final eventsForToday = events[dateUtc] ?? [];
    final liburEvent = eventsForToday.firstWhere(
      (e) => e.isLibur,
      // Jika tidak ada event spesifik, buat objek kosong agar tidak error.
      orElse: () => EventKalenderModel(id: '', keterangan: "", isLibur: false, color: Colors.transparent),
    );
    // --- AKHIR DEFINISI YANG HILANG ---

    String pesanFinal;
    
    // 1. Cek pesan kustom dari Kepala Sekolah (Prioritas tertinggi)
    if (pesanLiburKustom.value.isNotEmpty) {
      pesanFinal = pesanLiburKustom.value;
    } 
    // 2. Jika tidak ada, cek keterangan dari event libur spesifik
    else if (liburEvent.keterangan.isNotEmpty) {
      pesanFinal = liburEvent.keterangan;
    } 
    // 3. Jika tidak ada keduanya, gunakan pesan default
    else {
      pesanFinal = "Selamat berlibur anak-anak sholih dan sholihah.. jangan lupa murojaah yaa..";
    }

    // Buat model jurnal "palsu" dengan pesan libur yang sudah final
    final liburModel = JurnalModel(
      materipelajaran: pesanFinal,
      namapenginput: "Sistem Sekolah",
      jampelajaran: "Hari Libur",
      catatanjurnal: "Nikmati waktu bersama keluarga.", // (Opsional) bisa ditambahkan catatan
    );
    return Stream.value(liburModel);
  }

   if (jamId == 'Tidak ada jam pelajaran') {
    // Default pesan jika tidak ada pesan kustom yang berlaku
    String pesanFinal = "Kegiatan belajar di sekolah telah usai. Istirahat dan jangan lupa muroja'ah ya."; 

    // Cek apakah pesan kustom ada DAN masih berlaku untuk hari ini
    final tanggalUpdate = tanggalUpdatePesanAkhirSekolah.value;
    if (tanggalUpdate != null && pesanAkhirSekolahKustom.value.isNotEmpty) {
      final now = DateTime.now();
      // Bandingkan TAHUN, BULAN, dan TANGGAL saja. Abaikan jam, menit, detik.
      final bool isSameDay = now.year == tanggalUpdate.year &&
                             now.month == tanggalUpdate.month &&
                             now.day == tanggalUpdate.day;

      if (isSameDay) {
        // Jika tanggalnya sama dengan hari ini, gunakan pesan kustom
        pesanFinal = pesanAkhirSekolahKustom.value;
      }
    }

    // Buat model jurnal "palsu" dengan pesan yang sudah final
    final modelUsai = JurnalModel(
      materipelajaran: pesanFinal,
      namapenginput: "Info Sekolah",
      jampelajaran: "Jam Sekolah Usai"
    );
    return Stream.value(modelUsai);
  }
  // --- AKHIR LOGIKA LIBUR ---

  // Jika bukan hari libur, lanjutkan mengambil data jurnal asli.
  final docIdTanggalJurnal = DateFormat('yyyy-MM-dd').format(now);
  
  final docRef = firestore
      .collection('Sekolah').doc(idSekolah)
      .collection('tahunajaran').doc(idTahunAjaran!)
      .collection('kelasaktif').doc(idKelas)
      .collection('tanggaljurnal').doc(docIdTanggalJurnal)
      .collection('jurnalkelas').doc(jamId);

  return docRef.snapshots().map((docSnapshot) {
    if (docSnapshot.exists && docSnapshot.data() != null) {
      return JurnalModel.fromFirestore(docSnapshot.data()!);
    }
    if (jurnalOtomatisConfig.containsKey(jamId)) {
      final configData = jurnalOtomatisConfig[jamId]!;
      return JurnalModel.fromFirestore(configData);
    }
    return null;
  });
}

  // UNTUK KEPALA SEKOLAH
  Future<void> simpanPesanLibur(String pesanBaru) async {
  if (idTahunAjaran == null) {
    Get.snackbar("Error", "Tahun ajaran tidak aktif.");
    return;
  }
  
  // Ambil nama Kepala Sekolah dari profil yang sedang login
  final userDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
  final namaKepsek = userDoc.data()?['nama'] ?? 'Admin';

  try {
    isLoading.value = true;
    final docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!);
    
    await docRef.update({
      'pesanLiburConfig': {
        'pesan': pesanBaru,
        'diubahOleh': namaKepsek,
        'terakhirDiubah': FieldValue.serverTimestamp(),
        'tanggalUpdate': Timestamp.now(),
      }
    });
    Get.snackbar("Berhasil", "Pesan libur berhasil diperbarui.");
  } catch (e) {
    Get.snackbar("Error", "Gagal menyimpan pesan: $e");
  } finally {
    isLoading.value = false;
  }
}


  // =========================================================================
  // ACTIONS
  // =========================================================================
  
  void signOut() async {
    await auth.signOut();
    Get.offAllNamed('/login'); // Ganti dengan rute login Anda
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStreamBaru() async* {
    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .snapshots();
  }

  

  Future<void> simpanTahunAjaran() async {
    String uid = auth.currentUser!.uid;
    String emailPenginput = auth.currentUser!.email!;

    DocumentReference<Map<String, dynamic>> ambilDataPenginput = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(uid);

    DocumentSnapshot<Map<String, dynamic>> snapDataPenginput =
        await ambilDataPenginput.get();

    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
        await colTahunAjaran.get();
    List<Map<String, dynamic>> listTahunAjaran =
        snapshotTahunAjaran.docs.map((e) => e.data()).toList();

    //ambil namatahunajaranya
    listTahunAjaran.map((e) => e['namatahunajaran']).toList();

    // buat documen id buat tahun ajaran
    String idTahunAjaran = tahunAjaranBaruC.text.replaceAll("/", "-");

    if (listTahunAjaran.elementAt(0)['namatahunajaran'] !=
        tahunAjaranBaruC.text) {
      if (!listTahunAjaran.any(
        (element) => element['namatahunajaran'] == tahunAjaranBaruC.text,
      )) {
        //belum input tahun ajaran yang baru, maka bikin tahun ajaran baru
        colTahunAjaran
            .doc(idTahunAjaran)
            .set({
              'namatahunajaran': tahunAjaranBaruC.text,
              'idpenginput': uid,
              'emailpenginput': emailPenginput,
              'namapenginput': snapDataPenginput.data()?['nama'],
              'tanggalinput': DateTime.now().toString(),
              'idtahunajaran': idTahunAjaran,
            })
            .then(
              (value) => {
                Get.snackbar('Berhasil', 'Tahun ajaran sudah berhasil dibuat'),
                tahunAjaranBaruC.text = "",
              },
            );
      } else {
        Get.snackbar('Gagal', 'Tahun ajaran sudah ada');
      }
      // Get.back();
    }
    // Get.back();
  }

  Future<String?> getDataKelasWali() async {
  String tahunajaranya = await getTahunAjaranTerakhir();
  String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
      .collection('Sekolah')
      .doc(idSekolah)
      .collection('tahunajaran')
      .doc(idTahunAjaran)
      .collection('kelastahunajaran')
      .where('idwalikelas', isEqualTo: idUser)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.id;
  } else {
    // print('Tidak ditemukan kelas untuk walikelas dengan id: $idUser');
    // Get.snackbar("Informasi", "Tidak ada catatan dalam kelas anda");
    return null;
  }
}

  Future<String> getTahunAjaranTerakhir() async {
    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
        await colTahunAjaran.get();
    List<Map<String, dynamic>> listTahunAjaran =
        snapshotTahunAjaran.docs.map((e) => e.data()).toList();
    String tahunAjaranTerakhir =
        listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
    return tahunAjaranTerakhir;
  }

  Future<List<String>> getDataFase() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String idSemester = 'Semester I';  // nanti ini diambil dari database

    List<String> faseList = [];

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            faseList.add(docSnapshot.id);
          }
        });
    return faseList;
  }

  Future<List<String>> getDataKelasYangDiajar() async {
    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajaran')
        .doc(idTahunAjaran) // tahun ajaran yang d kelas pegawai
        .collection('kelasnya')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataKelas() async {

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('kelas')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataKelasMapel() async {

    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasaktif')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataMapel(String kelas) async {
    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> mapelList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajaran')
        .doc(idTahunAjaran) // tahun ajaran yang d kelas pegawai
        .collection('kelasnya')
        .doc(kelas)
        .collection('matapelajaran')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            mapelList.add(docSnapshot.id);
          }
        });
    return mapelList;
  }

  Future<List<String>> getDataKelompok() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String idSemester = 'Semester I';

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajarankelompok')
        .doc(idTahunAjaran)
        // .collection('semester')
        // .doc(idSemester)
        .collection('kelompokmengaji')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    // print('ini kelasList : $kelasList');
    return kelasList;
    // }
    // return [];
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProfileBaru() async* {
    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .snapshots();
  }



  Stream<QuerySnapshot<Map<String, dynamic>>> getDataInfo() async* {
    // ignore: unnecessary_null_comparison
    // if (idTahunAjaran == null) return const Stream.empty();

    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('informasisekolah')
        .orderBy('tanggalinput', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataJurnal() async* {
    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataJurnalKelas() {
    // ignore: unnecessary_null_comparison
    if (idTahunAjaran == null) return const Stream.empty();

    //   DateTime now = DateTime.now();
    //   String docIdJurnal = DateFormat.yMd().format(now).replaceAll('/', '-');

    return firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasaktif')
        .snapshots();
  }

  String getJamPelajaranSaatIni() {
  DateTime now = DateTime.now();
  int currentMinutes = now.hour * 60 + now.minute;
  print('currentMinutes: $currentMinutes');
  List<String> jamPelajaran = [
    '07-00-07.05',
    '07.05-07.30',
    '08.00-08.45',

  ];
  for (String jam in jamPelajaran) {
    List<String> range = jam.split('-');
    int startMinutes = _parseToMinutes(range[0]);
    int endMinutes = _parseToMinutes(range[1]);
    print('Cek: $currentMinutes >= $startMinutes && $currentMinutes < $endMinutes');
    if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
      print('MATCH: $jam');
      return jam;
    }
  }
  print('Tidak ada jam pelajaran');
  return 'Tidak ada jam pelajaran';
}

int _parseToMinutes(String hhmm) {
  List<String> parts = hhmm.split('.');
  int hour = int.parse(parts[0]);
  int minute = int.parse(parts[1]);
  return hour * 60 + minute;
}

  // void test() {
  //   // print("jamPelajaranRx.value = ${jamPelajaranRx.value}, getJamPelajaranSaatIni() = ${getJamPelajaranSaatIni()}");
  //   jamPelajaranRx.value = getJamPelajaranSaatIni();
  //   print('jamPelajaranRx.value (init): ${jamPelajaranRx.value}');
  // }

  void tampilkanjurnal(String docId, String jamPelajaran) {
    getDataJurnalPerKelas(docId, jamPelajaran);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataJurnalPerKelas(
    String docId,
    String jamPelajaran,
  ) {
    // if (idTahunAjaran == null) return const Stream.empty();
    DateTime now = DateTime.now();
    String docIdJurnal = DateFormat.yMd().format(now).replaceAll('/', '-');

    // jamPelajaranRx.value = getJamPelajaranSaatIni();

    return firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasaktif')
        .doc(docId)
        .collection('tanggaljurnal') // <-- ganti sesuai struktur Firestore
        .doc(docIdJurnal)
        .collection('jurnalkelas') // <-- ganti sesuai struktur Firestore
        // .where('jampelajaran', isEqualTo: jamPelajaran)
        // .where('jampelajaran', isEqualTo: getJamPelajaranSaatIni())
        .where('jampelajaran', isEqualTo: jamPelajaranDocId.value)
        .snapshots();
  }
}

//**
//1. Menggunakan Tipe Data Numerik untuk Perbandingan
// Pendekatan ini lebih robust karena membandingkan angka lebih mudah dan akurat daripada membandingkan string waktu.
//Anda bisa mengubah semua waktu menjadi menit total dari tengah malam atau menggunakan objek DateTime secara langsung.
// Contoh Implementasi: */

void tampilkanSesuaiWaktu() {
  DateTime now = DateTime.now();
  int currentHour = now.hour;
  int currentMinute = now.minute;

  // Konversi waktu sekarang ke menit total dari tengah malam
  int currentTimeInMinutes = currentHour * 60 + currentMinute;

  // Definisikan rentang waktu dalam menit total
  // 01.00 - 01.30
  int startTime1 = 1 * 60 + 0;
  int endTime1 = 1 * 60 + 30;

  // 01.31 - 02.00
  int startTime2 = 1 * 60 + 31;
  int endTime2 = 2 * 60 + 0;

  // 02.01 - 02.30
  int startTime3 = 2 * 60 + 1;
  int endTime3 = 2 * 60 + 30;

  String isidataWaktu1 = 'pertama';
  String isidataWaktu2 = 'kedua';
  String isidataWaktu3 = 'ketiga';

  String tampilanYangSesuai =
      'Tidak ada data waktu yang cocok.'; // Default value

  if (currentTimeInMinutes >= startTime1 && currentTimeInMinutes <= endTime1) {
    tampilanYangSesuai = isidataWaktu1;
  } else if (currentTimeInMinutes >= startTime2 &&
      currentTimeInMinutes <= endTime2) {
    tampilanYangSesuai = isidataWaktu2;
  } else if (currentTimeInMinutes >= startTime3 &&
      currentTimeInMinutes <= endTime3) {
    tampilanYangSesuai = isidataWaktu3;
  }

  print('Waktu sekarang: $currentHour:$currentMinute');
  print('Tampilan yang sesuai: $tampilanYangSesuai');

  // Di sini Anda bisa memperbarui UI berdasarkan nilai tampilanYangSesuai
  // Contoh: setState(() { _dataYangDitampilkan = tampilanYangSesuai; });
}

//*** 2. Menggunakan Objek DateTime dan isAfter/isBefore
//Ini adalah cara yang lebih modern dan direkomendasikan
//karena DateTime dirancang untuk perbandingan waktu.
//Anda bisa membuat objek DateTime untuk waktu mulai dan
//akhir setiap rentang.
// */
void tampilkanSesuaiWaktuDenganDateTime() {
  DateTime now = DateTime.now();

  // Penting: Pastikan Anda hanya membandingkan jam dan menit saja
  // atau pastikan rentang waktu yang Anda definisikan adalah untuk hari yang sama.
  // Untuk perbandingan waktu harian saja (tanpa mempertimbangkan tanggal):
  DateTime timeOnly(int hour, int minute) {
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Definisikan rentang waktu menggunakan objek DateTime
  DateTime start1 = timeOnly(1, 0); // 01.00
  DateTime end1 = timeOnly(1, 30); // 01.30

  DateTime start2 = timeOnly(1, 31); // 01.31
  DateTime end2 = timeOnly(2, 0); // 02.00

  DateTime start3 = timeOnly(2, 1); // 02.01
  DateTime end3 = timeOnly(4, 30); // 02.30

  String isidataWaktu1 = 'pertama';
  String isidataWaktu2 = 'kedua';
  String isidataWaktu3 = 'ketiga';

  String tampilanYangSesuai = 'Tidak ada data waktu yang cocok.';

  // Perbandingan menggunakan isAfter dan isBefore
  if ((now.isAfter(start1) || now.isAtSameMomentAs(start1)) &&
      (now.isBefore(end1) || now.isAtSameMomentAs(end1))) {
    tampilanYangSesuai = isidataWaktu1;
  } else if ((now.isAfter(start2) || now.isAtSameMomentAs(start2)) &&
      (now.isBefore(end2) || now.isAtSameMomentAs(end2))) {
    tampilanYangSesuai = isidataWaktu2;
  } else if ((now.isAfter(start3) || now.isAtSameMomentAs(start3)) &&
      (now.isBefore(end3) || now.isAtSameMomentAs(end3))) {
    tampilanYangSesuai = isidataWaktu3;
  }

  // print('Waktu sekarang: ${now.hour}:${now.minute}');
  // print('Tampilan yang sesuai: $tampilanYangSesuai');
}


