// lib/app/modules/home/controllers/home_controller.dart

import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class HomeController extends GetxController {
  // Tugas HomeController sekarang SANGAT sederhana
  final PersistentTabController tabController = PersistentTabController(initialIndex: 0);
  
  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}

// // lib/app/controllers/home_controller.dart

// import 'package:get/get.dart';
// import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';

// import '../../../routes/app_pages.dart';

// class HomeController extends GetxController {
//   final ConfigController configController = Get.find<ConfigController>();
//   final PersistentTabController tabController = PersistentTabController(initialIndex: 0);
  
//   // --- GETTER HAK AKSES (VERSI BARU YANG SUDAH DIPERBAIKI) ---
//   // Mengambil data langsung dari map 'infoUser'.
//   bool get isAdmin => configController.infoUser['role'] == 'Admin';
//   bool get isKepsek => configController.infoUser['role'] == 'Kepala Sekolah';
//   bool get isAdminAtauKepsek => isAdmin || isKepsek;
//   bool get isGuru => configController.infoUser['role'] == 'Guru Kelas' || configController.infoUser['role'] == 'Guru Mapel';

//   bool get isPimpinan {
//     final role = configController.infoUser['role'] ?? '';
//     final tugas = configController.infoUser['tugas'] ?? '';
//     final peranSistem = configController.infoUser['peranSistem'] ?? '';
//     return ['Kepala Sekolah', 'Koordinator Kurikulum'].contains(role) || tugas == 'Koordinator Kurikulum' || peranSistem == 'superadmin';
//   }

//   bool get canManageHalaqah {
//     final user = configController.infoUser;
//     if (user.isEmpty) return false;

//     final String peranSistem = user['peranSistem'] ?? '';
//     final String role = user['role'] ?? '';
//     // Ambil tugasTambahan sebagai List<String>
//     final List<String> tugas = List<String>.from(user['tugas'] ?? []);

//     // Cek kondisi sesuai aturan yang Anda berikan
//     final bool hasRequiredRole = ['Kepala Sekolah', 'TU', 'Tata Usaha', 'Admin'].contains(role);
//     final bool hasRequiredTugas = tugas.any((t) => ['Koordinator Halaqah', 'Koordinator Kurikulum'].contains(t));
    
//     return peranSistem == 'superadmin' || hasRequiredRole || hasRequiredTugas;
//   }

//   bool get isPengampuHalaqah {
//     final user = configController.infoUser;
//     if (user.isEmpty) return false;
//     // Cek apakah map 'grupHalaqahDiampu' ada dan tidak kosong
//     return user.containsKey('grupHalaqahDiampu') && (user['grupHalaqahDiampu'] as Map).isNotEmpty;
//   }

//   void goToHalaqahManagement() {
//     Get.toNamed(Routes.HALAQAH_MANAGEMENT); // Route ini akan kita buat
//   }

//   void goToHalaqahDashboard() {
//     Get.toNamed(Routes.HALAQAH_DASHBOARD_PENGAMPU);
//   }

//   void goToRekapAbsensiSekolah() {
//     Get.toNamed(Routes.REKAP_ABSENSI, arguments: {'scope': 'sekolah'});
//   }
  
//   @override
//   void onClose() {
//     tabController.dispose();
//     super.onClose();
//   }
// }