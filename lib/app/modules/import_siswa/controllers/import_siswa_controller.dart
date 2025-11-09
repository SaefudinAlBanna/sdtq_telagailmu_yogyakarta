// lib/app/modules/import_siswa/controllers/import_siswa_controller.dart (SEKOLAH - DIPERBAIKI)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';

import 'dart:io' show Platform; // Untuk deteksi OS (Windows, Android, dll)
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk deteksi Web

class ImportSiswaController extends GetxController {
  // --- DEPENDENSI ---
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final isPasswordVisible = false.obs;
  
  // --- STATE UI & PROSES ---
  final isLoading = false.obs;
  final isDownloading = false.obs;
  final RxString selectedFileName = 'Tidak ada file dipilih'.obs;
  final Rx<PlatformFile?> pickedFile = Rx<PlatformFile?>(null);

  // --- STATE HASIL IMPORT ---
  final RxInt totalRows = 0.obs;
  final RxInt processedRows = 0.obs;
  final RxInt successCount = 0.obs;
  final RxInt errorCount = 0.obs;
  final RxList<String> errorDetails = <String>[].obs;

  late TextEditingController passAdminC;

  @override
  void onInit() {
    super.onInit();
    passAdminC = TextEditingController();
  }

  @override
  void onClose() {
    passAdminC.dispose();
    super.onClose();
  }

  void resetState() {
    isLoading.value = false;
    selectedFileName.value = 'Tidak ada file dipilih';
    totalRows.value = 0;
    processedRows.value = 0;
    successCount.value = 0;
    errorCount.value = 0;
    errorDetails.clear();
    pickedFile.value = null;
  }

  Future<void> pickFile() async {
    resetState();
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result != null) {
      pickedFile.value = result.files.first;
      selectedFileName.value = pickedFile.value!.name;
    }
  }

  void startImport() {
    if (pickedFile.value == null) {
      Get.snackbar("Gagal", "Silakan pilih file Excel terlebih dahulu.");
      return;
    }

    Get.defaultDialog(
      title: 'Verifikasi Admin',
      content: Column(
        mainAxisSize: MainAxisSize.min, // Agar kolom tidak terlalu besar
        children: [
          const Text('Masukkan password Anda untuk melanjutkan.'),
          const SizedBox(height: 16),
          // Ganti TextField sederhana dengan Obx
          Obx(() => TextField(
                controller: passAdminC,
                obscureText: !isPasswordVisible.value, // <-- hubungkan ke state
                autocorrect: false,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Password Admin',
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
        ],
      ),
      confirm: Obx(() => ElevatedButton(
            onPressed: isLoading.value ? null : _processExcel,
            child: Text(isLoading.value ? 'MEMPROSES...' : 'Mulai Import'),
          )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
    );
  }

  Future<void> _processExcel() async {
    // ---- VALIDASI AWAL ----
    if (passAdminC.text.isEmpty) {
      Get.snackbar("Gagal", "Password admin wajib diisi.");
      return;
    }

    final String? emailAdmin = _auth.currentUser?.email;
    if (emailAdmin == null) {
      Get.snackbar("Error", "Sesi admin tidak valid. Silakan login ulang.");
      return;
    }
    
    // ---- PERSIAPAN PROSES ----
    isLoading.value = true;
    
    // [PERBAIKAN KUNCI 1] AKTIFKAN MODE SENYAP
    // Ini akan mencegah ConfigController bereaksi terhadap perubahan auth sementara.
    configC.isCreatingNewUser.value = true;
    
    final adminPassword = passAdminC.text;

    try {
      // ---- BACA FILE EXCEL ----
      // Catatan: Kode ini untuk platform Mobile/Desktop (dart:io).
      // Untuk web, Anda perlu menggunakan `pickedFile.value!.bytes`.
      var bytes = File(pickedFile.value!.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      var sheet = excel.tables[excel.tables.keys.first]!;
      
      // Validasi Header Excel
      if (sheet.rows.isEmpty || 
          sheet.rows.first[0]?.value.toString().trim() != 'NISN' ||
          sheet.rows.first[1]?.value.toString().trim() != 'Nama' ||
          sheet.rows.first[2]?.value.toString().trim() != 'SPP') {
        throw Exception("Format file tidak sesuai. Pastikan kolom: NISN, Nama, SPP.");
      }
      
      totalRows.value = sheet.maxRows - 1;

      // ---- PROSES PERULANGAN SETIAP BARIS ----
      for (var i = 1; i < sheet.maxRows; i++) {
        processedRows.value = i;
        var row = sheet.rows[i];

        final nisn = row[0]?.value?.toString().trim();
        final nama = row[1]?.value?.toString().trim();
        final spp = num.tryParse(row[2]?.value?.toString().trim() ?? '') ?? 0;

        if (nisn == null || nama == null || nisn.isEmpty || nama.isEmpty) {
          errorCount.value++;
          errorDetails.add("Baris ${i + 1}: Data NISN/Nama tidak valid.");
          continue;
        }

        final String emailPalsu = "$nisn@telagailmu.com"; // Sesuaikan domain jika perlu

        try {
          // ---- SIKLUS UTAMA PER SISWA ----
          // 1. Buat user (sesi berpindah ke siswa)
          UserCredential siswaCredential = await _auth.createUserWithEmailAndPassword(
            email: emailPalsu,
            password: 'telagailmu' // Password default
          );
          
          // 2. Rebut kembali sesi Admin (sesi kembali ke admin)
          await _auth.signInWithEmailAndPassword(email: emailAdmin, password: adminPassword);
          
          // 3. Simpan data ke Firestore (operasi aman sebagai admin)
          String uidSiswa = siswaCredential.user!.uid;
          await _firestore.collection("Sekolah").doc(configC.idSekolah).collection('siswa').doc(uidSiswa).set({
              "uid": uidSiswa,
              "nisn": nisn,
              "namaLengkap": nama, // Sesuaikan field 'nama' menjadi 'namaLengkap'
              "email": emailPalsu,
              "spp": spp,
              "mustChangePassword": true, // Ganti nama field agar konsisten
              "statusSiswa": "Aktif", // Ganti nama field
              "isProfileComplete": false, // Tambah field agar konsisten
              "createdAt": FieldValue.serverTimestamp(), // Ganti nama field
              "createdBy": emailAdmin, // Ganti nama field
              'kelasId': null,

          //     'namaLengkap': nama, 'nisn': nisn, 'spp': spp, 'email': emailPalsu,
          // 'isProfileComplete': false, 'mustChangePassword': true, 'statusSiswa': "Aktif",
          // 'createdAt': FieldValue.serverTimestamp(), 'createdBy': emailAdmin, 'uid': uidSiswa,
          // 'kelasId': null,
          });
          successCount.value++;
          
        } on FirebaseAuthException catch (e) {
            errorCount.value++;
            String errorMsg = e.code == 'email-already-in-use' ? "NISN (email) sudah terdaftar." : "Gagal membuat user.";
            errorDetails.add("Baris ${i + 1} ($nisn): $errorMsg");
            
            // Coba pulihkan sesi admin jika pembuatan user gagal
            await _auth.signInWithEmailAndPassword(email: emailAdmin, password: adminPassword);
        }
      }
      
      // ---- PROSES SELESAI ----
      Get.back(); // Tutup dialog password
      Get.snackbar("Selesai", "Proses import selesai. ${successCount.value} berhasil, ${errorCount.value} gagal.", duration: const Duration(seconds: 5));

    } catch (e) {
      // ---- PENANGANAN ERROR FATAL ----
      Get.back(); // Tutup dialog password jika masih terbuka
      resetState();
      Get.snackbar("Error Fatal", "Gagal memproses file: ${e.toString()}");
    } finally {
      // ---- PEMBERSIHAN ----
      isLoading.value = false;
      passAdminC.clear();
      
      // [PERBAIKAN KUNCI 2] MATIKAN MODE SENYAP
      // Kembalikan ConfigController ke mode normal setelah semua selesai.
      configC.isCreatingNewUser.value = false;
    }
  }

  Future<void> downloadTemplate() async {
    isDownloading.value = true;
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      CellStyle headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
      var headers = ["NISN", "Nama", "SPP"];
      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }
      sheetObject.appendRow([
        TextCellValue("1234567890"),
        TextCellValue("Fulan bin Fulan"),
        IntCellValue(250000)
      ]);
      String? outputFile = await FilePicker.platform.saveFile(dialogTitle: 'Simpan Template Siswa', fileName: 'template_import_siswa.xlsx');
      if (outputFile != null) {
        List<int>? fileBytes = excel.encode();
        if (fileBytes != null) {
          File(outputFile)..writeAsBytesSync(fileBytes);
          Get.snackbar("Berhasil", "Template berhasil diunduh.", backgroundColor: Colors.green, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat template: $e");
    } finally {
      isDownloading.value = false;
    }
  }
}