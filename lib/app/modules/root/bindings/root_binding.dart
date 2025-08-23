// lib/app/modules/root/bindings/root_binding.dart
import 'package:get/get.dart';

import 'package:sdtq_telagailmu_yogyakarta/app/controllers/dashboard_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/home/controllers/home_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/login/controllers/login_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/new_password/controllers/new_password_controller.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    // --- PERUBAHAN DI SINI ---
    // Ubah lazyPut menjadi put untuk LoginController.
    // Ini memastikan controller selalu siap di memori bahkan sebelum diminta,
    // menyelesaikan masalah "not found" saat logout.
    Get.put(LoginController());
    
    // Controller lain bisa tetap lazy karena tidak langsung dipanggil oleh RootView.
    Get.lazyPut<NewPasswordController>(() => NewPasswordController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}