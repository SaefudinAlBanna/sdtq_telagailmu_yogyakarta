// lib/app/modules/daftar_siswa/views/daftar_siswa_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daftar_siswa_controller.dart';

class DaftarSiswaView extends GetView<DaftarSiswaController> {
  const DaftarSiswaView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Siswa'),
        actions: [
          if (controller.canManageSiswa)
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Import dari Excel',
              onPressed: controller.goToImportSiswa,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchC,
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Cari nama atau NISN...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarSiswaFiltered.isEmpty) {
          return const Center(child: Text("Data siswa tidak ditemukan."));
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchSiswa(),
          child: ListView.builder(
            itemCount: controller.daftarSiswaFiltered.length,
            itemBuilder: (context, index) {
              final siswa = controller.daftarSiswaFiltered[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: siswa.fotoProfilUrl != null ? NetworkImage(siswa.fotoProfilUrl!) : null,
                    child: siswa.fotoProfilUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(siswa.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("NISN: ${siswa.nisn}"),
                  trailing: controller.canManageSiswa ? const Icon(Icons.chevron_right) : null,
                  onTap: controller.canManageSiswa ? () => controller.goToEditSiswa(siswa) : null,
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: controller.canManageSiswa
          ? FloatingActionButton(
              onPressed: controller.goToTambahSiswa,
              child: const Icon(Icons.add),
              tooltip: 'Tambah Siswa Manual',
            )
          : null,
    );
  }
}