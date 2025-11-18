// lib/app/modules/root/bindings/root_binding.dart (Aplikasi SEKOLAH)

import 'package:get/get.dart';

import '../controllers/root_controller.dart';
// ConfigController akan di-find di RootController

class RootBinding extends Bindings {
  @override
  void dependencies() {
    print("🚦 [RootBinding] dependencies called. Attempting to put RootController."); // <-- TAMBAHAN LOG
    
    // [PERBAIKAN KRUSIAL UNTUK DEBUGGING]
    // Ganti Get.lazyPut menjadi Get.put untuk memaksa instansiasi segera
    Get.put<RootController>( 
      RootController(), 
    );
    print("✅ [RootBinding] RootController put successfully."); // <-- TAMBAHAN LOG
  }
}