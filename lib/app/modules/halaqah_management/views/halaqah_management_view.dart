// lib/app/modules/halaqah_management/views/halaqah_management_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/avatar_pengampu.dart';
import '../controllers/halaqah_management_controller.dart';

class HalaqahManagementView extends GetView<HalaqahManagementController> {
  const HalaqahManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Grup Halaqah'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.goToCreateEditGroup(),
        child: const Icon(Icons.add),
        tooltip: "Buat Grup Halaqah Baru",
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller.searchC,
              decoration: InputDecoration(
                hintText: "Cari nama grup atau pengampu...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredGroups.isEmpty) {
                return const Center(child: Text("Tidak ada grup halaqah ditemukan."));
              }
              return ListView.builder(
                itemCount: controller.filteredGroups.length,
                itemBuilder: (context, index) {
                  final group = controller.filteredGroups[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: AvatarPengampu(
                        imageUrl: group.profileImageUrl, // Kirim URL gambar
                        nama: group.namaPengampu,          // Kirim nama untuk inisial
                      ),
                      title: Text(group.namaGrup, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.namaPengampu),
                          const SizedBox(height: 4),
                          Text("Total: ${group.memberCount} Anggota", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      // trailing: const Icon(Icons.edit_note_rounded),
                      // onTap: () => controller.goToCreateEditGroup(group),
                      trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       // Tombol untuk atur pengganti
                       IconButton(
                         icon: const Icon(Icons.person_add_alt_1_rounded),
                         onPressed: () => controller.goToSetPengganti(group),
                         tooltip: "Atur Pengganti",
                       ),
                       // Tombol hapus yang sudah ada
                       IconButton(
                         icon: const Icon(Icons.delete_outline, color: Colors.red),
                        //  onPressed: () => controller.deleteGroup(group),
                         onPressed: () => controller.deleteGroup(group),
                         tooltip: "Hapus Grup",
                       ),
                     ],
                   ),
                   onTap: () => controller.goToCreateEditGroup(group),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}


// // lib/app/modules/halaqah_management/views/halaqah_management_view.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_group_model.dart';
// import 'package:get/get.dart';
// import '../../../routes/app_pages.dart';
// import '../controllers/halaqah_management_controller.dart';

// class HalaqahManagementView extends GetView<HalaqahManagementController> {
//   const HalaqahManagementView({Key? key}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manajemen Halaqah'),
//         centerTitle: true,
//       // actions: [
//       //     PopupMenuButton<String>(
//       //       icon: const Icon(Icons.menu),
//       //       tooltip: "Editor Jadwal",
//       //       onSelected: (value) {
//               // if (value == 'Dashboard') {Get.toNamed(Routes.HALAQAH_DASHBOARD_KOORDINATOR);}
//               // if (value == 'penugasan') {Get.toNamed(Routes.HALAQAH_UMMI_MANAJEMEN_PENGUJI);}
//               // if (value == 'Jadwal') {Get.toNamed(Routes.HALAQAH_UMMI_JADWAL_PENGUJI);}
//         //     },
//         //     itemBuilder: (context) => [
//         //       // const PopupMenuItem(value: 'Dashboard', child: ListTile(leading: Icon(Icons.dashboard_customize_outlined), title: Text("Dashboard"))),
//         //       const PopupMenuItem(value: 'penugasan', child: ListTile(leading: Icon(Icons.grading_rounded), title: Text("penugasan"))),
//         //       const PopupMenuItem(value: 'Jadwal', child: ListTile(leading: Icon(Icons.schedule_sharp), title: Text("Jadwal"))),
//         //     ],
//         //   ),
//         // ],
//       ),
//       body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: controller.streamHalaqahGroups(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text(
//                 "Belum ada grup Halaqah untuk semester ini.\nSilakan buat grup baru.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//             );
//           }

//           final groupList = snapshot.data!.docs;

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: groupList.length,
//             itemBuilder: (context, index) {
//               final group = HalaqahGroupModel.fromFirestore(groupList[index]);
//               return Card(
//                 elevation: 2,
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ListTile(
//                   // --- [DIUBAH] Ganti seluruh leading ini ---
//                   leading: CircleAvatar(
//                 // Gunakan backgroundImage jika URL ada
//                 backgroundImage: (group.profileImageUrl != null && group.profileImageUrl!.isNotEmpty)
//                   ? NetworkImage(group.profileImageUrl!)
//                   : null,
//                 // Jika tidak ada gambar, tampilkan alias
//                 child: (group.profileImageUrl == null || group.profileImageUrl!.isEmpty)
//                   ? Text(group.aliasPengampu)
//                   : null,
//               ),
//                   title: Text(group.namaGrup, style: const TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: Text("Pengampu: ${group.namaPengampu}"),
//                    trailing: Row(
//                      mainAxisSize: MainAxisSize.min,
//                      children: [
//                        // Tombol untuk atur pengganti
//                        IconButton(
//                          icon: const Icon(Icons.person_add_alt_1_rounded),
//                          onPressed: () => controller.goToSetPengganti(group),
//                          tooltip: "Atur Pengganti",
//                        ),
//                        // Tombol hapus yang sudah ada
//                        IconButton(
//                          icon: const Icon(Icons.delete_outline, color: Colors.red),
//                          onPressed: () => controller.deleteGroup(group),
//                          tooltip: "Hapus Grup",
//                        ),
//                      ],
//                    ),
//                    onTap: () => controller.goToEditGroup(group),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: controller.goToCreateGroup,
//         icon: const Icon(Icons.add),
//         label: const Text("Buat Grup Baru"),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
// }