import 'package:get/get.dart';

import '../controllers/manajemen_penguji_controller.dart';

class ManajemenPengujiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenPengujiController>(
      () => ManajemenPengujiController(),
    );
  }
}
