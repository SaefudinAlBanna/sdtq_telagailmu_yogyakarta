import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase; 

import 'app/controllers/auth_controller.dart';
import 'app/controllers/config_controller.dart';
import 'app/controllers/dashboard_controller.dart';
import 'app/controllers/storage_controller.dart';
import 'app/modules/profile/controllers/profile_controller.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await supabase.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, 
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, 
  );
  
  await GetStorage.init();

  // --- [PERBAIKAN KRUSIAL] ---
  // Inisialisasi data lokalisasi SEBELUM membuat controller apa pun.
  // Ini memastikan DateFormat siap digunakan saat onInit() dipanggil.
  await initializeDateFormatting('id_ID', null);
  timeago.setLocaleMessages('id', timeago.IdMessages());
  // -----------------------------

  // Daftarkan semua controller permanen SETELAH semua await selesai.
  Get.put(AuthController(), permanent: true);
  Get.put(StorageController(), permanent: true);
  Get.put(ConfigController(), permanent: true);
  Get.put(DashboardController(), permanent: true); 
  Get.put(ProfileController(), permanent: true);

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PKBM Telagailmu",
      initialRoute: AppPages.INITIAL, 
      getPages: AppPages.routes,
      
      // Konfigurasi lokalisasi untuk widget Material
      locale: const Locale('id', 'ID'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
      ],
    ),
  );
}