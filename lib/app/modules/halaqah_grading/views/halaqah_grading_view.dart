// lib/app/modules/halaqah_grading/views/halaqah_grading_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_simple_model.dart';

import '../../../utils/halaqah_utils.dart';
import '../controllers/halaqah_grading_controller.dart';

class HalaqahGradingView extends GetView<HalaqahGradingController> {
  const HalaqahGradingView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.group.namaGrup),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: "Input Nilai Rapor Anggota",
            onPressed: controller.showInputNilaiRaporDialog,
          ),
        ],
      ),
      // [DIUBAH] Sesuaikan tipe data FutureBuilder
      body: FutureBuilder<List<AnggotaGrupDetail>>(
        future: controller.listAnggotaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada anggota di grup ini."));

          final anggotaList = snapshot.data!;
          
          anggotaList.sort((a, b) {
            // [DIUBAH] Akses UID melalui model helper
            final statusA = controller.siswaUjianStatusMap[a.siswa.uid];
            final statusB = controller.siswaUjianStatusMap[b.siswa.uid];

            int scoreA = _getSiswaSortScore(statusA, controller.antrianMap.containsKey(a.siswa.uid));
            int scoreB = _getSiswaSortScore(statusB, controller.antrianMap.containsKey(b.siswa.uid));

            if (scoreA != scoreB) return scoreB.compareTo(scoreA);
            
            final waktuA = controller.antrianMap[a.siswa.uid];
            final waktuB = controller.antrianMap[b.siswa.uid];
            if (waktuA != null && waktuB != null) return waktuA.compareTo(waktuB);
            if (waktuA != null) return -1;
            if (waktuB != null) return 1;
            return a.siswa.nama.compareTo(b.siswa.nama);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: anggotaList.length,
            itemBuilder: (context, index) {
              final anggotaDetail = anggotaList[index];
              final anggota = anggotaDetail.siswa; // Ambil data siswa dari model helper
              final ujianStatus = controller.siswaUjianStatusMap[anggota.uid];
              
              // [DIUBAH] Ambil data tingkatan langsung dari model helper
              final tingkatanData = anggotaDetail.tingkatan;
              final namaTingkatan = tingkatanData?['nama'] as String? ?? 'Belum Diatur';
            
              return Container(
                decoration: BoxDecoration(
                  color: _getHighlightColor(ujianStatus),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    onTap: () => controller.goToRiwayatSiswa(anggota),
                    leading: CircleAvatar(
                      radius: 25,
                      // [FIX 4 & 5] Mengganti 'urutan' dengan logika inisial nama yang sudah ada
                      child: Text(anggota.nama.isNotEmpty ? anggota.nama[0].toUpperCase() : '-'),
                    ),
                    title: Text(anggota.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Kelas Asal: ${anggota.kelasId}"),
                          const SizedBox(height: 4),
                          // [BARU] Tampilkan Chip Tingkatan di sini
                          Chip(
                            label: Text(namaTingkatan, style: const TextStyle(color: Colors.white, fontSize: 10)),
                            backgroundColor: HalaqahUtils.getWarnaTingkatan(namaTingkatan),
                            avatar: const Icon(Icons.bookmark, color: Colors.white, size: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    trailing: _buildTrailingWidget(anggota, ujianStatus),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  

  int _getSiswaSortScore(String? status, bool isInAntrian) {
    if (status == 'dijadwalkan') return 3;
    if (status == 'diajukan') return 2;
    if (isInAntrian) return 1;
    return 0; // Default
  }

  // [BARU] Helper untuk menentukan warna highlight
  Color? _getHighlightColor(String? status) {
    if (status == 'dijadwalkan') return Colors.teal.shade50;
    if (status == 'diajukan') return Colors.orange.shade50;
    return null; // Transparan
  }

  // [BARU] Helper untuk membangun widget trailing yang dinamis
  Widget _buildTrailingWidget(SiswaSimpleModel anggota, String? ujianStatus) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ujianStatus == 'dijadwalkan')
          const Chip(
            label: Text("Terjadwal"),
            avatar: Icon(Icons.check_circle, color: Colors.white, size: 14),
            backgroundColor: Colors.teal,
            labelStyle: TextStyle(color: Colors.white, fontSize: 10),
          )
        else if (ujianStatus == 'diajukan')
          // [MODIFIKASI] Tombol batal sekarang menjadi Ikon saja agar lebih ringkas
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            tooltip: "Batalkan Pengajuan",
            onPressed: () => controller.batalkanPengajuanUjian(anggota),
            color: Colors.orange.shade700,
          )
        else // Belum diajukan
          IconButton(
            icon: const Icon(Icons.military_tech_outlined),
            tooltip: "Ajukan Siswa untuk Ujian",
            onPressed: () => controller.ajukanSiswaUntukUjian(anggota),
            color: Colors.teal,
          ),
        
        const SizedBox(width: 8),
  
        ElevatedButton(
          onPressed: () => controller.goToSetoranPage(anggota),
          child: const Text("Setoran"),
        ),
      ],
    );
  }
}

class HalaqahGradingDialogContent extends StatelessWidget {
  final List<AnggotaGrupDetail> anggota;
  final Map<String, TextEditingController> nilaiControllers;
  final Map<String, TextEditingController> catatanControllers;

  const HalaqahGradingDialogContent({
    Key? key,
    required this.anggota,
    required this.nilaiControllers,
    required this.catatanControllers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width * 0.9, // Lebar dialog
      height: Get.height * 0.6, // Tinggi dialog
      child: ListView.builder(
        itemCount: anggota.length,
        itemBuilder: (context, index) {
          final detail = anggota[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: nilaiControllers[detail.siswa.uid],
                        decoration: const InputDecoration(labelText: 'Nilai', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: catatanControllers[detail.siswa.uid],
                        decoration: const InputDecoration(labelText: 'Catatan Akhir Semester', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}