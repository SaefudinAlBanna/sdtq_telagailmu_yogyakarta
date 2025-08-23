// lib/app/modules/guru_akademik/views/guru_akademik_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/guru_akademik_controller.dart';

class GuruAkademikView extends GetView<GuruAkademikController> {
  const GuruAkademikView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas & Mapel Saya'),
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.isWaliKelas.value) { // <-- Gunakan .value
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.fact_check_outlined),
                    onPressed: controller.goToAbsensi,
                    // Gunakan Obx lagi untuk tooltip yang reaktif
                    tooltip: "Absensi Kelas ${controller.kelasDiampuId.value.split('-').first}", 
                  ),
                  IconButton(
                    icon: const Icon(Icons.bar_chart_rounded),
                    onPressed: controller.goToRekapAbsensiKelas,
                    tooltip: "Rekap Absensi Kelas ${controller.kelasDiampuId.value.split('-').first}",
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarMapelDiampu.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Anda belum memiliki penugasan mengajar untuk tahun ajaran ini.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchMapelDiampu(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.daftarMapelDiampu.length,
           itemBuilder: (context, index) {
              final mapel = controller.daftarMapelDiampu[index];
              
              // Tampilan untuk guru REGULER (tidak digantikan)
              if (!mapel.isPengganti) {
                return Card(
                  elevation: 2, margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      child: Icon(Icons.book_outlined, color: Colors.indigo.shade700),
                    ),
                    title: Text(mapel.namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Kelas: ${mapel.idKelas}"),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => controller.goToDaftarSiswaPermapel(mapel),
                  ),
                );
              } 
              // Tampilan untuk guru PENGGANTI
              else {
                return Card(
                  elevation: 2, margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.shade400, width: 1.5) // Beri border untuk menandai
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withOpacity(0.15),
                      child: Icon(Icons.people_alt_rounded, color: Colors.amber.shade800),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mapel.namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (mapel.namaGuruAsli != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              "Menggantikan: ${mapel.namaGuruAsli}",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text("Kelas: ${mapel.idKelas}"),
                    trailing: const Chip(
                      label: Text('Pengganti', style: TextStyle(fontSize: 10)), 
                      padding: EdgeInsets.symmetric(horizontal: 4), 
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.amber,
                    ),
                    onTap: () => controller.goToDaftarSiswaPermapel(mapel),
                  ),
                );
              }
            },
          ),
        );
      }),
    );
  }
}