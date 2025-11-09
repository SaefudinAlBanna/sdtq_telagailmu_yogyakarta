// lib/app/modules/manajemen_penguji/views/manajemen_penguji_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manajemen_penguji_controller.dart';

class ManajemenPengujiView extends GetView<ManajemenPengujiController> {
  const ManajemenPengujiView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Penguji Halaqah'),
      ),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        onPressed: controller.isSaving.value ? null : controller.saveChanges,
        label: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan Perubahan"),
        icon: controller.isSaving.value
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
            : const Icon(Icons.save),
      )),
      body: Column(
        children: [
          // [BARU] Widget untuk kolom pencarian
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller.searchC,
              decoration: InputDecoration(
                hintText: "Cari nama atau alias pegawai...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // [DIUBAH] Bungkus ListView dengan Expanded
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              // [DIUBAH] Gunakan filteredPegawai
              if (controller.filteredPegawai.isEmpty) {
                if (controller.semuaPegawai.isEmpty) {
                  return const Center(child: Text("Tidak ada data pegawai."));
                } else {
                  return const Center(child: Text("Pegawai tidak ditemukan."));
                }
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                // [DIUBAH] Gunakan panjang dari filteredPegawai
                itemCount: controller.filteredPegawai.length,
                itemBuilder: (context, index) {
                  // [DIUBAH] Ambil data dari filteredPegawai
                  final pegawai = controller.filteredPegawai[index];
                  return Obx(() {
                    final isSelected = controller.pengujiTerpilihUids.contains(pegawai.uid);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        if (value != null) {
                          controller.togglePenguji(pegawai.uid, value);
                        }
                      },
                      title: Text(pegawai.nama),
                      subtitle: Text(pegawai.alias.isNotEmpty ? pegawai.alias : 'Tanpa Alias'),
                      activeColor: Colors.teal,
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}