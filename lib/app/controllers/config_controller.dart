// lib/app/controllers/config_controller.dart
// UNTUK APLIKASI SEKOLAH / GURU

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'auth_controller.dart';

enum AppStatus { loading, unauthenticated, needsNewPassword, authenticated }

class ConfigController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  final GetStorage _box = GetStorage();

  // --- STATE INTI ---
  late final String idSekolah;
  final RxMap<String, dynamic> infoUser = <String, dynamic>{}.obs;
  final Rx<AppStatus> status = AppStatus.loading.obs;
  
  // --- STATE KONFIGURASI SEKOLAH ---
  final RxString tahunAjaranAktif = "".obs;
  final RxString semesterAktif = "".obs;
  final RxList<String> daftarRoleTersedia = <String>[].obs;
  final RxList<String> daftarTugasTersedia = <String>[].obs;
  final RxBool isRoleManagementLoading = true.obs;

  final RxMap<String, dynamic> konfigurasiDashboard = <String, dynamic>{}.obs;

  // --- SAKLAR PENGAMAN ---
  final RxBool isCreatingNewUser = false.obs;
  StreamSubscription<User?>? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    idSekolah = dotenv.env['ID_SEKOLAH']!;
    _loadProfileFromCache();
    _userSubscription = _authController.authStateChanges.listen((user) {
      if (isCreatingNewUser.value) {
        print("[AUTH] Mode Senyap Aktif. Perubahan auth diabaikan.");
        return;
      }
      if (user == null) {
        clearUserConfig();
        status.value = AppStatus.unauthenticated;
      } else {
        status.value = AppStatus.loading;
        _syncAllUserData(user.uid);
      }
    });
  }
  
  @override
  void onClose() {
    _userSubscription?.cancel();
    super.onClose();
  }

  Future<void> _syncAllUserData(String uid) async {
    // Langkah 1: Selalu sinkronkan profil pengguna terlebih dahulu.
    bool profileSynced = await _syncProfileWithFirestore(uid);
    if (!profileSynced) return; // Hentikan jika profil tidak ditemukan

    // --- [PERBAIKAN LOGIKA] ---
    // Langkah 2: WAJIB sinkronkan tahun ajaran aktif.
    // Kita butuh data ini untuk langkah selanjutnya.
    await _syncTahunAjaranAktif();

    // Langkah 3: Jalankan sisa sinkronisasi secara paralel.
    // Keduanya (manajemen peran dan cek wali kelas) sekarang bisa berjalan bersamaan
    // karena sudah memiliki data tahun ajaran yang dibutuhkan.
    await Future.wait([
      _syncRoleManagementDataIfAllowed(),
      _checkIsWaliKelas(uid),
      _syncKonfigurasiDashboard(), 
    ]);
      
    // Langkah 4: Tentukan status akhir aplikasi.
    final bool mustChange = infoUser['mustChangePassword'] ?? false;
    if (mustChange) {
      status.value = AppStatus.needsNewPassword;
    } else {
      status.value = AppStatus.authenticated;
    }
    // --- AKHIR PERBAIKAN ---
  }

  Future<void> _checkIsWaliKelas(String uid) async {
    if (tahunAjaranAktif.value.isEmpty || tahunAjaranAktif.value.contains("TIDAK")) {
      // --- [DEBUG 1] ---
      print(">> DEBUG WALI KELAS: Stop, tahun ajaran tidak aktif.");
      return;
    }

    try {
      // --- [DEBUG 2] ---
      print(">> DEBUG WALI KELAS: Mencari di 'kelastahunajaran' dengan idWaliKelas == $uid");

      final snapshot = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif.value)
          .collection('kelastahunajaran')
          .where('idWaliKelas', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // --- [DEBUG 3] ---
        print(">> DEBUG WALI KELAS: DITEMUKAN! Kelas: ${snapshot.docs.first.id}");
        infoUser['kelasDiampu'] = snapshot.docs.first.id;
      } else {
        // --- [DEBUG 4] ---
        print(">> DEBUG WALI KELAS: TIDAK DITEMUKAN. Tidak ada kelas yang diampu.");
      }
    } catch (e) {
      print(">> DEBUG WALI KELAS: ERROR SAAT QUERY! $e");
    }
  }

  Future<void> _syncKonfigurasiDashboard() async {
  try {
    final doc = await _firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('pengaturan').doc('konfigurasi_dashboard')
        .get();
    if (doc.exists && doc.data() != null) {
      konfigurasiDashboard.value = doc.data()!;
    }
  } catch (e) {
    print("### Gagal mengambil konfigurasi dashboard: $e");
    // Biarkan map kosong jika gagal, agar ada fallback
  }
}

  Future<bool> _syncProfileWithFirestore(String uid) async {
    try {
      final userDoc = await _firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final Map<String, dynamic> firestoreData = userDoc.data()!;
        
        // Data ini yang akan kita gunakan di memori aplikasi
        infoUser.value = firestoreData;

        // --- [PERBAIKAN KRUSIAL] ---
        // Buat salinan data untuk disimpan ke cache
        final Map<String, dynamic> dataForCache = Map<String, dynamic>.from(firestoreData);

        // Periksa dan konversi field Timestamp ke String (ISO 8601)
        if (dataForCache['tglgabung'] is Timestamp) {
          dataForCache['tglgabung'] = (dataForCache['tglgabung'] as Timestamp).toDate().toIso8601String();
        }
        // Lakukan hal yang sama untuk field timestamp lain jika ada
        
        // Simpan data yang sudah aman (safe-to-encode) ke GetStorage
        await _box.write('userProfile', dataForCache);
        // --- AKHIR PERBAIKAN ---

        return true;
      } else {
        throw Exception("Profil pegawai tidak ditemukan.");
      }
    } catch (e) {
      await _authController.logout(); // authController sudah ada di scope class
      return false;
    }
  }

  /// Fungsi wrapper untuk memeriksa hak akses sebelum mengambil data peran.
  Future<void> _syncRoleManagementDataIfAllowed() async {
    const allowedRoles = ['Admin', 'Operator', 'TU', 'Tata Usaha', 'Kepala Sekolah'];
    bool canManage = infoUser['peranSistem'] == 'superadmin' || allowedRoles.contains(infoUser['role']);
    if (canManage) {
      await _syncRoleManagementData();
    }
  }

  /// Mengambil daftar peran dan tugas yang tersedia.
  Future<void> _syncRoleManagementData() async {
    try {
      isRoleManagementLoading.value = true;
      final doc = await _firestore.collection('Sekolah').doc(idSekolah).collection('pengaturan').doc('manajemen_peran').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        daftarRoleTersedia.assignAll(List<String>.from(data['daftar_role'] ?? []));
        daftarTugasTersedia.assignAll(List<String>.from(data['daftar_tugas'] ?? []));
      }
    } catch (e) {
      Get.snackbar("Error Konfigurasi", "Gagal memuat data peran dan tugas.");
    } finally {
      isRoleManagementLoading.value = false;
    }
  }
  
  /// Mengambil ID tahun ajaran dan semester yang sedang aktif.
  Future<void> _syncTahunAjaranAktif() async {
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').where('isAktif', isEqualTo: true).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        tahunAjaranAktif.value = doc.id;
        semesterAktif.value = doc.data()['semesterAktif']?.toString() ?? '1';
      } else {
        tahunAjaranAktif.value = "TIDAK DITEMUKAN";
      }
    } catch (e) {
      tahunAjaranAktif.value = "ERROR";
      print("Error sync Tahun Ajaran: $e");
    }
  }

  /// Memuat ulang data peran secara manual (dipanggil dari halaman manajemen).
  Future<void> reloadRoleManagementData() async {
    await _syncRoleManagementData();
  }

  /// Memuat profil dari cache lokal saat aplikasi dimulai.
  void _loadProfileFromCache() {
    // Gunakan <Map<String, dynamic>> untuk type safety
    final cachedProfile = _box.read<Map<String, dynamic>>('userProfile');
    
    if (cachedProfile != null) {
      // --- [PERBAIKAN KRUSIAL] ---
      // Buat salinan yang bisa diubah
      final Map<String, dynamic> processedProfile = Map<String, dynamic>.from(cachedProfile);

      // Periksa apakah 'tglgabung' ada dan merupakan String
      if (processedProfile['tglgabung'] is String) {
        try {
          // Konversi kembali String (ISO 8601) menjadi DateTime, lalu ke Timestamp
          final DateTime parsedDate = DateTime.parse(processedProfile['tglgabung']);
          processedProfile['tglgabung'] = Timestamp.fromDate(parsedDate);
        } catch (e) {
          // Jika parsing gagal, hapus key yang rusak agar tidak menyebabkan error
          processedProfile.remove('tglgabung');
          print("### Peringatan: Gagal mem-parsing 'tglgabung' dari cache: $e");
        }
      }
      
      // Masukkan data yang sudah diproses dan konsisten ke infoUser
      infoUser.value = processedProfile;
      // --- AKHIR PERBAIKAN ---
    }
  }
  
  /// Membersihkan semua state pengguna saat logout.
  Future<void> clearUserConfig() async {
    await _box.remove('userProfile');
    infoUser.clear();
    daftarRoleTersedia.clear();
    daftarTugasTersedia.clear();
    tahunAjaranAktif.value = "";
    semesterAktif.value = "";
    konfigurasiDashboard.clear();
  }

  Future<void> reloadKonfigurasiDashboard() async {
  await _syncKonfigurasiDashboard();
}

Future<void> forceSyncProfile() async {
    final user = _authController.auth.currentUser;
    if (user != null) {
      await _syncProfileWithFirestore(user.uid);
    }
}
}