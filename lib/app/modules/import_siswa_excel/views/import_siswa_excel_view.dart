// import_siswa_excel_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/import_siswa_excel_controller.dart';

class ImportSiswaExcelView extends GetView<ImportSiswaExcelController> {
  const ImportSiswaExcelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import & Buat Akun Siswa'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Obx(() {
            // Tampilan saat proses impor berjalan
            if (controller.isLoading.value) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    controller.progressMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Sukses: ${controller.successfulImports.value} | Gagal: ${controller.failedImports.value}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              );
            }
            // Tampilan awal sebelum impor
            else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.group_add_outlined, size: 100, color: Colors.blueGrey),
                  const SizedBox(height: 20),
                  const Text(
                    'Penting! Siapkan file Excel (.xlsx) Anda dengan urutan kolom:\n'
                    '1. NISN\n'
                    '2. Nama Lengkap\n'
                    '3. Email (unik)\n'
                    '4. Nominal SPP (hanya angka)',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.6, fontSize: 15),
                  ),
                  const SizedBox(height: 15),
                   Text(
                    'Password default untuk semua akun baru adalah:\n"${controller.defaultPassword}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Pilih File & Mulai Proses"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: controller.importAndCreateAccounts,
                  ),
                ],
              );
            }
          }),
        ),
      ),
    );
  }
}