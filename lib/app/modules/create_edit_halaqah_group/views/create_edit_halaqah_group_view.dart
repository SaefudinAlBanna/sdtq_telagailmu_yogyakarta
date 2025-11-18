// lib/app/modules/create_edit_halaqah_group/views/create_edit_halaqah_group_view.dart

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/pegawai_simple_model.dart';
import '../../../models/siswa_simple_model.dart';
import '../controllers/create_edit_halaqah_group_controller.dart';

class CreateEditHalaqahGroupView extends GetView<CreateEditHalaqahGroupController> {
  const CreateEditHalaqahGroupView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(controller.isEditMode.value ? 'Edit Grup Halaqah' : 'Buat Grup Halaqah'),
          actions: [
            Obx(() => TextButton(
                  onPressed: controller.isSaving.value ? null : controller.saveGroup,
                  child: controller.isSaving.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text("SIMPAN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                )),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildFormSection(),
              const TabBar(
                tabs: [
                  Tab(text: "Anggota Grup"),
                  Tab(text: "Siswa Tersedia"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAnggotaGrupTab(),
                    _buildSiswaTersediaTab(),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // [FIX] Menggunakan kode yang sudah benar dari diskusi terakhir kita
  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Obx(() => DropdownSearch<PegawaiSimpleModel>(
                items: (f, cs) => controller.daftarPengampu.toList(),
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Pilih Pengampu",
                    border: OutlineInputBorder(),
                  ),
                ),
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(hintText: "Cari nama pengampu..."),
                  ),
                ),

                // [PERBAIKAN KUNCI] Logika tampilan dibuat lebih kuat
                itemAsString: (PegawaiSimpleModel p) {
                  // Cek dulu apakah alias memiliki nilai yang valid (tidak null dan tidak kosong)
                  if (p.alias.isNotEmpty) {
                    // Jika ada, tampilkan format lengkap "Nama (Alias)"
                    return "${p.nama} (${p.alias})";
                  }
                  // Jika tidak ada alias, HANYA tampilkan nama untuk menghindari "Nama ()"
                  return p.nama;
                },

                compareFn: (item1, item2) => item1.uid == item2.uid,
                selectedItem: controller.selectedPengampu.value,
                onChanged: (value) {
                  controller.selectedPengampu.value = value;
                },
              )),
          const SizedBox(height: 12),
          TextField(
            controller: controller.namaGrupC,
            decoration: const InputDecoration(
              labelText: "Nama Grup Halaqah",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnggotaGrupTab() {
    return Obx(() {
      if (controller.anggotaGrup.isEmpty) {
        return const Center(child: Text("Belum ada anggota di grup ini."));
      }
      return ListView.builder(
        itemCount: controller.anggotaGrup.length,
        itemBuilder: (context, index) {
          final siswa = controller.anggotaGrup[index];
          return ListTile(
            title: Text(siswa.nama),
            subtitle: Text("Kelas: ${siswa.kelasId}"),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => controller.removeSiswaFromGroup(siswa),
            ),
          );
        },
      );
    });
  }

  Widget _buildSiswaTersediaTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 40,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  children: controller.daftarKelas
                      .map((kelasId) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(kelasId),
                              selected: controller.selectedKelasFilter.value == kelasId,
                              onSelected: (selected) {
                                if (selected) controller.fetchAvailableStudentsByClass(kelasId);
                              },
                            ),
                          ))
                      .toList(),
                )),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: controller.searchC,
            decoration: InputDecoration(
              hintText: "Cari nama siswa...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Obx(() {
            if (controller.selectedKelasFilter.value.isEmpty) {
              return const Center(child: Text("Pilih kelas di atas untuk melihat siswa."));
            }
            final displayedSiswa = controller.filteredSiswaTersedia;
            if (controller.siswaTersedia.isEmpty) {
              return const Center(child: Text("Tidak ada siswa tersedia di kelas ini."));
            }
            if (displayedSiswa.isEmpty && controller.searchQuery.value.isNotEmpty) {
              return Center(child: Text("Siswa dengan nama \"${controller.searchQuery.value}\" tidak ditemukan."));
            }
            return ListView.builder(
              itemCount: displayedSiswa.length,
              itemBuilder: (context, index) {
                final siswa = displayedSiswa[index];
                return ListTile(
                  title: Text(siswa.nama),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () => controller.addSiswaToGroup(siswa),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}