import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/input_nilai_siswa_controller.dart';

// GANTI DARI GetView MENJADI StatelessWidget
class InputNilaiSiswaView extends StatelessWidget {
  const InputNilaiSiswaView({super.key});

  @override
  Widget build(BuildContext context) {
    // KITA CARI CONTROLLER SECARA MANUAL DENGAN TAG YANG BENAR
    // 1. Ambil argumen untuk mendapatkan tag-nya
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    final String uniqueTag = args['idSiswa'] + args['idMapel'];

    // 2. Gunakan Get.find() dengan tag yang sudah kita buat
    final InputNilaiSiswaController controller = Get.find<InputNilaiSiswaController>(tag: uniqueTag);

    // Dari sini ke bawah, semua kode sama seperti sebelumnya,
    // karena kita sudah punya variabel 'controller'.
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.args['namaSiswa']),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            controller.args['idMapel'],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
      body: Obx(() {
        if (!controller.isReady.value) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: controller.getDaftarNilai(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Belum ada nilai yang diinput."));
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                padding: const EdgeInsets.all(15),
                itemBuilder: (context, index) {
                  var dataNilai = snapshot.data!.docs[index].data();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: dataNilai['jenisNilai'] == 'Sumatif' ? Colors.blue[300] : Colors.green[300],
                        child: Text(dataNilai['nilai'].toString()),
                      ),
                      title: Text(dataNilai['namaPenilaian']),
                      subtitle: Text(dataNilai['deskripsi'] ?? 'Tidak ada deskripsi.'),
                    ),
                  );
                },
              );
            },
          );
        }
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showInputNilaiSheet(context, controller);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showInputNilaiSheet(BuildContext context, InputNilaiSiswaController controller) {
    Get.bottomSheet(
      FormInputNilaiSheet(controller: controller),
      isScrollControlled: true,
    );
  }
}

// Widget FormInputNilaiSheet tidak perlu diubah sama sekali
class FormInputNilaiSheet extends StatelessWidget {
  final InputNilaiSiswaController controller;
  const FormInputNilaiSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // 6. Di dalam build method ini, 'controller' merujuk ke properti class di atas.
    //    Ini adalah variabel yang sama dengan yang kita lewatkan dari halaman utama.
    //    Jadi, semua pemanggilan seperti `controller.namaPenilaianC` atau `controller.addNilai()`
    //    dijamin merujuk ke controller yang benar.
    return Container(
      // Padding bawah ditambahkan agar form tidak tertutup keyboard.
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tambah Nilai Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Obx(() => DropdownButtonFormField<String>(
              value: controller.jenisNilai.value,
              items: ["Sumatif", "Formatif"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.jenisNilai.value = newValue;
                }
              },
              decoration: const InputDecoration(
                labelText: "Jenis Penilaian",
                border: OutlineInputBorder(),
              ),
            )),
            const SizedBox(height: 15),

            TextField(
              controller: controller.namaPenilaianC,
              decoration: const InputDecoration(
                labelText: "Nama Penilaian (cth: Sumatif Bab 1)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller.nilaiC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nilai (Angka)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller.deskripsiC,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Deskripsi/Catatan (Opsional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.addNilai();
                },
                child: const Text("Simpan Nilai"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}