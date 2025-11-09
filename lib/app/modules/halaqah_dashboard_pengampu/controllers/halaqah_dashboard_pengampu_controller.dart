import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_group_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/dashboard_controller.dart';

class HalaqahDashboardPengampuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();
  final DashboardController dashC = Get.find<DashboardController>();
  
  // Gunakan Future karena daftar grup yang diampu relatif statis per semester
  late Future<List<HalaqahGroupModel>> listGroupFuture;

  @override
  void onInit() {
    super.onInit();
    listGroupFuture = fetchMyGroups();
  }
  
  Future<List<HalaqahGroupModel>> fetchMyGroups() async {
    final uid = authC.auth.currentUser!.uid;
    final tahunAjaran = configC.tahunAjaranAktif.value;
    final semester = configC.semesterAktif.value;
    final keySemester = "${tahunAjaran}_$semester";
    
    final Map<String, HalaqahGroupModel> combinedGroups = {};
  
    // --- [SOLUSI BARU TANPA whereIn] ---
    // 1. Ambil SEMUA grup di tahun ajaran aktif
    final semuaGrupSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup')
        .get();
    
    // 2. Ambil daftar ID grup permanen dari profil pengguna
    final user = configC.infoUser;
    final Map<String, dynamic> diampuData = user['grupHalaqahDiampu'] ?? {};
    final List<String> permanentGroupIds = List<String>.from(diampuData[keySemester] ?? []);
  
    // 3. Filter di sisi klien
    for (var doc in semuaGrupSnapshot.docs) {
      if (permanentGroupIds.contains(doc.id)) {
        combinedGroups[doc.id] = HalaqahGroupModel.fromFirestore(doc);
      }
    }
    // --- AKHIR SOLUSI BARU ---
  
    // --- QUERY 2: Ambil grup pengganti (ini tetap efisien dan tidak perlu diubah) ---
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final substituteSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup')
        .where('penggantiHarian.$todayKey.idPengganti', isEqualTo: uid)
        .get();
  
    for (var doc in substituteSnapshot.docs) {
      final group = HalaqahGroupModel.fromFirestore(doc);
      group.isPengganti = true;
      combinedGroups[doc.id] = group;
    }
  
    final finalGroupList = combinedGroups.values.toList();
    finalGroupList.sort((a, b) => a.namaGrup.compareTo(b.namaGrup));
    
    return finalGroupList;
  }

  void goToGradingPage(HalaqahGroupModel group) {
    Get.toNamed(Routes.HALAQAH_GRADING, arguments: group);
  }
}