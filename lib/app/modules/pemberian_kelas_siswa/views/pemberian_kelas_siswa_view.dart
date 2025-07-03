import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pemberian_kelas_siswa_controller.dart';

class PemberianKelasSiswaView extends GetView<PemberianKelasSiswaController> {
  PemberianKelasSiswaView({super.key});

  final dataKelas = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Input Siswa ke Kelas $dataKelas'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- BAGIAN 1: INFORMASI KELAS & WALI KELAS ---
          Obx(() {
            // Tampilkan loading jika data kelas sedang diambil
            if (controller.kelasInfo.value == null) {
              return Center(
                heightFactor: 5,
                child: CircularProgressIndicator(),
              );
            }
            // Jika sudah ada, tampilkan kartunya
            return _buildWaliKelasSection(context, controller.kelasInfo.value!);
          }),

          Divider(height: 30, thickness: 1.5),

          // --- BAGIAN 2: DAFTAR SISWA ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "2. Pilih Siswa untuk Ditambahkan",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              // --- LOGIKA BARU: Cek apakah stream sudah dibuat ---
              if (controller.tampilkanSiswa.value == null) {
                // Jika stream masih null, berarti wali kelas belum dipilih
                return _buildDisabledSiswaList();
              }
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: controller.tampilkanSiswa.value!,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  // Tambahkan pengecekan error untuk keamanan
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error: Gagal memuat data siswa."),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('Semua siswa sudah punya kelas.'),
                    );
                  }
                  final data = snapshot.data!.docs;
                  return Obx(
                    () =>
                        controller.isLoadingTambahKelas.value
                            ? Center(child: CircularProgressIndicator())
                            : ListView.builder(
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                var siswaData = data[index].data();
                                String namaSiswa =
                                    siswaData['nama'] ?? 'No Name';
                                String nisnSiswa =
                                    siswaData['nisn'] ?? 'No NISN';
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    title: Text(namaSiswa),
                                    subtitle: Text("NISN: $nisnSiswa"),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      tooltip: "Tambahkan ke kelas",
                                      onPressed: () {
                                        controller.simpanKelasBaruLagi(
                                          namaSiswa,
                                          nisnSiswa,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // WIDGET UNTUK MENAMPILKAN KONDISI WALI KELAS
  Widget _buildWaliKelasSection(BuildContext context, KelasInfo info) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "1. Tentukan Wali Kelas",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.class_outlined),
                    title: Text("Kelas yang Dituju"),
                    trailing: Text(
                      dataKelas,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_today_outlined),
                    title: Text("Tahun Ajaran"),
                    trailing: FutureBuilder<String>(
                      future: controller.getTahunAjaranTerakhir(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        return Text(
                          snapshot.data ?? '-',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  Divider(),
                  // Tampilkan widget berdasarkan info.isSet
                  info.isSet
                      ? _buildWaliKelasInfo(info.namaWaliKelas!)
                      : _buildPilihWaliKelas(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET JIKA WALI KELAS SUDAH ADA
  Widget _buildWaliKelasInfo(String namaWaliKelas) {
    return ListTile(
      leading: Icon(Icons.person_pin_rounded, color: Colors.green[700]),
      title: Text("Wali Kelas Saat Ini"),
      trailing: Text(
        namaWaliKelas,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  // WIDGET JIKA WALI KELAS BELUM ADA
  Widget _buildPilihWaliKelas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Wali kelas untuk kelas ini belum ditentukan. Silakan pilih terlebih dahulu:",
          style: TextStyle(color: Colors.orange[800]),
        ),
        SizedBox(height: 15),
        DropdownSearch<String>(
          popupProps: PopupProps.menu(
            showSearchBox: true,
            fit: FlexFit.loose,
            // onDismissed sudah tidak diperlukan lagi, HAPUS.
          ),
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              labelText: "Pilih Wali Kelas",
              border: OutlineInputBorder(),
            ),
          ),
          items: (f, cs) => controller.getDataWaliKelasBaru(),
          // Langsung panggil fungsi yang sudah diperbarui
          onChanged: (String? value) { 
            controller.onWaliKelasSelected(value);
            }
        ),
      ],
    );
  }

  // WIDGET JIKA DAFTAR SISWA NON-AKTIF
  Widget _buildDisabledSiswaList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 40, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "Pilih Wali Kelas Terlebih Dahulu",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
