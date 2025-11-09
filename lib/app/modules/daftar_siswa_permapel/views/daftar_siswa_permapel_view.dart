// lib/app/modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart (SUDAH DIINTEGRASIKAN)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/siswa_model.dart';
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
            Text(controller.idKelas, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            tooltip: "Manajemen Tugas & Penilaian",
            onPressed: () => controller.goToManajemenTugas(),
          ),
        Obx(() {
            // Hanya tampilkan tombol ini jika pengguna adalah Wali Kelas
            if (controller.isWaliKelas.value) {
              return IconButton(
                icon: const Icon(Icons.edit_document),
                tooltip: "Tulis Catatan Rapor untuk Siswa",
                onPressed: controller.showCatatanRaporDialog,
              );
            }
            return const SizedBox.shrink(); // Sembunyikan jika bukan Wali Kelas
          }),
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
            
            // [MODIFIKASI KUNCI DI SINI]
            // Kita akan membuat ListTile dengan trailing yang dinamis
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: controller.isPengganti ? Colors.grey.shade100 : null,
              child: ListTile(
                leading: CircleAvatar(child: Text(siswa.namaLengkap[0])),
                title: Text(siswa.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("NISN: ${siswa.nisn}"),
                
                // --- Logika Kondisional untuk Aksi ---
                onTap: controller.isPengganti ? null : () {
                  // Jika BUKAN wali kelas, onTap langsung ke input nilai
                  if (!controller.isWaliKelas.value) {
                    controller.goToInputNilaiSiswa(siswa);
                  }
                  // Jika wali kelas, onTap tidak melakukan apa-apa karena aksi ada di menu
                },
                trailing: controller.isPengganti 
                  ? null // Tidak ada aksi untuk guru pengganti
                  : Obx(() {
                      // Jika pengguna adalah WALI KELAS, tampilkan menu
                      if (controller.isWaliKelas.value) {
                        return _buildWaliKelasMenu(siswa);
                      }
                      // Jika BUKAN wali kelas, tampilkan ikon panah biasa
                      return const Icon(Icons.chevron_right);
                    }),
              ),
            );
          },
        );
      }),
    );
  }

  // [BARU] Widget pembantu untuk membuat PopupMenuButton khusus Wali Kelas
  Widget _buildWaliKelasMenu(SiswaModel siswa) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'input_nilai') {
          controller.goToInputNilaiSiswa(siswa);
        } else if (value == 'lihat_rapor') {
          controller.goToRaporSiswa(siswa);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'input_nilai',
          child: ListTile(
            leading: Icon(Icons.edit_note_rounded),
            title: Text('Input Nilai Mapel'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'lihat_rapor',
          child: ListTile(
            leading: Icon(Icons.receipt_long_rounded),
            title: Text('Lihat Rapor Digital'),
          ),
        ),
      ],
    );
  }
}

// // lib/app/modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/daftar_siswa_permapel_controller.dart';

// class DaftarSiswaPermapelView extends GetView<DaftarSiswaPermapelController> {
//   const DaftarSiswaPermapelView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           children: [
//             Text(controller.namaMapel, style: const TextStyle(fontSize: 18)),
//             Text(controller.idKelas, style: const TextStyle(fontSize: 14, color: Colors.grey)),
//           ],
//         ),
//         centerTitle: true,
//         actions: [
//           // [PERBAIKAN UI/UX] Ganti PopupMenu dengan IconButton yang lebih jelas
//           IconButton(
//             icon: const Icon(Icons.assignment_turned_in_outlined),
//             tooltip: "Manajemen Tugas & Penilaian",
//             onPressed: () => controller.goToManajemenTugas(),
//           ),
//         ],
//       ),
//       body: Obx(() {
//         if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
//         if (controller.daftarSiswa.isEmpty) return const Center(child: Text("Belum ada siswa di kelas ini."));
//         return ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: controller.daftarSiswa.length,
//           itemBuilder: (context, index) {
//             final siswa = controller.daftarSiswa[index];
//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               color: controller.isPengganti ? Colors.grey.shade100 : null,
//               child: ListTile(
//                 leading: CircleAvatar(child: Text(siswa.namaLengkap[0])),
//                 title: Text(siswa.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: Text("NISN: ${siswa.nisn}"),
//                 trailing: controller.isPengganti ? null : const Icon(Icons.chevron_right),
//                 onTap: controller.isPengganti ? null : () => controller.goToInputNilaiSiswa(siswa),
//               ),
//             );
//           },
//         );
//       }),
//     );
//   }
// }