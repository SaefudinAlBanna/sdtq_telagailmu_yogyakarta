import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/storage_controller.dart';

class ProfileController extends GetxController {
  final AuthController authC = Get.find<AuthController>();
  final ConfigController configC = Get.find<ConfigController>();
  final StorageController storageC = Get.find<StorageController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController namaController = TextEditingController();
  TextEditingController aliasController = TextEditingController();
  TextEditingController noTelpController = TextEditingController();
  TextEditingController nipController = TextEditingController();
  TextEditingController alamatController = TextEditingController();
  TextEditingController tglGabungController = TextEditingController();

  // --- STATE REAKTIF ---
  final RxBool isLoading = false.obs;
  final Rxn<File> pickedImage = Rxn<File>();
  final RxString jenisKelamin = "".obs;
  final Rxn<DateTime> selectedJoinDate = Rxn<DateTime>();

  

  @override
  void onInit() {
    super.onInit();
    
    // Panggil fungsi untuk mengisi data saat pertama kali controller dibuat
    _populateDataFromConfig();

    // --- [PERBAIKAN KRUSIAL] ---
    // Buat listener yang akan berjalan SETIAP KALI status di ConfigController berubah.
    ever(configC.status, (AppStatus status) {
      // Jika status berubah menjadi authenticated (misalnya setelah login berhasil),
      // panggil kembali fungsi untuk mengisi data.
      if (status == AppStatus.authenticated) {
        _populateDataFromConfig();
      }
    });
    // --- AKHIR PERBAIKAN ---
  }

  void _populateDataFromConfig() {
    final userData = configC.infoUser;

    // Jika userData masih kosong, jangan lakukan apa-apa
    if (userData.isEmpty) return;

    // 1. Inisialisasi semua field teks standar
    namaController.text = userData['nama']?.toString() ?? '';
    aliasController.text = userData['alias']?.toString() ?? '';
    noTelpController.text = userData['noTelp']?.toString() ?? '';
    nipController.text = userData['nip']?.toString() ?? '';
    alamatController.text = userData['alamat']?.toString() ?? '';

    // 2. Tangani dan normalisasi field Jenis Kelamin
    String jkFromDb = userData['jeniskelamin']?.toString().toLowerCase() ?? '';
    if (jkFromDb == 'laki-laki') {
      jenisKelamin.value = 'Laki-Laki';
    } else if (jkFromDb == 'perempuan') {
      jenisKelamin.value = 'Perempuan';
    } else {
      jenisKelamin.value = '';
    }

    // 3. Tangani field Tanggal Bergabung
    dynamic tglGabungData = userData['tglgabung'];
    selectedJoinDate.value = null; // Reset dulu untuk memastikan kebersihan data
    if (tglGabungData is Timestamp) {
      selectedJoinDate.value = tglGabungData.toDate();
    } else if (tglGabungData is String && tglGabungData.isNotEmpty) {
      try {
        selectedJoinDate.value = DateTime.parse(tglGabungData);
      } catch (e) {
        print("### Gagal parsing 'tglgabung' String di ProfileController: $e");
      }
    }

    // 4. Update controller tanggal
    if (selectedJoinDate.value != null) {
      tglGabungController.text =
          DateFormat('dd MMMM yyyy', 'id_ID').format(selectedJoinDate.value!);
    } else {
      tglGabungController.text = '';
    }
  }

  @override
  void onClose() {
    namaController.dispose();
    aliasController.dispose();
    noTelpController.dispose();
    nipController.dispose();
    alamatController.dispose();
    tglGabungController.dispose();
    super.onClose();
  }

  Future<void> selectJoinDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedJoinDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != selectedJoinDate.value) {
      selectedJoinDate.value = picked;
      tglGabungController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
    }
  }

  /// Memilih gambar dari galeri pengguna.
  // Future<void> pickAndCropImage() async {
  //   try {
  //     // 1. Ambil gambar dari galeri
  //     final picker = ImagePicker();
  //     final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //     if (image == null) return; // Pengguna membatalkan

  //     // 2. Pangkas (Crop) gambar menjadi persegi
  //     CroppedFile? croppedFile = await ImageCropper().cropImage(
  //       sourcePath: image.path,
  //       aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Rasio 1:1 untuk foto profil
  //       uiSettings: [
  //         AndroidUiSettings(toolbarTitle: 'Pangkas Foto', lockAspectRatio: true),
  //         IOSUiSettings(title: 'Pangkas Foto', aspectRatioLockEnabled: true),
  //       ],
  //     );
  //     if (croppedFile == null) return; // Pengguna membatalkan crop

  //     // 3. Set gambar yang sudah dipangkas untuk pratinjau
  //     pickedImage.value = File(croppedFile.path);
  //   } catch (e) {
  //     Get.snackbar("Error", "Gagal memilih gambar: $e", backgroundColor: Colors.red, colorText: Colors.white);
  //   }
  // }

  Future<void> pickAndCropImage() async {
    try {
      // Langkah 1: Panggil pemilih gambar sistem.
      // Di Android modern, ini akan membuka "Android Photo Picker" yang aman.
      // Pengguna memberikan izin sementara hanya untuk file yang mereka pilih.
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      // Jika pengguna membatalkan (image == null), hentikan fungsi.
      if (image == null) {
        print("Pemilihan gambar dibatalkan oleh pengguna.");
        return; 
      }

      // Langkah 2: Panggil pemangkas gambar (image_cropper).
      // Ini juga aman dan bekerja pada file sementara yang sudah dipilih.
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Rasio 1:1 untuk foto profil
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Pangkas Foto', 
            lockAspectRatio: true,
            toolbarColor: Colors.deepPurple, // Contoh kustomisasi UI
            toolbarWidgetColor: Colors.white
          ),
          IOSUiSettings(
            title: 'Pangkas Foto', 
            aspectRatioLockEnabled: true
          ),
        ],
      );

      // Jika pengguna membatalkan proses crop, hentikan fungsi.
      if (croppedFile == null) {
        print("Proses pangkas gambar dibatalkan oleh pengguna.");
        return; 
      }

      // Langkah 3: Berhasil!
      // Tampilkan gambar yang sudah dipangkas di UI.
      pickedImage.value = File(croppedFile.path);

    } catch (e) {
      // Tangani error jika terjadi masalah tak terduga.
      print("### Terjadi error saat memilih gambar: $e");
      Get.snackbar(
        "Error", 
        "Gagal memilih atau memproses gambar.", 
        backgroundColor: Colors.red, 
        colorText: Colors.white
      );
    }
  }

  /// Mengompres gambar jika ukurannya melebihi batas (200 KB).
  Future<File?> _compressImage(File file) async {
    const int targetSizeInBytes = 100 * 1024; // Target 100 KB
    final int initialSize = file.lengthSync();
  
    // Jika sudah di bawah target, tidak perlu kompresi
    if (initialSize <= targetSizeInBytes) {
      print("### Gambar tidak perlu dikompresi. Ukuran: ${(initialSize / 1024).toStringAsFixed(2)} KB");
      return file;
    }
  
    try {
      final tempDir = await getTemporaryDirectory();
      final String targetPath = '${tempDir.path}/compressed_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
  
      // 1. Baca gambar
      img.Image? image = img.decodeImage(file.readAsBytesSync());
      if (image == null) return null;
  
      // 2. Logika Penskalaan (Resize) Cerdas
      // Jika gambar sangat besar (misal > 1200px), kecilkan dulu.
      // Ini adalah langkah paling efektif untuk mengurangi ukuran file.
      const int maxDimension = 1200;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxDimension);
        } else {
          image = img.copyResize(image, height: maxDimension);
        }
        print("### Gambar di-resize ke ${image.width}x${image.height} px");
      }
  
      // 3. Logika Kompresi Kualitas (Quality) Adaptif
      List<int> compressedBytes;
      int quality = 90; // Mulai dengan kualitas tinggi
  
      // Loop untuk menurunkan kualitas hingga ukuran file sesuai target
      do {
        compressedBytes = img.encodeJpg(image, quality: quality);
        print("### Kompresi dengan kualitas $quality. Ukuran baru: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB");
        
        // Turunkan kualitas untuk iterasi berikutnya jika masih terlalu besar
        if (compressedBytes.length > targetSizeInBytes) {
          if (quality > 40) {
            quality -= 10; // Turunkan 10 poin jika kualitas masih bagus
          } else {
            quality -= 5;  // Turunkan 5 poin jika kualitas sudah rendah
          }
        }
        
      } while (compressedBytes.length > targetSizeInBytes && quality > 15); // Berhenti di kualitas 15
  
      // 4. Simpan hasil kompresi ke file baru
      File compressedFile = await File(targetPath).writeAsBytes(compressedBytes);
      final finalSize = compressedFile.lengthSync();
      print("### Kompresi FINAL selesai. Ukuran akhir: ${(finalSize / 1024).toStringAsFixed(2)} KB");
      
      return compressedFile;
  
    } catch (e) {
      Get.snackbar("Error Kompresi", "Gagal memproses gambar: ${e.toString()}",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return null; // Kembalikan null jika ada error
    }
  }

  /// Mengupdate data profil ke Firestore.
  Future<void> updateProfile() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      String? newFotoUrl;
      if (pickedImage.value != null) {
        File? imageToUpload = await _compressImage(pickedImage.value!);
        if (imageToUpload != null) {
          newFotoUrl = await storageC.uploadProfilePicture(imageToUpload, authC.auth.currentUser!.uid);
        } else {
          throw Exception("Gagal memproses gambar.");
        }
      }

      final Map<String, dynamic> dataToUpdate = {
        'nama': namaController.text.trim(),
        'alias': aliasController.text.trim(),
        'noTelp': noTelpController.text.trim(),
        'nip': nipController.text.trim(),
        'alamat': alamatController.text.trim(),
        'jeniskelamin': jenisKelamin.value,
      };
      if (selectedJoinDate.value != null) {
        dataToUpdate['tglgabung'] = Timestamp.fromDate(selectedJoinDate.value!);
      }
      if (newFotoUrl != null) {
        // PERBAIKAN: Gunakan field 'profileImageUrl'
        dataToUpdate['profileImageUrl'] = newFotoUrl;
      }
      
      await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(authC.auth.currentUser!.uid).update(dataToUpdate);
      await configC.forceSyncProfile();
      
      Get.snackbar("Berhasil", "Profil berhasil diperbarui.", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Gagal", "Terjadi kesalahan: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async => await authC.logout();
}