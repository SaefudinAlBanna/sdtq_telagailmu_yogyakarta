// lib/app/modules/home/bindings/home_binding.dart

import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/dashboard_controller.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    // --- [PENTING] Daftarkan DashboardController di sini ---
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}


// import 'package:get/get.dart';

// import '../controllers/home_controller.dart';

// class HomeBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<HomeController>(
//       () => HomeController(),
//     );
//   }
// }
