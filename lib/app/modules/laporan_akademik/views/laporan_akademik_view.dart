// lib/app/modules/laporan_akademik/views/laporan_akademik_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/siswa_laporan_model.dart';
import '../controllers/laporan_akademik_controller.dart';

class LaporanAkademikView extends GetView<LaporanAkademikController> {
  const LaporanAkademikView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dasbor Pantauan Akademik"),
      actions: [
        IconButton(
          icon: const Icon(Icons.school_outlined),
          onPressed: () => controller.goToGuruAkademik(),
          tooltip: "Akademik",
        ),
      ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarKelas.isEmpty) {
          return const Center(child: Text("Tidak ada kelas di tahun ajaran ini."));
        }
        return Column(
          children: [
            _buildKelasSelector(),
            _buildInfoKontekstual(),
            Expanded(child: _buildDetailContent()),
          ],
        );
      }),
    );
  }

  Widget _buildKelasSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.white,
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.daftarKelas.length,
        itemBuilder: (context, index) {
          final kelas = controller.daftarKelas[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Obx(() => ChoiceChip(
                  label: Text(kelas['namaKelas']),
                  selected: controller.kelasTerpilih.value?['id'] == kelas['id'],
                  onSelected: (_) => controller.onKelasChanged(kelas),
                  selectedColor: Get.theme.primaryColor,
                  labelStyle: TextStyle(
                      color: controller.kelasTerpilih.value?['id'] == kelas['id']
                          ? Colors.white
                          : Colors.black),
                )),
          );
        },
      ),
    );
  }

  Widget _buildInfoKontekstual() {
    return Obx(() {
      if (controller.kelasTerpilih.value == null) return const SizedBox.shrink();
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoItem("Wali Kelas", controller.infoWaliKelas.value),
              _infoItem("Jumlah Siswa", "${controller.siswaDiKelas.length} Siswa"),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDetailContent() {
    return Obx(() {
      if (controller.kelasTerpilih.value == null) {
        return const Center(child: Text("Silakan pilih kelas untuk melihat laporan."));
      }
      if (controller.isDetailLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        children: [
          TabBar(
            controller: controller.tabController,
            tabs: const [
              Tab(text: "Peringkat Kelas"),
              Tab(text: "Detail Siswa"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _buildPeringkatTab(),
                _buildDetailSiswaTab(), // [DIUBAH]
              ],
            ),
          ),
        ],
      );
    });
  }

  // [PEROMBAKAN UI DI SINI]
  Widget _buildPeringkatTab() {
    return ListView.builder(
      itemCount: controller.siswaDiKelas.length,
      itemBuilder: (context, index) {
        final siswa = controller.siswaDiKelas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            // [REVISI: LOGIKA TAMPILAN FOTO]
            leading: (siswa.fotoProfilUrl != null && siswa.fotoProfilUrl!.isNotEmpty)
                ? CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(siswa.fotoProfilUrl!),
                    backgroundColor: Colors.grey.shade200,
                  )
                : CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text("${index + 1}", style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold)),
                  ),
            
            title: Text(siswa.nama),
            subtitle: Text("NISN: ${siswa.nisn}"),
            trailing: _buildTrailingNilai(siswa.nilaiAkhirRapor),
            onTap: () => controller.onSiswaTapped(siswa),
          ),
        );
      },
    );
  }
  
  Widget _buildTrailingNilai(double nilai) {
    Color color = Colors.grey;
    if (nilai >= 85) color = Colors.green;
    else if (nilai >= 75) color = Colors.blue;
    else if (nilai >= 65) color = Colors.orange;
    else color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Text(
        nilai.toStringAsFixed(1),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
      ),
    );
  }

  // [WIDGET BARU UNTUK PILAR 3]
  Widget _buildDetailSiswaTab() {
    return Obx(() {
      final siswa = controller.siswaTerpilihDetail.value;
      if (siswa == null) {
        return const Center(child: Text("Ketuk nama siswa di tab 'Peringkat Kelas' untuk melihat detail."));
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Detail Laporan: ${siswa.nama}", style: Get.textTheme.titleLarge),
          const SizedBox(height: 16),
          // Di sini kita bisa menambahkan Card untuk menampilkan metrik baru
          // _buildDetailMetricCard(siswa),
          const Text("Rincian Nilai per Mata Pelajaran:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Obx(() {
            if(controller.detailNilaiSiswa.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Belum ada nilai untuk siswa ini.")));
            }
            return Card(
              child: Column(
                children: controller.detailNilaiSiswa.map((mapel) {
                  return ListTile(
                    title: Text(mapel['mapel']),
                    trailing: _buildTrailingNilai(mapel['nilai_akhir']),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      );
    });
  }
}