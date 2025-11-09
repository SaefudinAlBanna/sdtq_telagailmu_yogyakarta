import 'package:get/get.dart';

import '../controllers/penjadwalan_ujian_controller.dart';

class PenjadwalanUjianBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PenjadwalanUjianController>(
      () => PenjadwalanUjianController(),
    );
  }
}
