// lib/app/modules/penjadwalan_ujian/views/penjadwalan_ujian_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/penjadwalan_ujian_controller.dart';

class PenjadwalanUjianView extends GetView<PenjadwalanUjianController> {
  const PenjadwalanUjianView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjadwalan Ujian Halaqah'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarPengajuan.isEmpty) {
          return const Center(child: Text("Tidak ada siswa yang diajukan untuk ujian."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.daftarPengajuan.length,
          itemBuilder: (context, index) {
            final pengajuan = controller.daftarPengajuan[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(pengajuan.namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Kelas: ${pengajuan.kelasId} | Diajukan oleh: ${pengajuan.namaPengaju}"),
                trailing: ElevatedButton(
                  child: const Text("Atur Jadwal"),
                  onPressed: () => controller.showSchedulingDialog(pengajuan),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}