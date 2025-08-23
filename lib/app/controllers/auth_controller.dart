// lib/app/controllers/auth_controller.dart (VERSI BARU UNTUK KEDUA APLIKASI)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'config_controller.dart'; // atau 'aplikasi_orangtua'

class AuthController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  late final Stream<User?> authStateChanges;
  final Rxn<User> _firebaseUser = Rxn<User>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    authStateChanges = auth.authStateChanges();
    _firebaseUser.bindStream(authStateChanges);
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Terjadi kesalahan.";
      if (e.code == 'user-not-found') {
        errorMessage = "Email tidak terdaftar.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Password yang Anda masukkan salah.";
      } else {
        errorMessage = "Gagal login. Periksa kembali email dan password Anda.";
      }
      Get.snackbar("Gagal Login",errorMessage, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error","Terjadi kesalahan yang tidak diketahui.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      if (Get.isRegistered<ConfigController>()) {
        final configC = Get.find<ConfigController>();
        await configC.clearUserConfig();
      }
      
      await auth.signOut();
      
      // --- [FIX] Beri jeda agar state stream selesai diproses ---
      // Ini akan mencegah error race condition saat membangun ulang widget tree.
      await Future.delayed(Duration.zero); 
      
      Get.offAllNamed('/login');

    } catch (e) {
      Get.snackbar("Error", "Gagal untuk logout. Silakan coba lagi.", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}