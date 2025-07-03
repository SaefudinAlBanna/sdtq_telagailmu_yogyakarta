// import_siswa_excel_controller.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImportSiswaExcelController extends GetxController {
  // --- State Reaktif untuk UI ---
  final isLoading = false.obs;
  final progressMessage = 'Siap untuk mengimpor data siswa.'.obs;
  final successfulImports = 0.obs;
  final failedImports = 0.obs;

  // --- Instance Firebase ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Konfigurasi ---
  final String idSekolah = "P9984539";
  final String defaultPassword = "telagailmu";

  Future<void> importAndCreateAccounts() async {
    isLoading.value = true;
    progressMessage.value = "Memulai proses impor...";
    successfulImports.value = 0;
    failedImports.value = 0;

    try {
      // 1. MEMILIH FILE
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) {
        Get.snackbar("Dibatalkan", "Pemilihan file dibatalkan.");
        isLoading.value = false;
        return;
      }
      
      progressMessage.value = "Membaca file Excel...";
      String? filePath = result.files.single.path;
      var bytes = File(filePath!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      var sheet = excel.tables[excel.tables.keys.first]!;
      int totalRows = sheet.maxRows - 1;

      // 2. ITERASI SETIAP BARIS DATA
      for (var i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        
        // Asumsi format kolom: A=NISN, B=Nama, C=Email, D=SPP
        String? nisn = row[0]?.value?.toString().trim();
        String? nama = row[1]?.value?.toString().trim();
        String? email = row[2]?.value?.toString().trim();
        // Coba parse SPP sebagai angka, jika gagal beri nilai 0
        num spp = num.tryParse(row[3]?.value?.toString() ?? '') ?? 0;

        // Validasi data penting
        if (nisn == null || nisn.isEmpty || nama == null || nama.isEmpty || email == null || !GetUtils.isEmail(email)) {
          failedImports.value++;
          print("Data tidak valid di baris ${i + 1}: NISN, Nama, atau Email kosong/salah format.");
          continue; // Lanjut ke baris berikutnya
        }

        progressMessage.value = "Memproses $nama ($email)...";

        try {
          // 3. BUAT AKUN DI FIREBASE AUTHENTICATION
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: defaultPassword,
          );
          
          User? newUser = userCredential.user;

          if (newUser != null) {
            // 4. KIRIM EMAIL VERIFIKASI
            await newUser.sendEmailVerification();
            
            // 5. SIMPAN DATA KE FIRESTORE
            await _firestore
                .collection("Sekolah")
                .doc(idSekolah)
                .collection('siswa')
                .doc(nisn) // NISN sebagai ID dokumen
                .set({
                  'uid': newUser.uid, // Simpan UID dari Auth, ini penting untuk relasi
                  'nisn': nisn,
                  'nama': nama,
                  'email': email,
                  'status' : "baru",
                  'spp': spp,
                  'role': 'siswa', // Tambahan field role, sangat berguna
                  'createdAt': FieldValue.serverTimestamp(),
                });
            
            successfulImports.value++;
          }
        } on FirebaseAuthException catch (e) {
          failedImports.value++;
          // Tangani error spesifik, misal email sudah terdaftar
          if (e.code == 'email-already-in-use') {
            print("Gagal untuk $email: Alamat email sudah terdaftar.");
             progressMessage.value = "Gagal: $email sudah ada.";
          } else {
            print("Gagal untuk $email: ${e.message}");
             progressMessage.value = "Gagal: ${e.code}";
          }
        } catch (e) {
           failedImports.value++;
           print("Terjadi error umum pada data $nama: $e");
        }
      }

      Get.snackbar(
        "Proses Selesai",
        "Berhasil: ${successfulImports.value}, Gagal: ${failedImports.value} dari total $totalRows siswa.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

    } catch (e) {
      print(e);
      Get.snackbar("Error Fatal", "Terjadi kesalahan: ${e.toString()}", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
      progressMessage.value = 'Siap untuk impor berikutnya.';
    }
  }
}