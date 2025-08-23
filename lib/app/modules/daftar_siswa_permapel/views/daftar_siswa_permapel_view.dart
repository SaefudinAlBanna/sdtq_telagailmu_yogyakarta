// lib/app/modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daftar_siswa_permapel_controller.dart';

class DaftarSiswaPermapelView extends GetView<DaftarSiswaPermapelController> {
  const DaftarSiswaPermapelView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(controller.namaMapel, style: const TextStyle(fontSize: 18)),
            Text(controller.idKelas, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: "Menu Tugas & Penilaian",
            onSelected: (value) {
              if (value == 'buat_tugas') _showBuatTugasDialog(context);
              if (value == 'input_nilai') {
                controller.showPilihTugasDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'buat_tugas', child: ListTile(leading: Icon(Icons.note_add_outlined), title: Text("Buat Tugas/Ulangan"))),
              const PopupMenuItem(value: 'input_nilai', child: ListTile(leading: Icon(Icons.grading_rounded), title: Text("Input Nilai Massal"))),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.daftarSiswa.isEmpty) return const Center(child: Text("Belum ada siswa di kelas ini."));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.daftarSiswa.length,
          itemBuilder: (context, index) {
            final siswa = controller.daftarSiswa[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              // --- [PERBAIKAN UX] Beri warna berbeda jika list tidak bisa di-klik ---
              color: controller.isPengganti ? Colors.grey.shade100 : null,
              child: ListTile(
                leading: CircleAvatar(child: Text(siswa.namaLengkap[0])),
                title: Text(siswa.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("NISN: ${siswa.nisn}"),
                // --- [PERBAIKAN UX] Hilangkan ikon jika tidak bisa di-klik ---
                trailing: controller.isPengganti ? null : const Icon(Icons.chevron_right),
                // --- [PERBAIKAN UX] Nonaktifkan onTap untuk guru pengganti ---
                onTap: controller.isPengganti ? null : () => controller.goToInputNilaiSiswa(siswa),
              ),
            );
          },
        );
      }),
    );
  }

  void _showBuatTugasDialog(BuildContext context) {
    Get.defaultDialog(
      title: "Buat Tugas / Ulangan Baru",
      content: Column(
        children: [
          TextField(controller: controller.judulTugasC, decoration: const InputDecoration(labelText: 'Judul (Contoh: PR Bab 1)')),
          const SizedBox(height: 12),
          TextField(controller: controller.deskripsiTugasC, decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'), maxLines: 3),
        ],
      ),
      actions: [
        OutlinedButton(onPressed: () => controller.buatTugasBaru("Ulangan"), child: const Text("Simpan Ulangan")),
        ElevatedButton(onPressed: () => controller.buatTugasBaru("PR"), child: const Text("Simpan PR")),
      ],
    );
  }
}