import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/siswa_laporan_model.dart';
import '../controllers/laporan_akademik_controller.dart';

class LaporanAkademikView extends GetView<LaporanAkademikController> {
  const LaporanAkademikView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan Akademik (Mata Elang)")),
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
            labelColor: Get.theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Peringkat Kelas"),
              Tab(text: "Detail Nilai"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _buildPeringkatTab(),
                _buildDetailNilaiTab(), // Placeholder
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPeringkatTab() {
    return ListView.builder(
      itemCount: controller.siswaDiKelas.length,
      itemBuilder: (context, index) {
        final siswa = controller.siswaDiKelas[index];
        return ListTile(
          leading: CircleAvatar(child: Text("${index + 1}")),
          title: Text(siswa.nama),
          subtitle: Text("NISN: ${siswa.nisn}"),
          trailing: Text(
            siswa.nilaiAkhirRapor.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }

  Widget _buildDetailNilaiTab() {
    // Placeholder untuk pengembangan selanjutnya
    return const Center(child: Text("Fitur Detail Nilai per Siswa akan dikembangkan."));
  }
}