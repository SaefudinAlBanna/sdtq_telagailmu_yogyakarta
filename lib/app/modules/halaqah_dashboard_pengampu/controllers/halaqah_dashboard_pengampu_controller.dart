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

    // 1. Ambil data profil terbaru DIRI SENDIRI terlebih dahulu.
    final myProfileDoc = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('pegawai').doc(uid).get();
    final myProfileImageUrl = myProfileDoc.data()?['profileImageUrl'] as String?;

    // 2. Lanjutkan ambil data grup.
    final Map<String, HalaqahGroupModel> combinedGroups = {};
    final queryGrup = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup');
    
    final results = await Future.wait([
      queryGrup.where('idPengampu', isEqualTo: uid).get(),
      queryGrup.where('penggantiHarian.${DateFormat('yyyy-MM-dd').format(DateTime.now())}.idPengganti', isEqualTo: uid).get()
    ]);

    final permanentSnapshot = results[0];
    final substituteSnapshot = results[1];

    // Proses grup permanen
    for (var doc in permanentSnapshot.docs) {
      // Buat objek awal dari Firestore
      final groupFromFirestore = HalaqahGroupModel.fromFirestore(doc);
      // Buat objek BARU yang sudah diperbarui menggunakan copyWith
      final updatedGroup = groupFromFirestore.copyWith(profileImageUrl: myProfileImageUrl);
      combinedGroups[doc.id] = updatedGroup;
    }
    
    // Proses grup pengganti
    for (var doc in substituteSnapshot.docs) {
      final groupFromFirestore = HalaqahGroupModel.fromFirestore(doc);
      final updatedGroup = groupFromFirestore.copyWith(
        profileImageUrl: myProfileImageUrl,
        isPengganti: true, // Kita juga bisa set properti lain
      );
      combinedGroups[doc.id] = updatedGroup;
    }

    final finalGroupList = combinedGroups.values.toList();
    finalGroupList.sort((a, b) => a.namaGrup.compareTo(b.namaGrup));
    
    return finalGroupList;
  }

  void goToGradingPage(HalaqahGroupModel group) {
    Get.toNamed(Routes.HALAQAH_GRADING, arguments: group);
  }
}