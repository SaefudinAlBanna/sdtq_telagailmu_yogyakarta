import 'package:flutter/material.dart';
import 'package:get/get.dart';
// --- [LANGKAH 1] Tambahkan import untuk widget avatar kustom ---
import '../../../widgets/avatar_pengampu.dart'; 
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
            Text(controller.idKelas, style: const TextStyle(fontSize: 14, color: Colors.indigo)), // Warna sedikit pudar
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            tooltip: "Manajemen Tugas & Penilaian",
            onPressed: () => controller.goToManajemenTugas(),
          ),
          
          // [REVISI: MENU DROP DOWN WALI KELAS]
          Obx(() {
            if (controller.isWaliKelas.value) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert), // Titik Tiga Vertikal
                tooltip: "Menu Wali Kelas",
                onSelected: (value) {
                  switch (value) {
                    case 'ranking':
                      controller.showRankingDialog();
                      break;
                    case 'catatan':
                      controller.showCatatanRaporDialog();
                      break;
                    case 'generate':
                      controller.confirmGenerateMassal();
                      break;
                    case 'absen_manual':
                      controller.showInputAbsensiMassalDialog();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'ranking',
                    child: ListTile(
                      leading: Icon(Icons.leaderboard_rounded, color: Colors.amber),
                      title: Text('Peringkat Kelas'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'catatan',
                    child: ListTile(
                      leading: Icon(Icons.edit_note_rounded, color: Colors.blue),
                      title: Text('Catatan Rapor'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'generate',
                    child: ListTile(
                      leading: Icon(Icons.sync_rounded, color: Colors.green),
                      title: Text('Update Rapor Massal'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'absen_manual',
                    child: ListTile(
                      leading: Icon(Icons.playlist_add_check_circle_outlined, color: Colors.red),
                      title: Text('Input Absensi Dadakan'),
                      subtitle: Text("Manual S/I/A", style: TextStyle(fontSize: 10)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
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
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: controller.isPengganti ? Colors.grey.shade100 : null,
              child: ListTile(
                // --- [LANGKAH 2: MODIFIKASI KUNCI DI SINI] ---
                // Ganti CircleAvatar statis dengan widget AvatarPengampu dinamis.
                leading: AvatarPengampu(
                  imageUrl: siswa.fotoProfilUrl,
                  nama: siswa.namaLengkap,
                ),
                // --- Akhir Modifikasi ---
                title: Text(siswa.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("NISN: ${siswa.nisn ?? 'N/A'}"), // Tambahkan fallback jika nisn null
                
                // onTap: controller.isPengganti ? null : () {
                //   if (!controller.isWaliKelas.value) {
                //     controller.goToInputNilaiSiswa(siswa);
                //   }
                // },
                
                onTap: controller.isPengganti ? null : () {
                  // [MODIFIKASI] Sekarang, baik Wali Kelas maupun Guru Mapel biasa
                  // akan diarahkan ke halaman input nilai saat menekan bagian tengah ListTile.
                  controller.goToInputNilaiSiswa(siswa);
                },
                trailing: controller.isPengganti 
                  ? null
                  : Obx(() {
                      if (controller.isWaliKelas.value) {
                        return _buildWaliKelasMenu(siswa);
                      }
                      return const Icon(Icons.chevron_right);
                    }),
              ),
            );
          },
        );
      }),
    );
  }

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