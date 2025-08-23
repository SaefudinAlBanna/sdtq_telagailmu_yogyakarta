// lib/app/modules/rekap_absensi/views/rekap_absensi_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/absensi_rekap_model.dart';
import '../controllers/rekap_absensi_controller.dart';

class RekapAbsensiView extends GetView<RekapAbsensiController> {
  const RekapAbsensiView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapitulasi Absensi'),
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(context),
          
          // Content Section
          Expanded(
            child: Obx(() {
              if (controller.selectedKelasId.value == null && controller.scope.value == 'sekolah') {
                return const Center(child: Text("Silakan pilih kelas untuk melihat rekap."));
              }
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.rekapData.isEmpty) {
                return const Center(child: Text("Tidak ada data absensi pada rentang tanggal ini."));
              }
              return Column(
                children: [
                  _buildTotalRekapSection(),
                  const Divider(thickness: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.rekapData.length,
                      itemBuilder: (context, index) {
                        final rekapHarian = controller.rekapData[index];
                        return _buildRekapHarianItem(rekapHarian);
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Filter Kelas (hanya untuk pimpinan)
          if (controller.scope.value == 'sekolah')
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedKelasId.value,
              hint: const Text("Pilih Kelas"),
              items: controller.daftarKelas.map((doc) {
                final id = doc.id;
                final nama = (doc.data() as Map<String, dynamic>)['namaKelas'] ?? 'Tanpa Nama';
                return DropdownMenuItem(value: id, child: Text(nama));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedKelasId.value = value;
                  controller.fetchRekapData();
                }
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            )),
          const SizedBox(height: 12),
          
          // Filter Tanggal
          OutlinedButton.icon(
            onPressed: () => controller.pickDateRange(context),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Obx(() => Text(
              "${DateFormat('dd MMM yyyy').format(controller.startDate.value)} - ${DateFormat('dd MMM yyyy').format(controller.endDate.value)}",
            )),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildTotalRekapSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _rekapItem("Hadir", controller.totalRekap['hadir'] ?? 0, Colors.green.shade700),
          _rekapItem("Sakit", controller.totalRekap['sakit'] ?? 0, Colors.orange.shade700),
          _rekapItem("Izin", controller.totalRekap['izin'] ?? 0, Colors.blue.shade700),
          _rekapItem("Alfa", controller.totalRekap['alfa'] ?? 0, Colors.red.shade700),
        ],
      )),
    );
  }

  Widget _rekapItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }

  Widget _buildRekapHarianItem(AbsensiRekapModel rekap) {
    final rekapSiswa = rekap.siswa;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        title: Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(rekap.tanggal.toDate())),
        subtitle: Text("H:${rekap.rekap['hadir']} S:${rekap.rekap['sakit']} I:${rekap.rekap['izin']} A:${rekap.rekap['alfa']}"),
        children: rekapSiswa.entries.map((entry) {
          final detail = entry.value;
          return ListTile(
            dense: true,
            leading: CircleAvatar(radius: 12, child: Text(detail['status'])),
            title: Text(detail['nama']),
            subtitle: Text(detail['keterangan'] ?? 'Tidak ada keterangan'),
          );
        }).toList(),
      ),
    );
  }
}