// lib/app/modules/upsert_siswa/controllers/upsert_siswa_controller.dart (SEKOLAH - FINAL)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_model.dart';

import 'dart:io' show Platform; // Untuk deteksi OS (Windows, Android, dll)
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk deteksi Web

class UpsertSiswaController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController namaC, nisnC, sppC, passAdminC;
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  SiswaModel? _siswaToEdit;
  bool get isEditMode => _siswaToEdit != null;

  @override
  void onInit() {
    super.onInit();
    namaC = TextEditingController();
    nisnC = TextEditingController();
    sppC = TextEditingController();
    passAdminC = TextEditingController();
    if (Get.arguments != null && Get.arguments is SiswaModel) {
      _siswaToEdit = Get.arguments;
      namaC.text = _siswaToEdit!.namaLengkap;
      nisnC.text = _siswaToEdit!.nisn;
      sppC.text = _siswaToEdit!.spp?.toString() ?? '0';
    }
  }

  @override
  void onClose() {
    namaC.dispose();
    nisnC.dispose();
    sppC.dispose();
    passAdminC.dispose();
    super.onClose();
  }

  void validasiDanProses() {
    if (!formKey.currentState!.validate()) return;
    if (isEditMode) {
      _prosesSimpanData();
    } else {
      Get.defaultDialog(
        title: 'Verifikasi Admin',
        // Ganti TextField sederhana dengan Obx
        content: Obx(() => TextField(
              controller: passAdminC,
              autofocus: true,
              obscureText: !isPasswordVisible.value, // <-- hubungkan ke state
              decoration: InputDecoration(
                labelText: 'Password Admin Anda',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton( // <-- tambahkan ikon mata
                  icon: Icon(
                    isPasswordVisible.value 
                      ? Icons.visibility_off 
                      : Icons.visibility,
                  ),
                  onPressed: () {
                    isPasswordVisible.toggle(); // <-- aksi untuk mengubah state
                  },
                ),
              ),
            )),
        actions: [
          OutlinedButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(onPressed: _prosesSimpanData, child: const Text('Konfirmasi')),
        ],
      );
    }
  }

   Future<void> _prosesSimpanData() async {
    isLoading.value = true;
    
    // --- PERBAIKAN 1: AKTIFKAN MODE SENYAP ---
    configC.isCreatingNewUser.value = true;

    final adminEmail = _auth.currentUser?.email;
    final adminPassword = passAdminC.text;

    try {
      if (isEditMode) {
        // Logika untuk mode edit tidak perlu otentikasi ulang dan tidak berubah.
        final dataToUpdate = {
          'namaLengkap': namaC.text,
          'spp': num.tryParse(sppC.text) ?? 0
        };
        await _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('siswa').doc(_siswaToEdit!.uid).update(dataToUpdate);
        
        Get.back(result: true); // Tutup view upsert
        Get.snackbar('Berhasil', 'Data siswa berhasil diperbarui.');
      
      } else {
        Get.back(); // Tutup dialog
        if (adminEmail == null || adminPassword.isEmpty) {
          throw Exception('Sesi admin tidak valid atau password kosong.');
        }

        final emailSiswa = "${nisnC.text}@telagailmu.com";

        // LANGKAH 1: Buat user siswa di Firebase Auth.
        // Setelah ini, sesi aktif akan berpindah ke user siswa.
        UserCredential cred = await _auth.createUserWithEmailAndPassword(email: "${nisnC.text}@telagailmu.com", password: 'telagailmu');
        await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);

        // LANGKAH 3: Simpan data siswa ke Firestore.
        // Sekarang kita sudah login sebagai admin lagi, jadi operasi ini aman.
        final dataSiswa = {
          'namaLengkap': namaC.text, 'nisn': nisnC.text, 'spp': num.tryParse(sppC.text) ?? 0, 'email': emailSiswa,
          'isProfileComplete': false, 'mustChangePassword': true, 'statusSiswa': "Aktif",
          'createdAt': FieldValue.serverTimestamp(), 'createdBy': adminEmail, 'uid': cred.user!.uid,
          'kelasId': null,
        };
        await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(cred.user!.uid).set(dataSiswa);
        
        Get.back(result: true);
        Get.snackbar('Berhasil', 'Siswa baru berhasil ditambahkan.');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Terjadi kesalahan.';
      if (e.code == 'wrong-password') msg = 'Password Admin salah.';
      if (e.code == 'email-already-in-use') msg = 'NISN ini sudah terdaftar sebagai user.';
      Get.snackbar('Gagal', msg);

      // Pastikan sesi admin tetap aktif bahkan jika terjadi error
      if (adminEmail != null && adminPassword.isNotEmpty) {
        try {
          await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);
        } catch (_) {
          // Abaikan error di sini, ini hanya upaya pemulihan.
        }
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      
      // --- PERBAIKAN 2: MATIKAN MODE SENYAP & PERIKSA CONTROLLER ---
      // Selalu matikan mode senyap, apapun yang terjadi.
      configC.isCreatingNewUser.value = false;

      // Periksa apakah controller masih ada sebelum membersihkan text field
      if (!isClosed) {
        passAdminC.clear();
      }
    }
  }
}