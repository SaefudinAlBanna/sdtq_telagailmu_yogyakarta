// lib/app/controllers/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';

class LoginController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  // --- TAMBAHAN BARU ---
  // 1. Kunci untuk mengelola state dan validasi dari Form widget.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isPasswordHidden = true.obs;
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();

  // --- PERUBAHAN PADA FUNGSI LOGIN ---
  void login() async {
    // 2. Cek apakah semua validator pada Form di UI sudah terpenuhi.
    if (formKey.currentState!.validate()) {
      // Jika form valid, lanjutkan proses login seperti biasa.
      await authController.login(emailC.text, passC.text);
    } else {
      // Jika form tidak valid, tampilkan pesan umum.
      // Pesan error spesifik per field akan otomatis ditampilkan di UI oleh TextFormField.
      Get.snackbar(
        "Input Tidak Valid",
        "Mohon periksa kembali data yang Anda masukkan.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // --- FUNGSI VALIDATOR BARU ---
  // 3. Validator untuk field email.
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    // Menggunakan Regex untuk memeriksa format email yang valid.
    if (!GetUtils.isEmail(value)) {
      return 'Format email tidak valid.';
    }
    return null; // Return null jika valid.
  }

  // 4. Validator untuk field password.
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong.';
    }
    // Firebase Auth memerlukan minimal 6 karakter.
    if (value.length < 6) {
      return 'Password minimal harus 6 karakter.';
    }
    return null; // Return null jika valid.
  }

  @override
  void onClose() {
    emailC.dispose();
    passC.dispose();
    super.onClose();
  }
}