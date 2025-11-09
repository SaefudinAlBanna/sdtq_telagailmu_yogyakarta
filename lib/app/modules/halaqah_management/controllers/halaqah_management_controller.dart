// lib/app/modules/halaqah_management/controllers/halaqah_management_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_group_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_group_with_count_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';

class HalaqahManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  final RxList<HalaqahGroupWithCount> allGroups = <HalaqahGroupWithCount>[].obs;
  
  final searchC = TextEditingController();
  final searchQuery = "".obs;

  List<HalaqahGroupWithCount> get filteredGroups {
    if (searchQuery.value.isEmpty) {
      return allGroups;
    }
    return allGroups.where((group) {
      final query = searchQuery.value.toLowerCase();
      return group.namaGrup.toLowerCase().contains(query) ||
             group.namaPengampu.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    searchC.addListener(() {
      searchQuery.value = searchC.text;
    });
  }

  @override
  void onReady() {
    super.onReady();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    isLoading.value = true;
    try {
      final tahunAjaran = configC.tahunAjaranAktif.value;
      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) return;
  
      final groupSnapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('halaqah_grup').get();
  
      final List<HalaqahGroupWithCount> groupsWithCount = [];
  
      for (var doc in groupSnapshot.docs) {
        final groupData = HalaqahGroupModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        
        final memberSnapshot = await doc.reference.collection('anggota').count().get();
        final memberCount = memberSnapshot.count ?? 0;
  
        groupsWithCount.add(HalaqahGroupWithCount(
          id: groupData.id,
          namaGrup: groupData.namaGrup,
          idPengampu: groupData.idPengampu,
          namaPengampu: groupData.namaPengampu,
          aliasPengampu: groupData.aliasPengampu,
          semester: groupData.semester,
          // [PERBAIKAN KUNCI DI SINI] Meneruskan URL yang hilang
          profileImageUrl: groupData.profileImageUrl, 
          memberCount: memberCount,
        ));
      }
      
      groupsWithCount.sort((a, b) => a.namaGrup.compareTo(b.namaGrup));
      allGroups.assignAll(groupsWithCount);
  
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data grup: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void goToCreateEditGroup([HalaqahGroupModel? group]) {
    Get.toNamed(Routes.CREATE_EDIT_HALAQAH_GROUP, arguments: group)?.then((_) {
      _fetchGroups(); 
    });
  }

  void goToSetPengganti(HalaqahGroupModel group) {
    Get.toNamed(Routes.HALAQAH_SET_PENGGANTI, arguments: group);
  }

  Future<void> deleteGroup(HalaqahGroupModel group) async {
    ////----------------------------------------------
    Get.snackbar("Peringatan", "Fitur ini akan aktif ketika regulasi sekolah ada hapus grup halaqah",
      backgroundColor: Colors.red[600], colorText: Colors.white);
//     try {
//       final groupRef = _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
//           .collection('halaqah_grup').doc(group.id);

//       // LANGKAH 1: Validasi apakah grup masih memiliki anggota
//       final anggotaSnapshot = await groupRef.collection('anggota').limit(1).get();
//       if (anggotaSnapshot.docs.isNotEmpty) {
//         Get.snackbar(
//           "Gagal Menghapus",
//           "Grup tidak dapat dihapus karena masih memiliki anggota siswa.",
//           backgroundColor: Colors.red, colorText: Colors.white
//         );
//         return;
//       }

//       // LANGKAH 2: Tampilkan dialog konfirmasi
//       Get.defaultDialog(
//         title: "Konfirmasi Hapus",
//         middleText: "Apakah Anda yakin ingin menghapus grup '${group.namaGrup}'?",
//         textConfirm: "Ya, Hapus",
//         textCancel: "Batal",
//         confirmTextColor: Colors.white,
//         onConfirm: () async {
//           Get.back(); // Tutup dialog
          
//           final WriteBatch batch = _firestore.batch();
          
//           // Aksi 1: Hapus dokumen grup itu sendiri
//           batch.delete(groupRef);

//           // Aksi 2 (Denormalisasi): Hapus ID grup dari data pengampu
//           final pengampuRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(group.idPengampu);
//           final keySemester = "${configC.tahunAjaranAktif.value}_${configC.semesterAktif.value}";
//           batch.update(pengampuRef, {
//             'grupHalaqahDiampu.$keySemester': FieldValue.arrayRemove([group.id])
//           });

//           await batch.commit();
//           Get.snackbar("Berhasil", "Grup halaqah telah dihapus.");
//         },
//       );
//     } catch (e) {
//       Get.snackbar("Error", "Terjadi kesalahan: $e");
//     }
  }
  
  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }
}


// // lib/app/modules/halaqah_management/controllers/halaqah_management_controller.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';

// import '../../../models/halaqah_group_model.dart';

// class HalaqahManagementController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();

//   // Stream untuk mengambil daftar grup halaqah
//   Stream<QuerySnapshot<Map<String, dynamic>>> streamHalaqahGroups() {
//     final tahunAjaran = configC.tahunAjaranAktif.value;
//     final semester = configC.semesterAktif.value;

//     if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
//       return const Stream.empty();
//     }

//     return _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(tahunAjaran)
//         .collection('halaqah_grup')
//         .where('semester', isEqualTo: semester)
//         .orderBy('namaGrup')
//         .snapshots();
//   }

//   // Navigasi ke halaman buat/edit grup
//   // Kita kirim 'null' untuk menandakan ini adalah pembuatan grup BARU
//   void goToCreateGroup() {
//     Get.toNamed(Routes.CREATE_EDIT_HALAQAH_GROUP, arguments: null);
//   }

//   // Fungsi ini akan kita gunakan nanti saat mengedit grup yang sudah ada
//   void goToEditGroup(HalaqahGroupModel group) {
//     Get.toNamed(Routes.CREATE_EDIT_HALAQAH_GROUP, arguments: group);
//   }

//   void goToSetPengganti(HalaqahGroupModel group) {
//     Get.toNamed(Routes.HALAQAH_SET_PENGGANTI, arguments: group);
//   }

//   Future<void> deleteGroup(HalaqahGroupModel group) async {
//     try {
//       final groupRef = _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
//           .collection('halaqah_grup').doc(group.id);

//       // LANGKAH 1: Validasi apakah grup masih memiliki anggota
//       final anggotaSnapshot = await groupRef.collection('anggota').limit(1).get();
//       if (anggotaSnapshot.docs.isNotEmpty) {
//         Get.snackbar(
//           "Gagal Menghapus",
//           "Grup tidak dapat dihapus karena masih memiliki anggota siswa.",
//           backgroundColor: Colors.red, colorText: Colors.white
//         );
//         return;
//       }

//       // LANGKAH 2: Tampilkan dialog konfirmasi
//       Get.defaultDialog(
//         title: "Konfirmasi Hapus",
//         middleText: "Apakah Anda yakin ingin menghapus grup '${group.namaGrup}'?",
//         textConfirm: "Ya, Hapus",
//         textCancel: "Batal",
//         confirmTextColor: Colors.white,
//         onConfirm: () async {
//           Get.back(); // Tutup dialog
          
//           final WriteBatch batch = _firestore.batch();
          
//           // Aksi 1: Hapus dokumen grup itu sendiri
//           batch.delete(groupRef);

//           // Aksi 2 (Denormalisasi): Hapus ID grup dari data pengampu
//           final pengampuRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(group.idPengampu);
//           final keySemester = "${configC.tahunAjaranAktif.value}_${configC.semesterAktif.value}";
//           batch.update(pengampuRef, {
//             'grupHalaqahDiampu.$keySemester': FieldValue.arrayRemove([group.id])
//           });

//           await batch.commit();
//           Get.snackbar("Berhasil", "Grup halaqah telah dihapus.");
//         },
//       );
//     } catch (e) {
//       Get.snackbar("Error", "Terjadi kesalahan: $e");
//     }
//   }
// }