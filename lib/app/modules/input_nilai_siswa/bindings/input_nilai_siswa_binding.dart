import 'package:get/get.dart';
import '../controllers/input_nilai_siswa_controller.dart';

class InputNilaiSiswaBinding extends Bindings {
  @override
  void dependencies() {
    // Ambil argumen sekali saja untuk efisiensi
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    
    // Buat tag yang unik dari kombinasi idSiswa dan idMapel
    final String uniqueTag = args['idSiswa'] + args['idMapel'];

    Get.lazyPut<InputNilaiSiswaController>(
      () => InputNilaiSiswaController(args: args),
      tag: uniqueTag, // Gunakan tag unik
    );
  }
}