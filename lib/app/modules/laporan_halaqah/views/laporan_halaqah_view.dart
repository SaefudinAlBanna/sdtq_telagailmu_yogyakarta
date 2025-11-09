// lib/app/modules/laporan_halaqah/views/laporan_halaqah_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/widgets/avatar_pengampu.dart';

import '../../../utils/halaqah_utils.dart';
import '../controllers/laporan_halaqah_controller.dart';

class LaporanHalaqahView extends GetView<LaporanHalaqahController> {
  const LaporanHalaqahView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Halaqah (Pantau)"),
        actions: [
          // [BARU] Tombol untuk beralih mode
          Obx(() => IconButton(
            icon: Icon(controller.isModePerGrup.value ? Icons.search : Icons.group_work_outlined),
            tooltip: controller.isModePerGrup.value ? "Mode Pencarian Siswa" : "Mode Lihat per Grup",
            onPressed: controller.toggleMode,
          )),
        ],
      ),
      body: Obx(() {
        // Tampilkan loading jika salah satu data utama belum siap
        if (controller.isLoadingSiswa.value || controller.isLoadingGrup.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Beralih tampilan berdasarkan mode
        return controller.isModePerGrup.value 
          ? _buildModePerGrup() 
          : _buildModePencarianSiswa();
      }),
    );
  }

  // [BARU] Widget untuk tampilan mode "Lihat per Grup"
  Widget _buildModePerGrup() {
    return Column(
      children: [
        _buildGroupSelector(),
        Expanded(
          child: Obx(() {
            if (controller.grupTerpilih.value == null) {
              return const Center(child: Text("Silakan pilih grup di atas."));
            }
            if (controller.isDetailGrupLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildSiswaListView(controller.anggotaGrupTerpilih);
          }),
        ),
      ],
    );
  }
  
  // [BARU] Widget untuk tampilan mode "Pencarian Siswa"
  Widget _buildModePencarianSiswa() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: controller.searchC,
            decoration: InputDecoration(
              hintText: "Cari nama siswa...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: Obx(() => _buildSiswaListView(controller.filteredSiswa)),
        ),
      ],
    );
  }

  // Widget _buildSiswaListView(List<Map<String, dynamic>> siswaList) {
  //   if (siswaList.isEmpty) return const Center(child: Text("Tidak ada siswa ditemukan."));
    
  //   return ListView.builder(
  //     itemCount: siswaList.length,
  //     itemBuilder: (context, index) {
  //       final siswa = siswaList[index];
  //       final grupData = siswa['grupHalaqah'] as Map<String, dynamic>?;
  //       final statusUjian = siswa['statusUjianHalaqah'] as String?;
  //       final setoranData = siswa['setoranTerakhirHalaqah'] as Map<String, dynamic>?;
  
  //       final namaPengampu = grupData?['namaPengampu'] as String? ?? 'N/A';
  //       final namaGrup = grupData?['namaGrup'] as String? ?? 'Belum terdaftar';
  
  //       // Ekstrak data tugas dan nilai dari setoran terakhir
  //       final tugas = setoranData?['tugas'] as Map<String, dynamic>?;
  //       final nilai = setoranData?['nilai'] as Map<String, dynamic>?;
  
  //       return Card(
  //         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  //         // [UPGRADE] Gunakan ExpansionTile untuk detail
  //         child: ExpansionTile(
  //           leading: AvatarPengampu(
  //             imageUrl: siswa['profileImageUrl'], 
  //             nama: siswa['namaLengkap'] ?? '?',
  //             radius: 22,
  //           ),
  //           title: Text(siswa['namaLengkap'] ?? 'Tanpa Nama'),
  //           subtitle: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text("Kelas: ${siswa['kelasId'] ?? 'N/A'}"),
  //               if (grupData != null)
  //                 Text("Grup: $namaGrup", overflow: TextOverflow.ellipsis),
  //               if (grupData == null)
  //                 const Text("Grup: Belum terdaftar", style: TextStyle(color: Colors.red)),
  //             ],
  //           ),
  //           trailing: _buildStatusUjianChip(statusUjian),
  
  //           // [BARU] Detail yang akan muncul saat di-expand
  //           children: <Widget>[
  //             Padding(
  //               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Divider(),
  //                   const Text("Rincian Setoran Terakhir:", style: TextStyle(fontWeight: FontWeight.bold)),
  //                   const SizedBox(height: 8),
  
  //                   if (tugas == null)
  //                     const Text("Belum ada data setoran.", style: TextStyle(fontStyle: FontStyle.italic)),
  
  //                   if (tugas != null) ...[
  //                     _buildDetailRow("Sabaq", tugas['sabak'], nilai?['sabak']),
  //                     _buildDetailRow("Sabqi", tugas['sabqi'], nilai?['sabqi']),
  //                     _buildDetailRow("Manzil", tugas['manzil'], nilai?['manzil']),
  //                     _buildDetailRow("Tambahan", tugas['tambahan'], nilai?['tambahan']),
  //                   ]
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildSiswaListView(List<Map<String, dynamic>> siswaList) {
    if (siswaList.isEmpty) {
      return const Center(child: Text("Tidak ada siswa ditemukan."));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16), // Beri padding di bawah
      itemCount: siswaList.length,
      itemBuilder: (context, index) {
        final siswa = siswaList[index];
        
        // Ekstrak semua data dengan aman (menggunakan null-aware)
        final grupData = siswa['grupHalaqah'] as Map<String, dynamic>?;
        final statusUjian = siswa['statusUjianHalaqah'] as String?;
        final setoranData = siswa['setoranTerakhirHalaqah'] as Map<String, dynamic>?;
        final tingkatanData = siswa['halaqahTingkatan'] as Map<String, dynamic>?;
        
        // Siapkan variabel tampilan dengan nilai default yang aman
        final namaTingkatan = tingkatanData?['nama'] as String? ?? 'Belum Diatur';
        final namaPengampu = grupData?['namaPengampu'] as String? ?? 'N/A';
        final namaGrup = grupData?['namaGrup'] as String? ?? 'Belum terdaftar';
  
        // Ekstrak data tugas dan nilai dari setoran terakhir
        final tugas = setoranData?['tugas'] as Map<String, dynamic>?;
        final nilai = setoranData?['nilai'] as Map<String, dynamic>?;
  
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: AvatarPengampu(
              imageUrl: siswa['profileImageUrl'] as String?,
              nama: siswa['namaLengkap'] as String? ?? '?',
              radius: 22,
            ),
            title: Row(
              children: [
                Expanded(child: Text(siswa['namaLengkap'] as String? ?? 'Tanpa Nama')),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    namaTingkatan,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: HalaqahUtils.getWarnaTingkatan(namaTingkatan),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Kelas: ${siswa['kelasId'] as String? ?? 'N/A'}"),
                if (grupData != null)
                  Text("Grup: $namaGrup", overflow: TextOverflow.ellipsis),
                if (grupData == null)
                  const Text("Grup: Belum terdaftar", style: TextStyle(color: Colors.red)),
              ],
            ),
            trailing: _buildStatusUjianChip(statusUjian),
  
            // Detail yang akan muncul saat di-expand
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text("Rincian Setoran Terakhir:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
  
                    if (tugas == null)
                      const Text(
                        "Belum ada data setoran.",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
  
                    if (tugas != null) ...[
                      _buildDetailRow("Sabaq", tugas['sabak'] as String?, nilai?['sabak'] as String?),
                      _buildDetailRow("Sabqi", tugas['sabqi'] as String?, nilai?['sabqi'] as String?),
                      _buildDetailRow("Manzil", tugas['manzil'] as String?, nilai?['manzil'] as String?),
                      _buildDetailRow("Tambahan", tugas['tambahan'] as String?, nilai?['tambahan'] as String?),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // [BARU] Tambahkan widget helper ini di dalam class LaporanHalaqahView
  Widget _buildDetailRow(String title, String? tugas, String? nilai) {
    if (tugas == null || tugas.isEmpty) return const SizedBox.shrink();
  
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("$title:", style: const TextStyle(color: Colors.grey))),
          Expanded(flex: 5, child: Text(tugas)),
          if (nilai != null && nilai.isNotEmpty)
            Expanded(flex: 2, child: Text(nilai, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
  
  // Widget Chip Selector Grup (dari kode lama, sedikit modifikasi)
  Widget _buildGroupSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.white,
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.daftarGrup.length,
        itemBuilder: (context, index) {
          final grup = controller.daftarGrup[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Obx(() => ChoiceChip(
                  label: Text(grup['namaGrup']),
                  selected: controller.grupTerpilih.value?['id'] == grup['id'],
                  onSelected: (_) => controller.onGrupChanged(grup),
                  selectedColor: Colors.teal.shade700,
                  labelStyle: TextStyle(
                      color: controller.grupTerpilih.value?['id'] == grup['id']
                          ? Colors.white
                          : Colors.black),
                )),
          );
        },
      ),
    );
  }

  Widget? _buildStatusUjianChip(String? status) {
    if (status == null) return null;

    Color color = Colors.grey;
    String label = status.capitalizeFirst!;
    if (status == 'diajukan') {
      color = Colors.orange;
      label = "Diajukan";
    } else if (status == 'dijadwalkan') {
      color = Colors.teal;
      label = "Terjadwal";
    }

    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../models/santri_halaqah_laporan_model.dart';
// import '../controllers/laporan_halaqah_controller.dart';

// class LaporanHalaqahView extends GetView<LaporanHalaqahController> {
//   const LaporanHalaqahView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Laporan Halaqah (Pantau)")),
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (controller.daftarGrup.isEmpty) {
//           return const Center(child: Text("Belum ada grup Halaqah yang dibentuk."));
//         }
//         return Column(
//           children: [
//             _buildGroupSelector(),
//             _buildInfoKontekstual(),
//             Expanded(child: _buildDetailContent()),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _buildGroupSelector() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
//       color: Colors.white,
//       height: 60,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: controller.daftarGrup.length,
//         itemBuilder: (context, index) {
//           final grup = controller.daftarGrup[index];
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4.0),
//             child: Obx(() => ChoiceChip(
//                   label: Text(grup['namaGrup']),
//                   selected: controller.grupTerpilih.value?['id'] == grup['id'],
//                   onSelected: (_) => controller.onGrupChanged(grup),
//                   selectedColor: Colors.teal.shade700,
//                   labelStyle: TextStyle(
//                       color: controller.grupTerpilih.value?['id'] == grup['id']
//                           ? Colors.white
//                           : Colors.black),
//                 )),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildInfoKontekstual() {
//     return Obx(() {
//       if (controller.grupTerpilih.value == null) return const SizedBox.shrink();
//       return Card(
//         margin: const EdgeInsets.all(16),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _infoItem("Pengampu", controller.infoPengampu.value),
//               _infoItem("Jumlah Santri", "${controller.santriDiGrup.length} Santri"),
//               _infoItem("Total Setoran Bulan Ini", controller.totalSetoranGrupBulanIni.value.toString()),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   Widget _infoItem(String label, String value) {
//     return Column(
//       children: [
//         Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
//         const SizedBox(height: 4),
//         Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//       ],
//     );
//   }

//   Widget _buildDetailContent() {
//     return Obx(() {
//       if (controller.grupTerpilih.value == null) {
//         return const Center(child: Text("Silakan pilih grup untuk melihat laporan."));
//       }
//       if (controller.isDetailLoading.value) {
//         return const Center(child: CircularProgressIndicator());
//       }
//       return Column(
//         children: [
//           TabBar(
//             controller: controller.tabController,
//             labelColor: Colors.teal,
//             unselectedLabelColor: Colors.grey,
//             tabs: const [
//               Tab(text: "Progres Santri"),
//               Tab(text: "Statistik Grup"),
//             ],
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: controller.tabController,
//               children: [
//                 _buildProgresSantriTab(),
//                 const Center(child: Text("Fitur Statistik Grup akan dikembangkan.")),
//               ],
//             ),
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildProgresSantriTab() {
//     if (controller.santriDiGrup.isEmpty) {
//       return const Center(child: Text("Belum ada santri di grup ini."));
//     }
//     return ListView.builder(
//       itemCount: controller.santriDiGrup.length,
//       itemBuilder: (context, index) {
//         final santri = controller.santriDiGrup[index];
//         return ListTile(
//           leading: CircleAvatar(child: Text("${index + 1}")),
//           title: Text(santri.nama),
//           subtitle: Text("Setoran terakhir: ${santri.setoranTerakhir}"),
//           trailing: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text("${santri.totalSetoranBulanIni}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//               const Text("Setoran", style: TextStyle(fontSize: 10, color: Colors.grey)),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }