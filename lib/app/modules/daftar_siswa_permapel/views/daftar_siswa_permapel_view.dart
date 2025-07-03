import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../input_nilai_siswa/bindings/input_nilai_siswa_binding.dart';
import '../../input_nilai_siswa/views/input_nilai_siswa_view.dart';
import '../../rapor_siswa/bindings/rapor_siswa_binding.dart';
import '../../rapor_siswa/views/rapor_siswa_view.dart';
import '../controllers/daftar_siswa_permapel_controller.dart';

class DaftarSiswaPermapelView extends GetView<DaftarSiswaPermapelController> {
  DaftarSiswaPermapelView({super.key});

 final Map<String, dynamic> dataArgumen = Get.arguments;

  @override
  Widget build(BuildContext context) {
    print("dataArgumen ada 2 = $dataArgumen");
    return Scaffold(
      appBar: AppBar(
        title: Text('${dataArgumen["namaMapel"]} - Kelas ${dataArgumen["idKelas"]}'),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: controller.getDataSiswa(),
        builder: (context, snapsiswa) {
          if (snapsiswa.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapsiswa.data == null) {
            return Center(child: Text("Siswa tidak ada"));
          }
          if (snapsiswa.data!.docs.isEmpty) {
            return Center(child: Text("Siswa tidak ada"));
          }
          if (snapsiswa.hasData) {
            return ListView(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapsiswa.data!.docs.length,
                  itemBuilder: (context, index) {
                    var dataSiswa = snapsiswa.data!.docs[index].data();
                    var idSiswa = snapsiswa.data!.docs[index].id;
                    // return InkWell(
                    //   onTap: () {
                    //     Get.to(
                    //       () =>  InputNilaiSiswaView(),
                    //       binding: InputNilaiSiswaBinding(),
                    //       arguments: {
                    //         'idKelas': dataArgumen['idKelas'], // misal: '1B'
                    //         'idMapel': dataArgumen['namaMapel'], // misal: 'Matematika'
                    //         'idSiswa': idSiswa, // misal: '9988'
                    //         'namaSiswa': dataSiswa['namasiswa'],
                    //       },
                    //     );
                    //   },
                    //   child: Container(
                    //     margin: EdgeInsets.fromLTRB(15, 0, 15, 8),
                    //     padding: EdgeInsets.fromLTRB(15, 3, 15, 8),
                    //     decoration: BoxDecoration(
                    //       color: Colors.green[100],
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [Text(dataSiswa['namasiswa'])],
                    //     ),
                    //   ),
                    // );

//================================= RAPOR ==========================
                    return Card(
                            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(dataSiswa['namasiswa'], style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text("NIS: ${dataSiswa['nis'] ?? '...'}"),
                                      ],
                                    ),
                                  ),
                                  // Tombol Lihat Rapor
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.assignment, color: Colors.blue),
                                        tooltip: 'Lihat nilai',
                                        onPressed: () {
                                          // Navigasi ke Halaman Rapor
                                         Get.to(
                                            () =>  InputNilaiSiswaView(),
                                            binding: InputNilaiSiswaBinding(),
                                            arguments: {
                                              'idKelas': dataArgumen['idKelas'], // misal: '1B'
                                              'idMapel': dataArgumen['namaMapel'], // misal: 'Matematika'
                                              'idSiswa': idSiswa, // misal: '9988'
                                              'namaSiswa': dataSiswa['namasiswa'],
                                            },
                                            );
                                         },
                                      ),
                                      SizedBox(width: 15),
                                      IconButton(
                                        icon: Icon(Icons.assignment_ind, color: Colors.blue),
                                        tooltip: 'Lihat Rapor',
                                        onPressed: () {
                                          // Navigasi ke Halaman Rapor
                                          Get.to(
                                            () => RaporSiswaView(), // Ganti dengan nama view rapor Anda
                                            binding: RaporSiswaBinding(), // Jika Anda membuat binding
                                            arguments: {
                                              'idSiswa': idSiswa,
                                              'namaSiswa': dataSiswa['nama'],
                                              'idKelas': dataArgumen['idKelas'], // Asumsi idKelas ada di argumen halaman ini
                                              // Kirim data lain yang mungkin dibutuhkan controller rapor
                                            }
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
// ================================================================
                  },
                ),
              ],
            );
          } else {
            return Center(
              child: Text("tidak dapat memuat data, periksa koneksi internet"),
            );
          }
        },
      ),
    );
  }
}
