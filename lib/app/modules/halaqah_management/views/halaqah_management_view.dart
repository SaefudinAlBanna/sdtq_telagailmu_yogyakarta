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