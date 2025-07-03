import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../models/siswa_halaqoh.dart';
import '../controllers/daftar_halaqohnya_controller.dart';
import '../../../routes/app_pages.dart'; // Jika dibutuhkan

class DaftarHalaqohnyaView extends GetView<DaftarHalaqohnyaController> {
  const DaftarHalaqohnyaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
      return Scaffold(
            appBar: AppBar(
              // Foto pengampu di samping judul
              title: Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    // Tampilkan foto pengampu, jika tidak ada tampilkan inisial
                    backgroundImage: controller.urlFotoPengampu.value != null
                        ? NetworkImage(controller.urlFotoPengampu.value!)
                        : null,
                    child: controller.urlFotoPengampu.value == null
                        ? Text(controller.namaPengampu.value.isNotEmpty ? controller.namaPengampu.value[0] : 'P')
                        : null,
                  ),
                  const SizedBox(width: 12),
            Text(controller.namaPengampu.value),
          ],
          
        )),
        centerTitle: true,
        actions: [
          IconButton(
          tooltip: 'Riwayat Pindah Halaqoh',
          icon: const Icon(Icons.history_rounded),
          onPressed: _showRiwayatPindahDialog, // Panggil dialog riwayat
        ),
        IconButton(
          tooltip: 'Update Al-Husna Massal',
          icon: const Icon(Icons.edit_note_rounded),
          onPressed: _showBulkUpdateDialog,
        ),
          IconButton(
            tooltip: 'Tambah Siswa',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: _showPilihKelasDialog, // Panggil dialog pertama
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarSiswa.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      "Belum Ada Siswa",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Kelompok ini masih kosong. Tambahkan siswa pertama Anda untuk memulai.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text("Tambah Siswa"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _showPilihKelasDialog, // Langsung panggil aksi
                    ),
                  ],
                ),
              ),
            );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: controller.daftarSiswa.length,
          itemBuilder: (context, index) {
            final siswa = controller.daftarSiswa[index];
            return _buildSiswaCard(siswa);
          },
        );
      }),
    );
  }

  void _showRiwayatPindahDialog() {
  Get.dialog(
    AlertDialog(
      title: const Text("Riwayat Pindah Halaqoh"),
      content: SizedBox(
        width: double.maxFinite,
        height: Get.height * 0.6,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: controller.getRiwayatPindah(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Tidak ada riwayat perpindahan."));
            }

            final riwayatList = snapshot.data!;
            return ListView.builder(
              itemCount: riwayatList.length,
              itemBuilder: (context, index) {
                final riwayat = riwayatList[index];
                
                // Cek apakah siswa ini keluar atau masuk
                final bool isKeluar = riwayat['dariPengampu'] == controller.namaPengampu.value;
                final Timestamp timestamp = riwayat['tanggalPindah'] ?? Timestamp.now();
                final date = timestamp.toDate();
                // Format tanggal sederhana, bisa lebih bagus dengan package 'intl'
                final formattedDate = "${date.day}/${date.month}/${date.year}";

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: isKeluar ? Colors.red.shade50 : Colors.green.shade50,
                  child: ListTile(
                    leading: Icon(
                      isKeluar ? Icons.arrow_circle_up_rounded : Icons.arrow_circle_down_rounded,
                      color: isKeluar ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                    title: Text(riwayat['namaSiswa'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isKeluar
                          ? "Pindah ke: ${riwayat['kePengampu']}"
                          : "Pindah dari: ${riwayat['dariPengampu']}"),
                        if (riwayat['alasan'] != 'Tidak ada alasan')
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text("Alasan: ${riwayat['alasan']}", style: const TextStyle(fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                    trailing: Text(formattedDate),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Tutup"),
        )
      ],
    ),
  );
}

  // 2. Tambahkan FUNGSI DIALOG BARU di dalam class View
void _showBulkUpdateDialog() {
  // Pastikan daftar pilihan kosong sebelum dialog dibuka
  controller.siswaTerpilihUntukUpdateMassal.clear(); 
  controller.bulkUpdateAlhusnaC.clear();

  Get.defaultDialog(
    title: "Update Al-Husna Massal",
    content: SizedBox(
      width: Get.width,
      height: Get.height * 0.5, // Beri batasan tinggi
      child: Column(
        children: [
          // Dropdown untuk memilih level Al-Husna
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: DropdownSearch<String>(
              popupProps: const PopupProps.menu(showSearchBox: true, fit: FlexFit.loose),
              items: (f, cs) => controller.listLevelAlhusna,
              onChanged: (value) => controller.bulkUpdateAlhusnaC.text = value ?? '',
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: "Pilih Level Al-Husna Tujuan",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const Divider(),
          // Daftar siswa dengan checkbox
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.daftarSiswa.length,
              itemBuilder: (context, index) {
                final siswa = controller.daftarSiswa[index];
                return Obx(() => CheckboxListTile(
                  title: Text(siswa.nama),
                  subtitle: Text("Level saat ini: ${siswa.alhusna}"),
                  value: controller.siswaTerpilihUntukUpdateMassal.contains(siswa.nisn),
                  onChanged: (isSelected) {
                    if (isSelected == true) {
                      controller.siswaTerpilihUntukUpdateMassal.add(siswa.nisn);
                    } else {
                      controller.siswaTerpilihUntukUpdateMassal.remove(siswa.nisn);
                    }
                  },
                ));
              },
            )),
          ),
        ],
      ),
    ),
    confirm: Obx(() => ElevatedButton(
      onPressed: controller.isDialogLoading.value 
        ? null 
        : () => controller.updateAlHusnaMassal(),
      child: controller.isDialogLoading.value
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text("Simpan Perubahan"),
    )),
    cancel: TextButton(
      onPressed: () => Get.back(),
      child: const Text("Batal"),
    ),
  );
}

    /// Membangun Card Siswa yang sudah dipercantik
  Widget _buildSiswaCard(SiswaHalaqoh siswa) {
    return Material(
      child: InkWell(
        onTap: () {Get.toNamed(Routes.DAFTAR_NILAI, arguments: siswa.rawData);},
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(children: [
              // Avatar Siswa dengan Fallback
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueGrey.shade50,
                backgroundImage: siswa.profileImageUrl != null
                    ? NetworkImage(siswa.profileImageUrl!)
                    : null,
                child: siswa.profileImageUrl == null
                    ? Text(
                        siswa.nama.isNotEmpty ? siswa.nama[0] : 'S',
                        style: const TextStyle(fontSize: 26, color: Colors.blueGrey),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Informasi Siswa
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text("Kelas: ${siswa.kelas}", style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text("Al-Husna: ${siswa.alhusna}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _getAlhusnaColor(siswa.alhusna), // <-- GUNAKAN HELPER
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
              )),
              // Tombol Aksi (PopupMenu)
              PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'update') _showUpdateAlHusnaDialog(siswa);
                if (value == 'pindah') _showPindahHalaqohDialog(siswa);
                // if (value == 'nilai') {
                //   Get.toNamed(Routes.DAFTAR_NILAI, arguments: siswa.rawData);
                // }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'update', child: Text('Update Al-Husna')),
                const PopupMenuItem(value: 'pindah', child: Text('Pindah Halaqoh')),
                // const PopupMenuItem(value: 'nilai', child: Text('Input Nilai')),
              ],
            ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Dialog untuk mengupdate Al-Husna
  void _showUpdateAlHusnaDialog(SiswaHalaqoh siswa) {
    controller.alhusnaC.text = siswa.alhusna; // Set nilai awal
    Get.defaultDialog(
      title: "Update Al-Husna",
      content: Column(
        children: [
          Text(siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Anda bisa ganti DropdownSearch dengan DropdownButton biasa jika list-nya statis
          // TextField(
          //   controller: controller.alhusnaC,
          //   decoration: const InputDecoration(labelText: "Level Al-Husna"),
          // ),
           DropdownSearch<String>(
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            fit: FlexFit.loose, // Agar menu tidak terlalu besar
          ),
          items: (f, cs) => controller.listLevelAlhusna,
          selectedItem: controller.alhusnaC.text, // Tampilkan nilai yang sudah ada
          onChanged: (value) {
            controller.alhusnaC.text = value ?? ''; // Update controller saat dipilih
          },
          decoratorProps: const DropDownDecoratorProps(
            decoration: InputDecoration(
              labelText: "Level Al-Husna",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ],
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isDialogLoading.value 
          ? null 
          : () => controller.updateAlHusna(siswa.nisn),
        child: controller.isDialogLoading.value
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text("Simpan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }
  
  /// Dialog untuk memindahkan siswa
  void _showPindahHalaqohDialog(SiswaHalaqoh siswa) {
    Get.defaultDialog(
      title: "Pindah Halaqoh",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Pindahkan ${siswa.nama} ke kelompok:", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Dropdown untuk memilih pengampu tujuan
          FutureBuilder<List<String>>(
            future: controller.getTargetPengampu(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return DropdownSearch<String>(
                popupProps: const PopupProps.menu(showSearchBox: true),
                items: (f, cs) => snapshot.data ?? [],
                onChanged: (value) => controller.pengampuPindahC.text = value ?? '',
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(labelText: "Pengampu Tujuan"),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.alasanPindahC,
            decoration: const InputDecoration(labelText: "Alasan Pindah"),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
         // Panggil fungsi yang sudah dibuat di controller
          controller.pindahkanSiswa(siswa); 
        },
        child: const Text("Pindahkan"),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  /// Dialog 1: Memilih Kelas
  void _showPilihKelasDialog() {
    Get.defaultDialog(
      title: "Pilih Kelas",
      content: FutureBuilder<List<String>>(
        future: controller.getKelasTersedia(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          if (snapshot.data!.isEmpty) return const Text("Tidak ada kelas yang tersedia.");
          return SizedBox(
            width: Get.width * 0.7,
            height: Get.height * 0.3,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                String namaKelas = snapshot.data![index];
                return ListTile(
                  title: Text(namaKelas),
                  onTap: () {
                    Get.back(); // Tutup dialog pilih kelas
                    _showPilihSiswaBottomSheet(namaKelas); // Buka bottom sheet siswa
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Dialog 2: Memilih Siswa dari Kelas yang Dipilih
  void _showPilihSiswaBottomSheet(String namaKelas) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Text("Siswa dari Kelas $namaKelas", style: Get.textTheme.titleLarge),
          const Divider(),
          Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: controller.getSiswaBaruStream(namaKelas),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Semua siswa di kelas ini sudah memiliki kelompok."));
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var dataSiswa = snapshot.data!.docs[index].data();
                  return ListTile(
                    title: Text(dataSiswa['namasiswa']),
                    subtitle: Text("NISN: ${dataSiswa['nisn']}"),
                    trailing: Obx(() => controller.isDialogLoading.value 
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => controller.tambahSiswaKeHalaqoh(dataSiswa),
                        )),
                  );
                },
              );
            },
          )),
        ]),
      ),
      isScrollControlled: true,
    );
  }
}

Color _getAlhusnaColor(String level) {
  if (level.toLowerCase().contains('al-husna')) {
    return Colors.green.shade400;
  }
  if (level.toLowerCase().contains('juz 30')) {
    return Colors.blue.shade400;
  }
  if (level.toLowerCase().contains('juz 1')) {
    return Colors.purple.shade400;
  }
  if (level.toLowerCase().startsWith('juz')) {
    return Colors.orange.shade400;
  }
  return Colors.grey.shade400;
}
