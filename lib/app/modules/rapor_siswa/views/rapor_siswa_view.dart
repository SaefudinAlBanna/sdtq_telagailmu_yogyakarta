// lib/app/modules/rapor_siswa/views/rapor_siswa_view.dart (DRAF KODE AWAL)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Pastikan package intl sudah ada di pubspec.yaml
import '../../../models/rapor_model.dart';
import '../controllers/rapor_siswa_controller.dart';

class RaporSiswaView extends GetView<RaporSiswaController> {
  const RaporSiswaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rapor Digital Siswa'),
        // Judul akan diperbarui dengan nama siswa setelah controller siap
        // title: Text(controller.siswa.namaLengkap), 
        actions: [
          Obx(() {
            if (controller.raporData.value != null) {
              if (controller.isUpdating.value) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.teal[700])),
                );
              }
              return IconButton(
                icon: const Icon(Icons.sync_rounded),
                tooltip: "Perbarui Rapor dengan Data Terbaru",
                onPressed: controller.confirmAndUpdateRapor,
              );
            }
            return const SizedBox.shrink();
          }),
          // --- TOMBOL CETAK (PRINT) ---
          Obx(() {
            // Hanya tampilkan tombol jika rapor sudah digenerate
            if (controller.raporData.value != null) {
              // Tampilkan loading jika sedang memproses PDF
              if (controller.isPrinting.value) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)),
                );
              }
              // Tampilkan tombol cetak
              return IconButton(
                icon: const Icon(Icons.print_outlined),
                onPressed: controller.exportRaporPdf,
                tooltip: "Cetak Rapor",
              );
            }
            return const SizedBox.shrink(); // Sembunyikan jika rapor belum ada
          }),
      
          // --- TOMBOL BAGIKAN (SHARE) ---
          Obx(() {
            // Hanya tampilkan tombol jika rapor sudah digenerate
            if (controller.raporData.value != null) {
              // Tampilkan loading jika sedang memproses status share
              if (controller.isSharing.value) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)),
                );
              }
              // Tampilkan tombol share dengan status dinamis
              final isShared = controller.raporData.value!.isShared;
              return IconButton(
                icon: Icon(isShared ? Icons.share_rounded : Icons.share_outlined),
                color: isShared ? Colors.grey[700] : Colors.blue[800],
                tooltip: isShared ? "Batalkan Berbagi Rapor" : "Bagikan ke Orang Tua",
                onPressed: controller.toggleShareRapor,
              );
            }
            return const SizedBox.shrink(); // Sembunyikan jika rapor belum ada
          }),
        ],
      ),
      body: Obx(() {
        // Tampilan saat controller sedang memuat data awal (jika ada)
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Cek apakah data rapor sudah ada atau belum
        if (controller.raporData.value == null) {
          // Tampilan Awal: Tombol untuk generate rapor
          return _buildInitialState();
        } else {
          // Tampilan Hasil: Menampilkan data rapor yang sudah digenerate
          return _buildRaporDisplay(controller.raporData.value!);
        }
      }),
    );
  }

  // == WIDGET UNTUK TAMPILAN AWAL (SEBELUM GENERATE) ==
  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              "Rapor Digital untuk ${controller.siswa.namaLengkap} belum dibuat.",
              textAlign: TextAlign.center,
              style: Get.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              "Klik tombol di bawah untuk mengumpulkan semua data akademik, absensi, dan pengembangan diri siswa ke dalam satu dokumen rapor.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 32),
            Obx(() => ElevatedButton.icon(
                  onPressed: controller.isGenerating.value ? null : controller.generateRapor,
                  icon: controller.isGenerating.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.autorenew_rounded),
                  label: Text(controller.isGenerating.value ? "Memproses..." : "Generate Rapor Sekarang"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // == WIDGET UTAMA UNTUK MENAMPILKAN DATA RAPOR ==
  Widget _buildRaporDisplay(RaporModel rapor) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildHeader(rapor),
        const SizedBox(height: 16),
        _buildNilaiAkademikSection(rapor.daftarNilaiMapel),
        const SizedBox(height: 16),
        _buildPengembanganDiriSection(rapor.dataHalaqah, rapor.daftarEkskul),
        const SizedBox(height: 16),
        _buildAbsensiSection(rapor.rekapAbsensi),
        const SizedBox(height: 16),
        _buildCatatanWaliKelasSection(rapor),
      ],
    );
  }

  // -- Helper-helper untuk setiap bagian rapor --

  Widget _buildHeader(RaporModel rapor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(rapor.namaSiswa, style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text("NISN: ${rapor.nisn}"),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _headerInfo("Kelas", rapor.idKelas.split('_').first),
                _headerInfo("Semester", rapor.semester),
                _headerInfo("Tahun Ajaran", rapor.idTahunAjaran.replaceAll('-', '/')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildNilaiAkademikSection(List<NilaiMapelRapor> daftarNilai) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("A. Nilai Akademik", style: Get.textTheme.titleLarge),
            const Divider(),
            if (daftarNilai.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text("Data nilai belum tersedia.")),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daftarNilai.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final nilai = daftarNilai[index];
                  return ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(nilai.namaMapel, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text(
                      nilai.nilaiAkhir.toStringAsFixed(1),
                      style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16).copyWith(top: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Guru: ${nilai.namaGuru}", style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            const Text("Capaian Kompetensi:", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(nilai.deskripsiCapaian, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPengembanganDiriSection(DataHalaqahRapor dataHalaqah, List<DataEkskulRapor> daftarEkskul) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("B. Pengembangan Diri", style: Get.textTheme.titleLarge),
            const Divider(),
            
            // --- [MODIFIKASI TOTAL BAGIAN HALAQAH] ---
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text("Halaqah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              // Tampilkan Nilai Akhir di trailing jika ada
              trailing: dataHalaqah.nilaiAkhir != null 
                ? Chip(
                    label: Text(dataHalaqah.nilaiAkhir.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    backgroundColor: Colors.indigo,
                    avatar: const Icon(Icons.star, color: Colors.white, size: 16),
                  )
                : null,
            ),
            const SizedBox(height: 8),
            _buildHalaqahInfoRow(Icons.bookmark_border, "Tingkatan", dataHalaqah.tingkatan),
            const SizedBox(height: 8),
            _buildHalaqahInfoRow(Icons.menu_book_outlined, "Pencapaian", dataHalaqah.pencapaian),
            const SizedBox(height: 12),
            // Tampilkan Catatan Pengampu jika ada
            if(dataHalaqah.catatan.isNotEmpty && dataHalaqah.catatan != 'Belum ada catatan akhir dari pengampu.') ...[
              const Text("Catatan Pengampu:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(dataHalaqah.catatan, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ],
            // --- [AKHIR MODIFIKASI HALAQAH] ---

            const Divider(height: 24),
            const ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 4),
              title: Text("Ekstrakurikuler", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (daftarEkskul.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 8),
                child: Text("Tidak mengikuti ekstrakurikuler semester ini.", style: TextStyle(color: Colors.grey)),
              )
            else
              ...daftarEkskul.map((ekskul) => ListTile(
                    leading: const SizedBox(),
                    title: Text(ekskul.namaEkskul),
                    subtitle: Text(ekskul.catatan),
                    trailing: Text(ekskul.nilai, style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildHalaqahInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 18),
        const SizedBox(width: 12),
        Text("$label: ", style: TextStyle(color: Colors.grey.shade700)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildAbsensiSection(RekapAbsensi rekap) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("C. Ketidakhadiran", style: Get.textTheme.titleLarge),
            const Divider(),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _absenItem("Sakit", rekap.sakit),
                  const VerticalDivider(),
                  _absenItem("Izin", rekap.izin),
                  const VerticalDivider(),
                  _absenItem("Tanpa Keterangan", rekap.alpa),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _absenItem(String label, int jumlah) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(jumlah.toString(), style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCatatanWaliKelasSection(RaporModel rapor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("D. Catatan Wali Kelas", style: Get.textTheme.titleLarge),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(
                rapor.catatanWaliKelas.isEmpty ? "-" : rapor.catatanWaliKelas,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 32),
            
            // --- TANDA TANGAN UI (Segitiga Terbalik) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // KIRI: Orang Tua
                Column(
                  children: [
                    const Text("Mengetahui,"),
                    const Text("Orang Tua/Wali"),
                    const SizedBox(height: 50),
                    Text("(${rapor.namaOrangTua})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                // KANAN: Wali Kelas
                Column(
                  children: [
                    Text("Yogyakarta, ${DateFormat('dd MMM yyyy', 'id_ID').format(rapor.tanggalGenerate)}"),
                    const Text("Wali Kelas"),
                    const SizedBox(height: 50),
                    Text("(${rapor.namaWaliKelas})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40), // Jarak ke bawah
            // TENGAH BAWAH: Kepala Sekolah
            Center(
              child: Column(
                children: [
                  const Text("Mengetahui,"),
                  const Text("Kepala Sekolah"),
                  const SizedBox(height: 50),
                  // Ambil dari controller agar dinamis
                  Text("(${controller.namaKepalaSekolah.value})", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}