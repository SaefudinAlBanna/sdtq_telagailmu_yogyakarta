// lib/app/modules/manajemen_tingkatan_siswa/views/manajemen_tingkatan_siswa_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/utils/halaqah_utils.dart';
import '../controllers/manajemen_tingkatan_siswa_controller.dart';

class ManajemenTingkatanSiswaView extends GetView<ManajemenTingkatanSiswaController> {
  const ManajemenTingkatanSiswaView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Tingkatan Siswa'),
        actions: [
          Obx(() => IconButton(
            icon: Icon(controller.isModeMassal.value ? Icons.person : Icons.people_alt_outlined),
            tooltip: controller.isModeMassal.value ? "Mode Atur per Siswa" : "Mode Atur Massal",
            onPressed: controller.toggleMode,
          )),
        ],
      ),
      floatingActionButton: Obx(() => controller.isModeMassal.value
          ? FloatingActionButton.extended(
              onPressed: controller.isSaving.value ? null : controller.saveTingkatanMassal,
              label: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan (${controller.siswaTerpilihMassalUids.length} Siswa)"),
              icon: const Icon(Icons.save),
            )
          : const SizedBox.shrink()
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller.searchC,
                decoration: InputDecoration(
                  hintText: "Cari nama siswa...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: controller.isModeMassal.value ? _buildModeMassal() : _buildModePerSiswa(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildModePerSiswa() {
    return Obx(() {
      if (controller.filteredSiswa.isEmpty) return const Center(child: Text("Siswa tidak ditemukan."));
      return ListView.builder(
        itemCount: controller.filteredSiswa.length,
        itemBuilder: (context, index) {
          final siswa = controller.filteredSiswa[index];
          return ListTile(
            leading: Chip(
              label: Text(siswa.namaTingkatan, style: const TextStyle(color: Colors.white, fontSize: 10)),
              backgroundColor: HalaqahUtils.getWarnaTingkatan(siswa.tingkatanSaatIni?['nama']),
            ),
            title: Text(siswa.nama),
            trailing: SizedBox(
              width: 120,
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Atur"),
                onChanged: (newValue) {
                  if (newValue != null) {
                    controller.updateTingkatanSatuSiswa(siswa.uid, newValue);
                  }
                },
                items: HalaqahUtils.daftarTingkatan.map((tingkat) {
                  return DropdownMenuItem(value: tingkat, child: Text(tingkat));
                }).toList(),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildModeMassal() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButtonFormField<String>(
            hint: const Text("Pilih Tingkatan Target"),
            onChanged: (value) => controller.tingkatanTerpilihMassal.value = value,
            items: HalaqahUtils.daftarTingkatan.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        Obx(() => CheckboxListTile(
          title: const Text("Pilih Semua Siswa (yang tampil)"),
          value: controller.filteredSiswa.isNotEmpty && controller.siswaTerpilihMassalUids.length == controller.filteredSiswa.length,
          onChanged: (value) {
            if (value != null) controller.selectAll(value);
          },
        )),
        const Divider(),
        Expanded(
          child: Obx(() {
            if (controller.filteredSiswa.isEmpty) return const Center(child: Text("Siswa tidak ditemukan."));
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: controller.filteredSiswa.length,
              itemBuilder: (context, index) {
                final siswa = controller.filteredSiswa[index];
                return Obx(() => CheckboxListTile(
                  value: controller.siswaTerpilihMassalUids.contains(siswa.uid),
                  onChanged: (value) {
                    if (value != null) controller.toggleSiswaSelection(siswa.uid, value);
                  },
                  title: Text(siswa.nama),
                  subtitle: Text(siswa.namaTingkatan),
                ));
              },
            );
          }),
        ),
      ],
    );
  }
}