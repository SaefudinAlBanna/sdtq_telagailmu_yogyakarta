// lib/app/modules/catatan_siswa/views/catatan_siswa_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/catatan_siswa_controller.dart';

class CatatanSiswaView extends GetView<CatatanSiswaController> {
  const CatatanSiswaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catatan Perkembangan Siswa"),
        actions: [
          Obx(() {
            if (controller.isWaliKelas.value) {
              return IconButton(
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: "Tambah Catatan Baru",
                onPressed: controller.openAddCatatanDialog,
              );
            }
            return const SizedBox.shrink();
          })
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.userRole.value != 'Wali Kelas' &&
            controller.userRole.value != 'Guru BK' &&
            controller.userRole.value != 'Kepala Sekolah') {
          return const Center(child: Text("Anda tidak memiliki hak akses untuk melihat halaman ini."));
        }
        return Column(
          children: [
            _buildSelectionUI(),
            Expanded(
              child: Obx(() {
                if (controller.selectedSiswaId.value.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          "Pilih siswa untuk melihat catatan.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: controller.streamCatatanSiswa(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Belum ada catatan untuk siswa ini."));
                    }
                    final catatanList = snapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: catatanList.length,
                      itemBuilder: (context, index) {
                        final doc = catatanList[index];
                        final Map<String, dynamic> catatan = doc.data();
                        catatan['docId'] = doc.id;
                        return _CatatanCard(catatan: catatan);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSelectionUI() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Obx(() {
        if (controller.isWaliKelas.value) {
          if (controller.selectedKelasId.value.isEmpty) {
            return const Center(child: Text("Anda tidak terdaftar sebagai wali kelas manapun."));
          }
          return Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Kelas Anda",
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  child: Text(
                    controller.selectedKelasId.value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedSiswaId.value.isEmpty ? null : controller.selectedSiswaId.value,
                  hint: const Text("Pilih Siswa"),
                  onChanged: controller.onSiswaChanged,
                  items: controller.daftarSiswa.map((siswa) {
                    return DropdownMenuItem(value: siswa['id'], child: Text(siswa['nama']!));
                  }).toList(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedKelasId.value.isEmpty ? null : controller.selectedKelasId.value,
                  hint: const Text("Pilih Kelas"),
                  onChanged: (val) => controller.onKelasChanged(val),
                  items: controller.daftarKelas.map((kelas) {
                    return DropdownMenuItem(value: kelas['id'], child: Text(kelas['nama']!));
                  }).toList(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedSiswaId.value.isEmpty ? null : controller.selectedSiswaId.value,
                  hint: const Text("Pilih Siswa"),
                  onChanged: controller.onSiswaChanged,
                  items: controller.daftarSiswa.map((siswa) {
                    return DropdownMenuItem(value: siswa['id'], child: Text(siswa['nama']!));
                  }).toList(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}

class _CatatanCard extends GetView<CatatanSiswaController> {
  final Map<String, dynamic> catatan;
  const _CatatanCard({required this.catatan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String formattedDate = "Tanggal tidak valid";
    if (catatan['tanggalinput'] != null) {
      try {
        formattedDate = DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.parse(catatan['tanggalinput']));
      } catch(e) {}
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(catatan['judulinformasi'] ?? 'Tanpa Judul', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Oleh: ${catatan['namapenginput']} pada $formattedDate", style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
            const Divider(height: 24),
            
            _buildSection("Isi Catatan", catatan['informasicatatansiswa']),
            _buildSection("Tindakan Awal Wali Kelas", catatan['tindakanawalwalikelas']),
            
            const Divider(height: 24, thickness: 0.5),

            // Urutan Tanggapan Disesuaikan
            _buildTanggapanSection("Tindakan yang sudah dilakukan Wali Kelas", catatan['tanggapanwalikelas'], Colors.blue.shade50),
            _buildTanggapanSection("Tanggapan Guru BK", catatan['tanggapangurubk'], Colors.purple.shade50),
            _buildTanggapanSection("Tanggapan Kepala Sekolah", catatan['tanggapankepalasekolah'], Colors.green.shade50),
            _buildTanggapanSection("Tanggapan Orang Tua", catatan['tanggapanorangtua'], Colors.orange.shade50),
            
            const Divider(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: _buildTanggapanButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTanggapanButton() {
    // Tombol muncul jika user punya peran untuk merespon.
    // User bisa mengedit respon di field miliknya masing-masing.
    final canRespond = controller.userRole.value == 'Kepala Sekolah' || 
                       controller.userRole.value == 'Guru BK' || 
                       controller.userRole.value == 'Wali Kelas';

    if (canRespond) {
      return ElevatedButton.icon(
        onPressed: () => controller.openTanggapanDialog(catatan),
        icon: const Icon(Icons.edit_note, size: 18),
        label: const Text("Beri Tanggapan"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12),
          backgroundColor: Colors.indigo.shade400,
          foregroundColor: Colors.white,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
  
  Widget _buildTanggapanSection(String title, String? content, Color bgColor) {
    bool hasContent = content != null && content.isNotEmpty && content != "0";
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasContent ? bgColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200)
            ),
            child: Text(
              hasContent ? content : "Belum ada tanggapan.",
              style: TextStyle(
                fontStyle: hasContent ? FontStyle.normal : FontStyle.italic,
                color: hasContent ? Colors.black87 : Colors.grey.shade600
              ),
            ),
          )
        ],
      ),
    );
  }
}