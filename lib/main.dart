// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'app/controllers/auth_controller.dart';
import 'app/controllers/config_controller.dart';
import 'app/controllers/dashboard_controller.dart';
import 'app/controllers/storage_controller.dart';
import 'app/routes/app_pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timeago/timeago.dart' as timeago;

// Import intl untuk formatting tanggal
import 'package:intl/date_symbol_data_local.dart';

// Import Supabase dengan prefix 'as supabase' untuk menghindari konflik nama 'User'
import 'package:supabase_flutter/supabase_flutter.dart' as supabase; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

   await dotenv.load(fileName: ".env");
  
  // Inisialisasi Firebase (tidak berubah)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi Supabase dengan prefix (tidak berubah)
  await supabase.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, 
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, 
  );
  
  await GetStorage.init();

    // --- DAFTARKAN STORAGE CONTROLLER DI SINI ---
    Get.put(AuthController(), permanent: true);
    Get.put(StorageController(), permanent: true);
    Get.put(ConfigController(), permanent: true);
    Get.put(DashboardController(), permanent: true); 

  // ==========================================================
  // --- TAMBAHKAN KODE INISIALISASI TANGGAL DI SINI ---
  await initializeDateFormatting('id_ID', null);
  timeago.setLocaleMessages('id', timeago.IdMessages());
  // ==========================================================

  runApp(
    // Hapus StreamBuilder di sini.
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PKBM Telagailmu",
      // Selalu mulai dari halaman splash/loading atau langsung ke login.
      // Biarkan controller yang menangani navigasi setelahnya.
      initialRoute: AppPages.INITIAL, 
      getPages: AppPages.routes,
    ),
  );
}