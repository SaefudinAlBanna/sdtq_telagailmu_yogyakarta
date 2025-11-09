import 'package:get/get.dart';

import '../controllers/manajemen_tingkatan_siswa_controller.dart';

class ManajemenTingkatanSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenTingkatanSiswaController>(
      () => ManajemenTingkatanSiswaController(),
    );
  }
}
