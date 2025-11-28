// lib/app/modules/upsert_pegawai/controllers/upsert_pegawai_controller.dart (FINAL FIX)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_model.dart';

class UpsertPegawaiController extends GetxController {
  // --- DEPENDENSI & KUNCI ---
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- FORM CONTROLLERS ---
  late TextEditingController namaC;
  late TextEditingController emailC;
  late TextEditingController passAdminC;

  // --- STATE LOADING & MODE ---
  final RxBool isLoadingProses = false.obs;
  PegawaiModel? _pegawaiToEdit;
  bool get isEditMode => _pegawaiToEdit != null;

  // --- STATE DATA FORM ---
  final RxString jenisKelamin = "Laki-Laki".obs;
  final Rxn<String> jabatanTerpilih = Rxn<String>();
  final RxList<String> tugasTerpilih = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    namaC = TextEditingController();
    emailC = TextEditingController();
    passAdminC = TextEditingController();

    if (Get.arguments != null && Get.arguments is PegawaiModel) {
      _pegawaiToEdit = Get.arguments;
      _populateFieldsForEdit(_pegawaiToEdit!.uid);
    }
  }

  Future<void> _populateFieldsForEdit(String uid) async {
    try {
      final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(uid).get();
      if(doc.exists) {
        final data = doc.data()!;
        namaC.text = data['nama'] ?? '';
        emailC.text = data['email'] ?? '';
        jenisKelamin.value = data['jeniskelamin'] ?? 'Laki-Laki';
        jabatanTerpilih.value = data['role'];
        // Safe casting untuk List
        if (data['tugas'] != null) {
           tugasTerpilih.assignAll(List<String>.from(data['tugas']));
        }
      }
    } catch (e) {
      print("Error loading data edit: $e");
    }
  }

  @override
  void onClose() {
    namaC.dispose(); emailC.dispose(); passAdminC.dispose();
    super.onClose();
  }
  
  void validasiDanProses() {
    if (!formKey.currentState!.validate()) return;

    if (isEditMode) {
      _prosesSimpanData();
    } else {
      Get.defaultDialog(
        title: 'Verifikasi Admin',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan password Anda untuk membuat akun baru."),
            const SizedBox(height: 10),
            TextField(
              controller: passAdminC, 
              obscureText: true, 
              autofocus: true, 
              decoration: const InputDecoration(
                labelText: 'Password Admin Anda',
                border: OutlineInputBorder()
              )
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              // [FIX WINDOWS] Tutup dialog DULU, baru jalankan proses
              Get.back(); 
              _prosesSimpanData();
            }, 
            child: const Text('Konfirmasi')
          ),
        ],
      );
    }
  }

  Future<void> _prosesSimpanData() async {
    isLoadingProses.value = true;
    configC.isCreatingNewUser.value = true;
    
    // Pastikan user saat ini valid
    final currentUser = _auth.currentUser;
    final adminEmail = currentUser?.email;
    final adminPassword = passAdminC.text;

    try {
      if (isEditMode) {
        // --- LOGIKA UPDATE (SAMA SEPERTI SEBELUMNYA) ---
        final dataToUpdate = {
          'nama': namaC.text.trim(), 
          'jeniskelamin': jenisKelamin.value,
          'alias': "${jenisKelamin.value == "Laki-Laki" ? "Ustadz" : "Ustadzah"} ${namaC.text.trim()}",
          'role': jabatanTerpilih.value, 
          'tugas': tugasTerpilih.toList(),
        };
        await _firestore.collection("Sekolah").doc(configC.idSekolah).collection('pegawai').doc(_pegawaiToEdit!.uid).update(dataToUpdate);
        
        Get.back(result: true); // Kembali ke halaman list
        Get.snackbar('Berhasil', 'Data pegawai berhasil diperbarui.');

      } else {
        // --- LOGIKA CREATE ---
        
        // Validasi Admin Credentials
        if (currentUser == null || adminEmail == null) {
           throw FirebaseAuthException(code: 'user-not-found', message: 'Sesi admin habis. Silakan login ulang.');
        }
        if (adminPassword.isEmpty) {
           throw Exception('Password admin tidak boleh kosong.');
        }

        // 1. Re-authenticate Admin (Memastikan password benar)
        await currentUser.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: adminEmail, password: adminPassword)
        );
        
        // 2. Buat Akun Pegawai Baru
        // [PERINTAH DILAKSANAKAN] Password default: "telagailmu"
        UserCredential pegawaiCredential = await _auth.createUserWithEmailAndPassword(
          email: emailC.text.trim(), 
          password: 'telagailmu' 
        );
        
        // 3. Rebut Kembali Sesi Admin (CRITICAL STEP)
        // Login ulang sebagai admin agar bisa menulis ke Firestore
        await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);

        String uid = pegawaiCredential.user!.uid;
        final dataToSave = {
          'uid': uid, 
          'email': emailC.text.trim(), 
          'createdAt': FieldValue.serverTimestamp(), 
          'createdBy': adminEmail,
          'mustChangePassword': true,
          'nama': namaC.text.trim(), 
          'jeniskelamin': jenisKelamin.value,
          'alias': "${jenisKelamin.value == "Laki-Laki" ? "Ustadz" : "Ustadzah"} ${namaC.text.trim()}",
          'role': jabatanTerpilih.value, 
          'tugas': tugasTerpilih.toList(),
          'nip': '', 
          'noTelp': '', 
          'alamat': '', 
          'tglgabung': null, 
          'profileImageUrl': null, 
        };
        
        // Simpan ke Firestore
        await _firestore.collection("Sekolah").doc(configC.idSekolah).collection('pegawai').doc(uid).set(dataToSave);
        
        // Opsional: Kirim email verifikasi
        // await pegawaiCredential.user!.sendEmailVerification();
        
        Get.back(result: true); // Kembali ke halaman list
        Get.snackbar('Berhasil', 'Pegawai baru ditambahkan. Password default: telagailmu');
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Terjadi kesalahan: ${e.message}";
      if (e.code == 'wrong-password') msg = 'Password Admin salah.';
      if (e.code == 'email-already-in-use') msg = 'Email ini sudah terdaftar.';
      if (e.code == 'user-not-found') msg = 'Sesi admin tidak valid.';
      Get.snackbar('Gagal', msg, backgroundColor: Colors.red, colorText: Colors.white);
      
      // Jika sesi kacau, pastikan admin login balik (fail-safe)
      if (adminEmail != null && adminPassword.isNotEmpty && _auth.currentUser?.email != adminEmail) {
         try { await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword); } catch (_) {}
      }

    } catch (e) {
      Get.snackbar('Error Sistem', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoadingProses.value = false;
      passAdminC.clear();
      configC.isCreatingNewUser.value = false;
    }
  }

  String? validator(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName tidak boleh kosong.';
    return null;
  }
}


// // lib/app/modules/upsert_pegawai/controllers/upsert_pegawai_controller.dart (SEKOLAH - DIPERBAIKI)

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_model.dart';

// class UpsertPegawaiController extends GetxController {
//   // --- DEPENDENSI & KUNCI ---
//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();
//   final ConfigController configC = Get.find<ConfigController>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // --- FORM CONTROLLERS ---
//   late TextEditingController namaC;
//   late TextEditingController emailC;
//   late TextEditingController passAdminC;

//   // --- STATE LOADING & MODE ---
//   final RxBool isLoadingProses = false.obs;
//   PegawaiModel? _pegawaiToEdit;
//   bool get isEditMode => _pegawaiToEdit != null;

//   // --- STATE DATA FORM ---
//   final RxString jenisKelamin = "Laki-Laki".obs;
//   final Rxn<String> jabatanTerpilih = Rxn<String>();
//   final RxList<String> tugasTerpilih = <String>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     namaC = TextEditingController();
//     emailC = TextEditingController();
//     passAdminC = TextEditingController();

//     if (Get.arguments != null && Get.arguments is PegawaiModel) {
//       _pegawaiToEdit = Get.arguments;
//       _populateFieldsForEdit(_pegawaiToEdit!.uid);
//     }
//   }

//   Future<void> _populateFieldsForEdit(String uid) async {
//     // Ambil data lengkap dari Firestore untuk mode edit
//     final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(uid).get();
//     if(doc.exists) {
//       final data = doc.data()!;
//       namaC.text = data['nama'] ?? '';
//       emailC.text = data['email'] ?? '';
//       jenisKelamin.value = data['jeniskelamin'] ?? 'Laki-Laki';
//       jabatanTerpilih.value = data['role'];
//       tugasTerpilih.assignAll(List<String>.from(data['tugas'] ?? []));
//     }
//   }

//   @override
//   void onClose() {
//     namaC.dispose(); emailC.dispose(); passAdminC.dispose();
//     super.onClose();
//   }
  
//   void validasiDanProses() {
//     if (!formKey.currentState!.validate()) return;

//     if (isEditMode) {
//       _prosesSimpanData();
//     } else {
//       Get.defaultDialog(
//         title: 'Verifikasi Admin',
//         content: TextField(controller: passAdminC, obscureText: true, autofocus: true, 
//         decoration: const InputDecoration(labelText: 'Password Admin Anda')),
//         actions: [
//           OutlinedButton(onPressed: () => Get.back(), child: const Text('Batal')),
//           ElevatedButton(onPressed: _prosesSimpanData, child: const Text('Konfirmasi')),
//         ],
//       );
//     }
//   }

//   Future<void> _prosesSimpanData() async {
//     isLoadingProses.value = true;
//     final adminEmail = _auth.currentUser?.email;
//     final adminPassword = passAdminC.text;
    
//     configC.isCreatingNewUser.value = true;

//     try {
//       if (isEditMode) {
//         // --- LOGIKA UPDATE ---
//         final dataToUpdate = {
//           'nama': namaC.text.trim(), 'jeniskelamin': jenisKelamin.value,
//           'alias': "${jenisKelamin.value == "Laki-Laki" ? "Ustadz" : "Ustadzah"} ${namaC.text.trim()}",
//           'role': jabatanTerpilih.value, 'tugas': tugasTerpilih.toList(),
//         };
//         await _firestore.collection("Sekolah").doc(configC.idSekolah).collection('pegawai').doc(_pegawaiToEdit!.uid).update(dataToUpdate);
//         Get.back(result: true);
//         Get.snackbar('Berhasil', 'Data pegawai berhasil diperbarui.');

//       } else {
//         // --- LOGIKA CREATE YANG AMAN ---
//         if (adminEmail == null || adminPassword.isEmpty) throw Exception('Sesi admin tidak valid atau password kosong.');
//         Get.back();

//         await _auth.currentUser!.reauthenticateWithCredential(EmailAuthProvider.credential(email: adminEmail, password: adminPassword));
        
//         UserCredential pegawaiCredential = await _auth.createUserWithEmailAndPassword(email: emailC.text.trim(), password: 'password123');
        
//         // --- PERBAIKAN KRUSIAL: REBUT KEMBALI SESI ADMIN ---
//         await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);

//         String uid = pegawaiCredential.user!.uid;
//         final dataToSave = {
//           // --- Data Inti (Tidak Berubah) ---
//           'uid': uid, 'email': emailC.text.trim(), 'createdAt': FieldValue.serverTimestamp(), 'createdBy': adminEmail,
//           'mustChangePassword': true,
//           'nama': namaC.text.trim(), 'jeniskelamin': jenisKelamin.value,
//           'alias': "${jenisKelamin.value == "Laki-Laki" ? "Ustadz" : "Ustadzah"} ${namaC.text.trim()}",
//           'role': jabatanTerpilih.value, 'tugas': tugasTerpilih.toList(),

//           // --- [PERBAIKAN] Tambahkan field baru dengan nilai default ---
//           'nip': '', // Default: string kosong
//           'noTelp': '', // Default: string kosong
//           'alamat': '', // Default: string kosong
//           'tglgabung': null, // Default: null
//           'profileImageUrl': null, // Default: null
//           // --- AKHIR PERBAIKAN ---
//         };
//         await _firestore.collection("Sekolah").doc(configC.idSekolah).collection('pegawai').doc(uid).set(dataToSave);
        
//         // Kirim email verifikasi untuk pegawai (sesuai PR kita)
//         await pegawaiCredential.user!.sendEmailVerification();
        
//         Get.back(result: true);
//         Get.snackbar('Berhasil', 'Pegawai baru berhasil ditambahkan.');
//       }
//     } on FirebaseAuthException catch (e) {
//       String msg = "Terjadi kesalahan.";
//       if (e.code == 'wrong-password') msg = 'Password Admin salah.';
//       if (e.code == 'email-already-in-use') msg = 'Email ini sudah terdaftar.';
//       Get.snackbar('Gagal', msg);
//     } catch (e) {
//       Get.snackbar('Error Sistem', e.toString());
//     } finally {
//       isLoadingProses.value = false;
//       passAdminC.clear();
//       configC.isCreatingNewUser.value = false;
//     }
//   }

//   String? validator(String? value, String fieldName) {
//     if (value == null || value.isEmpty) return '$fieldName tidak boleh kosong.';
//     return null;
//   }
// }