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
import 'dart:typed_data';
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

  // Future<void> _processExcel() async {
  //   // ---- VALIDASI AWAL ----
  //   if (passAdminC.text.isEmpty) {
  //     Get.snackbar("Gagal", "Password admin wajib diisi.");
  //     return;
  //   }

  //   final String? emailAdmin = _auth.currentUser?.email;
  //   if (emailAdmin == null) {
  //     Get.snackbar("Error", "Sesi admin tidak valid. Silakan login ulang.");
  //     return;
  //   }

  //   // ---- PERSIAPAN PROSES ----
  //   isLoading.value = true;

  //   // [PENTING] AKTIFKAN MODE SENYAP
  //   // Mencegah ConfigController bereaksi/redirect saat auth berubah sementara
  //   configC.isCreatingNewUser.value = true;

  //   final adminPassword = passAdminC.text;

  //   try {
  //     // ---- BACA FILE EXCEL ----
  //     // Menggunakan readAsBytesSync untuk performa file lokal (Mobile/Desktop)
  //     var bytes = File(pickedFile.value!.path!).readAsBytesSync();
  //     var excel = Excel.decodeBytes(bytes);
      
  //     // Mengambil sheet pertama
  //     var sheet = excel.tables[excel.tables.keys.first]!;

  //     // Validasi Header Excel (Baris ke-0)
  //     if (sheet.rows.isEmpty ||
  //         sheet.rows.first[0]?.value.toString().trim() != 'NISN' ||
  //         sheet.rows.first[1]?.value.toString().trim() != 'Nama' ||
  //         sheet.rows.first[2]?.value.toString().trim() != 'SPP') {
  //       throw Exception("Format file tidak sesuai. Pastikan header kolom: NISN, Nama, SPP.");
  //     }

  //     totalRows.value = sheet.maxRows - 1;

  //     // ---- PROSES PERULANGAN SETIAP BARIS (Mulai dari index 1 karena index 0 adalah Header) ----
  //     for (var i = 1; i < sheet.maxRows; i++) {
  //       processedRows.value = i;
  //       var row = sheet.rows[i];

  //       // --- [FIX 1] PEMBERSIHAN NISN ---
  //       // Mengambil nilai, ubah ke string, dan trim spasi
  //       String nisnRaw = row[0]?.value?.toString().trim() ?? '';
        
  //       // Cek apakah karakter pertama adalah tanda petik ('), jika ya, buang.
  //       if (nisnRaw.startsWith("'")) {
  //         nisnRaw = nisnRaw.substring(1);
  //       }
        
  //       final nisn = nisnRaw;
  //       // --------------------------------

  //       // Ambil Nama
  //       final nama = row[1]?.value?.toString().trim();

  //       // --- [FIX 2] PEMBERSIHAN SPP ---
  //       // Membersihkan input SPP dari karakter non-angka (seperti "Rp", ".", ",", " ") 
  //       // sebelum di-parse ke number agar tidak error.
  //       String sppRaw = row[2]?.value?.toString().trim() ?? '';
  //       String sppClean = sppRaw.replaceAll(RegExp(r'[^0-9]'), ''); // Hanya ambil angka 0-9
  //       final spp = num.tryParse(sppClean) ?? 0;
  //       // -------------------------------

  //       // Validasi Data Kosong
  //       if (nisn.isEmpty || nama == null || nama.isEmpty) {
  //         errorCount.value++;
  //         errorDetails.add("Baris ${i + 1}: Data NISN atau Nama kosong/tidak valid.");
  //         continue;
  //       }

  //       final String emailPalsu = "$nisn@telagailmu.com"; 

  //       try {
  //         // ---- SIKLUS UTAMA PER SISWA ----
          
  //         // 1. Buat user baru (Sesi Auth otomatis pindah ke user baru ini)
  //         UserCredential siswaCredential = await _auth.createUserWithEmailAndPassword(
  //             email: emailPalsu,
  //             password: 'telagailmu' // Password default
  //         );

  //         // 2. Rebut kembali sesi Admin (Login ulang sebagai admin agar bisa tulis ke Firestore)
  //         await _auth.signInWithEmailAndPassword(email: emailAdmin, password: adminPassword);

  //         // 3. Simpan data ke Firestore
  //         String uidSiswa = siswaCredential.user!.uid;
          
  //         await _firestore.collection("Sekolah").doc(configC.idSekolah).collection('siswa').doc(uidSiswa).set({
  //           "uid": uidSiswa,
  //           "nisn": nisn, // NISN yang sudah bersih dari tanda petik
  //           "namaLengkap": nama,
  //           "email": emailPalsu,
  //           "spp": spp,
  //           "mustChangePassword": true,
  //           "statusSiswa": "Aktif",
  //           "isProfileComplete": false,
  //           "createdAt": FieldValue.serverTimestamp(),
  //           "createdBy": emailAdmin,
  //           "kelasId": null,
  //         });

  //         successCount.value++;

  //       } on FirebaseAuthException catch (e) {
  //         errorCount.value++;
          
  //         String errorMsg;
  //         if (e.code == 'email-already-in-use') {
  //           errorMsg = "NISN sudah terdaftar.";
  //         } else if (e.code == 'weak-password') {
  //           errorMsg = "Password terlalu lemah.";
  //         } else {
  //           errorMsg = "Gagal membuat user: ${e.message}";
  //         }
          
  //         errorDetails.add("Baris ${i + 1} ($nisn): $errorMsg");

  //         // PENTING: Jika create user gagal (misal email duplikat), sesi mungkin masih stuck atau error.
  //         // Kita pastikan sesi admin tetap aktif untuk iterasi selanjutnya.
  //         if (_auth.currentUser?.email != emailAdmin) {
  //            await _auth.signInWithEmailAndPassword(email: emailAdmin, password: adminPassword);
  //         }
  //       }
  //     }

  //     // ---- PROSES SELESAI ----
  //     Get.back(); // Tutup dialog password
  //     Get.snackbar(
  //       "Selesai", 
  //       "Proses import selesai.\nBerhasil: ${successCount.value}\nGagal: ${errorCount.value}", 
  //       duration: const Duration(seconds: 5),
  //       backgroundColor: Colors.green,
  //       colorText: Colors.white
  //     );

  //   } catch (e) {
  //     // ---- PENANGANAN ERROR FATAL (Misal File Corrupt / Password Salah) ----
  //     Get.back(); // Tutup dialog password jika masih terbuka
      
  //     // Reset progress jika crash di tengah jalan
  //     // resetState(); // Opsional: bisa di-rem jika ingin user melihat progress terakhir sebelum crash
      
  //     Get.snackbar(
  //       "Gagal", 
  //       "Terjadi kesalahan: ${e.toString()}",
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //       duration: const Duration(seconds: 5)
  //     );
      
  //   } finally {
  //     // ---- PEMBERSIHAN ----
  //     isLoading.value = false;
  //     passAdminC.clear();

  //     // [PENTING] MATIKAN MODE SENYAP
  //     // Kembalikan ConfigController ke mode normal agar aplikasi bereaksi normal terhadap perubahan auth user
  //     configC.isCreatingNewUser.value = false;
  //   }
  // }

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

    // [PENTING] AKTIFKAN MODE SENYAP
    // Mencegah ConfigController bereaksi/redirect saat auth berubah sementara
    configC.isCreatingNewUser.value = true;

    final adminPassword = passAdminC.text;

    try {
      // ---- BACA FILE EXCEL ----
      // [PERBAIKAN] Pastikan path tidak null
      if (pickedFile.value?.path == null) {
        throw Exception("Gagal membaca file. Path tidak ditemukan di perangkat.");
      }

      File file = File(pickedFile.value!.path!);
      
      // [PERBAIKAN] Cek eksistensi file sebelum membaca
      if (!file.existsSync()) {
        throw Exception("File tidak ditemukan. Coba pilih ulang file.");
      }

      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      
      // Mengambil sheet pertama
      var sheet = excel.tables[excel.tables.keys.first]!;

      // Validasi Header Excel (Baris ke-0)
      if (sheet.rows.isEmpty ||
          sheet.rows.first[0]?.value.toString().trim() != 'NISN' ||
          sheet.rows.first[1]?.value.toString().trim() != 'Nama' ||
          sheet.rows.first[2]?.value.toString().trim() != 'SPP') {
        throw Exception("Format file tidak sesuai. Pastikan header kolom: NISN, Nama, SPP.");
      }

      totalRows.value = sheet.maxRows - 1;

      // ---- PROSES PERULANGAN SETIAP BARIS (Mulai dari index 1 karena index 0 adalah Header) ----
      for (var i = 1; i < sheet.maxRows; i++) {
        processedRows.value = i;
        var row = sheet.rows[i];

        // --- [FIX 1] PEMBERSIHAN NISN ---
        // Mengambil nilai, ubah ke string, dan trim spasi
        String nisnRaw = row[0]?.value?.toString().trim() ?? '';
        
        // Cek apakah karakter pertama adalah tanda petik ('), jika ya, buang.
        if (nisnRaw.startsWith("'")) {
          nisnRaw = nisnRaw.substring(1);
        }
        
        final nisn = nisnRaw;
        // --------------------------------

        // Ambil Nama
        final nama = row[1]?.value?.toString().trim();

        // --- [FIX 2] PEMBERSIHAN SPP ---
        // Membersihkan input SPP dari karakter non-angka (seperti "Rp", ".", ",", " ") 
        // sebelum di-parse ke number agar tidak error.
        String sppRaw = row[2]?.value?.toString().trim() ?? '';
        String sppClean = sppRaw.replaceAll(RegExp(r'[^0-9]'), ''); // Hanya ambil angka 0-9
        final spp = num.tryParse(sppClean) ?? 0;
        // -------------------------------

        // Validasi Data Kosong
        if (nisn.isEmpty || nama == null || nama.isEmpty) {
          errorCount.value++;
          errorDetails.add("Baris ${i + 1}: Data NISN atau Nama kosong/tidak valid.");
          continue;
        }

        final String emailPalsu = "$nisn@telagailmu.com"; 

        try {
          // ---- SIKLUS UTAMA PER SISWA ----
          
          // 1. Buat user baru (Sesi Auth otomatis pindah ke user baru ini)
          UserCredential siswaCredential = await _auth.createUserWithEmailAndPassword(
              email: emailPalsu,
              password: 'telagailmu' // Password default
          );

          // 2. Rebut kembali sesi Admin (Login ulang sebagai admin agar bisa tulis ke Firestore)
          await _auth.signInWithEmailAndPassword(email: emailAdmin, password: adminPassword);

          // 3. Simpan data ke Firestore
          String uidSiswa = siswaCredential.user!.uid;
          
          await _firestore.collection("Sekolah").doc(configC.idSekolah).collection('siswa').doc(uidSiswa).set({
            "uid": uidSiswa,
            "nisn": nisn, // NISN yang sudah bersih dari tanda petik
            "namaLengkap": nama,
            "email": emailPalsu,
            "spp": spp,
            "mustChangePassword": true,
            "statusSiswa": "Aktif",
            "isProfileComplete": false,
            "createdAt": FieldValue.serverTimestamp(),
            "createdBy": emailAdmin,
            "kelasId": null,
          });

          successCount.value++;

        } on FirebaseAuthException catch (e) {
          errorCount.value++;
          
          String errorMsg;
          if (e.code == 'email-already-in-use') {
            errorMsg = "NISN sudah terdaftar.";
          } else if (e.code == 'weak-password') {
            errorMsg = "Password terlalu lemah.";
          } else {
            errorMsg = "Gagal membuat user: ${e.message}";
          }
          
          errorDetails.add("Baris ${i + 1} ($nisn): $errorMsg");

          // PENTING: Jika create user gagal (misal email duplikat), sesi mungkin masih stuck atau error.
          // Kita pastikan sesi admin tetap aktif untuk iterasi selanjutnya.
          if (_auth.currentUser?.email != emailAdmin) {
             await _auth.signInWithEmailAndPassword(email: emailAdmin, password: adminPassword);
          }
        }
      }

      // ---- PROSES SELESAI ----
      Get.back(); // Tutup dialog password
      Get.snackbar(
        "Selesai", 
        "Proses import selesai.\nBerhasil: ${successCount.value}\nGagal: ${errorCount.value}", 
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
        colorText: Colors.white
      );

    } catch (e) {
      // ---- PENANGANAN ERROR FATAL (Misal File Corrupt / Password Salah) ----
      Get.back(); // Tutup dialog password jika masih terbuka
      
      // Reset progress jika crash di tengah jalan
      // resetState(); // Opsional: bisa di-rem jika ingin user melihat progress terakhir sebelum crash
      
      Get.snackbar(
        "Gagal", 
        "Terjadi kesalahan: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5)
      );
      
    } finally {
      // ---- PEMBERSIHAN ----
      isLoading.value = false;
      passAdminC.clear();

      // [PENTING] MATIKAN MODE SENYAP
      // Kembalikan ConfigController ke mode normal agar aplikasi bereaksi normal terhadap perubahan auth user
      configC.isCreatingNewUser.value = false;
    }
  }

  // Future<void> downloadTemplate() async {
  //   isDownloading.value = true;
  //   try {
  //     var excel = Excel.createExcel();
  //     Sheet sheetObject = excel['Sheet1'];
  //     CellStyle headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
  //     var headers = ["NISN", "Nama", "SPP"];
  //     for (var i = 0; i < headers.length; i++) {
  //       var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
  //       cell.value = TextCellValue(headers[i]);
  //       cell.cellStyle = headerStyle;
  //     }
  //     sheetObject.appendRow([
  //       TextCellValue("1234567890"),
  //       TextCellValue("Fulan bin Fulan"),
  //       IntCellValue(250000)
  //     ]);
  //     String? outputFile = await FilePicker.platform.saveFile(dialogTitle: 'Simpan Template Siswa', fileName: 'template_import_siswa.xlsx');
  //     if (outputFile != null) {
  //       List<int>? fileBytes = excel.encode();
  //       if (fileBytes != null) {
  //         File(outputFile)..writeAsBytesSync(fileBytes);
  //         Get.snackbar("Berhasil", "Template berhasil diunduh.", backgroundColor: Colors.green, colorText: Colors.white);
  //       }
  //     }
  //   } catch (e) {
  //     Get.snackbar("Error", "Gagal membuat template: $e");
  //   } finally {
  //     isDownloading.value = false;
  //   }
  // }

  Future<void> downloadTemplate() async {
    isDownloading.value = true;
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      
      // Styling Header
      CellStyle headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
      var headers = ["NISN", "Nama", "SPP"];
      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }
      
      // Data Contoh
      sheetObject.appendRow([
        TextCellValue("1234567890"),
        TextCellValue("Fulan bin Fulan"),
        IntCellValue(250000)
      ]);

      // 1. Encode file Excel ke dalam Bytes
      List<int>? fileBytes = excel.encode();
      
      if (fileBytes != null) {
        Uint8List data = Uint8List.fromList(fileBytes);

        // 2. Panggil FilePicker dengan Parameter yang TEPAT untuk setiap OS
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Template Siswa',
          fileName: 'template_import_siswa.xlsx',
          // [KUNCI PERBAIKAN] Android/iOS butuh 'bytes' dikirim langsung ke sini
          bytes: data, 
        );

        // 3. Logika Tambahan untuk Windows/Desktop
        // Di Desktop, saveFile hanya mengembalikan Path, tapi TIDAK menulis filenya.
        // Jadi kita harus menulisnya secara manual.
        if (outputFile != null) {
           // Cek jika platform BUKAN Android dan BUKAN iOS (artinya Desktop)
           if (!Platform.isAndroid && !Platform.isIOS) {
             File(outputFile)..writeAsBytesSync(data);
           }
           
           Get.snackbar("Berhasil", "Template berhasil diunduh.", backgroundColor: Colors.green, colorText: Colors.white);
        } else {
           // Pada Android, jika user membatalkan dialog, outputFile null. 
           // Tapi jika berhasil, file_picker Android biasanya menangani notifikasi suksesnya sendiri atau mengembalikan path.
           // Kita tampilkan snackbar hanya jika di Android (karena outputFile mungkin null meski sukses di beberapa versi plugin mobile)
           if (Platform.isAndroid || Platform.isIOS) {
              // Opsi: Tampilkan pesan umum atau biarkan sistem menangani
           }
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat template: $e");
    } finally {
      isDownloading.value = false;
    }
  }
}