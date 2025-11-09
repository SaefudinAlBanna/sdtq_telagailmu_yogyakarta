// lib/app/modules/jadwal_ujian_penguji/views/jadwal_ujian_penguji_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/jadwal_ujian_penguji_controller.dart';

class JadwalUjianPengujiView extends GetView<JadwalUjianPengujiController> {
  const JadwalUjianPengujiView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Ujian Saya'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarJadwal.isEmpty) {
          return const Center(child: Text("Tidak ada jadwal ujian yang ditugaskan kepada Anda."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.daftarJadwal.length,
          itemBuilder: (context, index) {
            final jadwal = controller.daftarJadwal[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(jadwal.namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Kelas: ${jadwal.kelasId}"),
                trailing: ElevatedButton(
                  child: const Text("Beri Penilaian"),
                  onPressed: () => controller.showAssessmentDialog(jadwal),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}