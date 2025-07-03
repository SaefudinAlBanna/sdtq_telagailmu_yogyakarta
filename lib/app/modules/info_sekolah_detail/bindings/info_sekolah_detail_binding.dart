import 'package:get/get.dart';

import '../controllers/info_sekolah_detail_controller.dart';

class InfoSekolahDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InfoSekolahDetailController>(
      () => InfoSekolahDetailController(),
    );
  }
}
