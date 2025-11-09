// lib/app/modules/halaqah_dashboard/views/halaqah_dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_dashboard_student_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/halaqah_dashboard_controller.dart';

class HalaqahDashboardView extends GetView<HalaqahDashboardController> {
  const HalaqahDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Halaqah"),
        // leading: Obx(() => controller.isRunningScript.value 
        //   ? Padding(padding: const EdgeInsets.all(18.0), child: CircularProgressIndicator(color: Colors.indigo, strokeWidth: 2,))
        //   : IconButton(
        //       icon: Icon(Icons.sync),
        //       tooltip: "Jalankan Skrip Sinkronisasi",
        //       onPressed: controller.runDenormalizationScript,
        //     )
        // ),
        
        actions: [
        if (controller.dashC.kepalaSekolah || controller.dashC.canManageHalaqah)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_outlined),
            tooltip: "Pengaturan Halaqah",
            onSelected: (value) {
              if (value == 'Manajemen Penguji') {Get.toNamed(Routes.MANAJEMEN_PENGUJI);}
              if (value == 'Penjadwalan') {Get.toNamed(Routes.PENJADWALAN_UJIAN);}
              if (value == 'Manajemen Tingkatan') {Get.toNamed(Routes.MANAJEMEN_TINGKATAN_SISWA);}
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Manajemen Penguji', child: ListTile(leading: Icon(Icons.person_add_alt_outlined), title: Text("Manajemen Penguji"))),
              const PopupMenuItem(value: 'Penjadwalan', child: ListTile(leading: Icon(Icons.grading_rounded), title: Text("Penjadwalan"))),
              const PopupMenuItem(value: 'Manajemen Tingkatan', child: ListTile(leading: Icon(Icons.grade_outlined), title: Text("Manajemen Tingkatan"))),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchDataForDashboard(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFilterKelas(),
              const SizedBox(height: 16),
              _buildKpiCards(),
              const SizedBox(height: 24),
              _buildSection(
                title: "Siswa Tanpa Grup (${controller.siswaTanpaGrup.length})",
                icon: Icons.person_off_outlined,
                child: _buildSiswaList(controller.siswaTanpaGrup),
                // Tampilkan sebagai peringatan jika ada siswa tanpa grup
                isWarning: controller.siswaTanpaGrup.isNotEmpty,
                isExpanded: controller.siswaTanpaGrup.isNotEmpty,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterKelas() {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.selectedKelas.value,
      items: controller.daftarKelas.map((kelas) => DropdownMenuItem(value: kelas, child: Text(kelas))).toList(),
      onChanged: controller.onKelasFilterChanged,
      decoration: const InputDecoration(labelText: "Filter Berdasarkan Kelas", border: OutlineInputBorder()),
    ));
  }

  Widget _buildKpiCards() {
    return Obx(() => Column(
      children: [
        Row(
          children: [
            _buildKpiItem("Total Siswa", controller.semuaSiswaDiFilter.length.toString(), Colors.blue),
            _buildKpiItem("Tanpa Grup", controller.siswaTanpaGrup.length.toString(), controller.siswaTanpaGrup.isEmpty ? Colors.green : Colors.red),
          ],
        ),
        Row(
          children: [
            _buildKpiItem("Total Grup", controller.totalGrupAktif.value.toString(), Colors.indigo),
            _buildKpiItem("Dalam Ujian", controller.siswaDalamSiklusUjian.value.toString(), Colors.orange),
          ],
        ),
      ],
    ));
  }

  Widget _buildKpiItem(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child, bool isWarning = false, bool isExpanded = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isWarning ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        leading: Icon(icon, color: isWarning ? Colors.red : Get.theme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSiswaList(List<HalaqahDashboardStudentModel> siswaList) {
    if (siswaList.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text("Tidak ada data."));
    return Column(
      children: siswaList.map((siswa) {
        String subtitle = "Kelas: ${siswa.kelasId.split('-').first}";
        return ListTile(
          dense: true,
          title: Text(siswa.nama),
          subtitle: Text(subtitle),
        );
      }).toList(),
    );
  }
}