import 'package:get/get.dart';

import '../controllers/jadwal_ujian_penguji_controller.dart';

class JadwalUjianPengujiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JadwalUjianPengujiController>(
      () => JadwalUjianPengujiController(),
    );
  }
}
