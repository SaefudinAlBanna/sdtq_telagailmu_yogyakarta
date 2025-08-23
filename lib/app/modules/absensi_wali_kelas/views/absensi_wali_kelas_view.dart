// lib/app/modules/absensi_wali_kelas/views/absensi_wali_kelas_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_simple_model.dart';
import '../controllers/absensi_wali_kelas_controller.dart';

class AbsensiWaliKelasView extends GetView<AbsensiWaliKelasController> {
  const AbsensiWaliKelasView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Kelas'),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.isSaving.value ? null : controller.simpanAbsensi,
            child: Text("SIMPAN", style: TextStyle(color: controller.isSaving.value ? Colors.grey : Colors.black, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildHeaderRekap(),
            _buildCatatanHarian(),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: controller.daftarSiswa.length,
                itemBuilder: (context, index) {
                  final siswa = controller.daftarSiswa[index];
                  return _buildSiswaItem(siswa);
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeaderRekap() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Text(
            "Absensi untuk ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now())}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _rekapItem("Total Siswa", controller.totalSiswa.value, Colors.black),
              _rekapItem("Hadir", controller.totalHadir.value, Colors.green.shade700),
              _rekapItem("Sakit", controller.totalSakit.value, Colors.orange.shade700),
              _rekapItem("Izin", controller.totalIzin.value, Colors.blue.shade700),
              _rekapItem("Alfa", controller.totalAlfa.value, Colors.red.shade700),
            ],
          )),
        ],
      ),
    );
  }
  
  Widget _rekapItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
  
  Widget _buildCatatanHarian() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller.catatanHarianC,
        decoration: const InputDecoration(
          isDense: true,
          hintText: "Catatan harian kelas (opsional)...",
          prefixIcon: Icon(Icons.note_alt_outlined),
        ),
      ),
    );
  }

  Widget _buildSiswaItem(SiswaSimpleModel siswa) {
    return Obx(() {
      final status = controller.statusAbsensi[siswa.uid] ?? 'H';
      final showKeterangan = status == 'S' || status == 'I' || status == 'A';
      return Column(
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(siswa.nama.isNotEmpty ? siswa.nama[0] : '-')),
            title: Text(siswa.nama),
            trailing: ToggleButtons(
              isSelected: [status == 'S', status == 'I', status == 'A'],
              onPressed: (index) {
                if (index == 0) controller.setStatusAbsensi(siswa.uid, 'S');
                if (index == 1) controller.setStatusAbsensi(siswa.uid, 'I');
                if (index == 2) controller.setStatusAbsensi(siswa.uid, 'A');
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("S")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("I")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("A")),
              ],
            ),
          ),
          if (showKeterangan)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
              child: TextField(
                controller: controller.keteranganControllers[siswa.uid],
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Keterangan (misal: surat dokter)...",
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
              ),
            ),
        ],
      );
    });
  }
}