import 'package:get/get.dart';

import '../controllers/halaqah_dashboard_controller.dart';

class HalaqahDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahDashboardController>(
      () => HalaqahDashboardController(),
    );
  }
}
