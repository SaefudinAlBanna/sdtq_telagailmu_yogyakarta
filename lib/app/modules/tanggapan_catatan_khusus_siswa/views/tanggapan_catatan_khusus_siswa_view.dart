import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/tanggapan_catatan_khusus_siswa_controller.dart';

class TanggapanCatatanKhususSiswaView
    extends GetView<TanggapanCatatanKhususSiswaController> {
  TanggapanCatatanKhususSiswaView({super.key});

  final dataArgumen = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Khusus Siswa'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.getDataSiswa(),
        builder: (context, snapsiswa) {
          if (snapsiswa.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapsiswa.data == null || snapsiswa.data!.docs.isEmpty) {
            print("snapsiswa.lenght = ${snapsiswa.data!.docs.length}");
            return Center(child: Text("Siswa tidak ada"));
          }
          if (snapsiswa.hasData) {
            var datasiswa = snapsiswa.data!.docs;
            return ListView(
              children: [
                // ElevatedButton(onPressed: (){controller.test();}, child: Text("test")),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text("wali kelas : ${datasiswa[0]['walikelas']}"),
                ),
                SizedBox(height: 25),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapsiswa.data!.docs.length,
                  itemBuilder: (context, index) {
                    print("OOOOsnapsiswa.data!.docs = ${snapsiswa.data!.docs.first.data()}");
                    return InkWell(
                      onTap: () {
                        Get.bottomSheet(
                          ListView(
                            children: [
                              Container(
                                width: Get.width,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 30,
                                ),
                                color: Colors.white,
                                child: StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>
                                >(
                                  stream: controller.getDataSiswa(),
                                  builder: (context, snapshotsiswa) {
                                    if (snapshotsiswa.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }
                                    // ignore: prefer_is_empty
                                    if (snapshotsiswa.data?.docs.length == 0 ||
                                        snapshotsiswa.data == null) {
                                      return Center(
                                        child: Text(
                                          'Tidak ada siswa yang terpilih',
                                        ),
                                      );
                                    } else if (snapshotsiswa.hasData) {
                                      String judulinformasi =
                                          snapshotsiswa.data!.docs[index]
                                              .data()['judulinformasi'] ??
                                          'No Judul';
                                      String informasicatatansiswa =
                                          snapshotsiswa.data!.docs[index]
                                              .data()['informasicatatansiswa'] ??
                                          'No Info';
                                      String tindakangurubk =
                                          snapshotsiswa.data!.docs[index]
                                              .data()['tindakangurubk'] ??
                                          'No Info';
                                      String tanggapankepalasekolah =
                                          snapshotsiswa.data!.docs[index]
                                              .data()['tanggapankepalasekolah'] ??
                                          'No Info';
                                      String tanggapanwalikelas =
                                          snapshotsiswa.data!.docs[index]
                                              .data()['tanggapanwalikelas'] ??
                                          'No Info';
                                      String tanggapanorangtua =
                                          snapshotsiswa.data!.docs[index]
                                              .data()['tanggapanorangtua'] ??
                                          'No Info';

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.all(10),
                                            child: Text(
                                              judulinformasi,
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.all(10),
                                            child: Text(
                                              informasicatatansiswa,
                                              // ,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text("yang sudah dilakukan guru BK"),
                                          Container(
                                            margin: EdgeInsets.all(10),
                                            child: Text(
                                              tindakangurubk,
                                              // ,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Text("Tanggapan kepala sekolah"),
                                          Container(
                                            margin: EdgeInsets.all(10),
                                            child: Builder(
                                              builder: (context) {
                                                var idkepalasekolah =
                                                    snapshotsiswa
                                                        .data!
                                                        .docs[index]
                                                        .data()['idkepalasekolah'];
                                                return Row(
                                                  children: [
                                                    Text(
                                                      tanggapankepalasekolah,
                                                      // ,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    if (controller.idUser ==
                                                        idkepalasekolah)
                                                      TextButton(
                                                        onPressed: () {
                                                          // Isi field jika ingin mengedit tanggapan yang sudah ada
                                                          // controller.tanggapanWaliKelasC.text = tanggapanwalikelas;
                                                          // Atau biarkan kosong untuk input baru

                                                           // Ambil idwalikelas dan nisnSiswa dari snapshot data
                                                          String idwalikelas = snapshotsiswa.data!.docs[index].data()['idwalikelas'] ?? '';
                                                          String idGuruBK = snapshotsiswa.data!.docs[index].data()['idpenginput'] ?? '';
                                                          String nisnSiswa = snapshotsiswa.data!.docs[index].data()['nisn'] ?? '';
                                                          String docIdCatatan = snapshotsiswa.data!.docs[index].id;

                                                          Get.defaultDialog(
                                                            onConfirm: () {
                                                              if (idwalikelas
                                                                      .isEmpty ||
                                                                  nisnSiswa
                                                                      .isEmpty) {
                                                                Get.snackbar(
                                                                  "Error",
                                                                  "Data Walikelas atau Siswa tidak lengkap pada catatan ini.",
                                                                );
                                                                return;
                                                              }

                                                              // dataId adalah docIdCatatan yang sudah diambil di atas atau dari:
                                                              // String dataIdFromSnapshot = snapshotsiswa.data!.docs[index]['docId'];

                                                              controller.updateTanggapanKepalaSekolah(
                                                                docIdCatatan, // atau dataIdFromSnapshot jika Anda yakin field 'docId' selalu benar
                                                                idwalikelas,
                                                                idGuruBK,
                                                                nisnSiswa, // ini yang akan jadi idSiswa
                                                                // controller.dataArgumen (idKelas) sudah ada di controller
                                                              );
                                                              // Get.back() dan clearForm() sudah dihandle di controller
                                                            },

                                                            onCancel: () {
                                                              controller
                                                                  .clearForm(); // Hanya clear text field jika cancel
                                                            },

                                                            title:
                                                                'Tanggapan Kepala Sekolah',
                                                            content: TextField(
                                                              controller:
                                                                  controller.tanggapankepalasekolahC,
                                                              decoration: InputDecoration(
                                                                hintText:
                                                                    'Judul info',
                                                                border: OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                ),
                                                                contentPadding:
                                                                    const EdgeInsets.all(
                                                                      16,
                                                                    ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Text(
                                                          "Input Tanggapan",
                                                        ),
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                          Text("Tanggapan wali kelas"),
                                          Container(
                                            margin: EdgeInsets.all(10),

                                            
                                            child: Text(
                                              tanggapanwalikelas,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Text("Tanggapan orang tua"),
                                          Container(
                                            margin: EdgeInsets.all(10),
                                            child: Text(
                                              tanggapanorangtua,
                                              // ,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Center(
                                        child: Text('No data available'),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.fromLTRB(15, 0, 15, 10),
                        // height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(datasiswa[index]['namasiswa']),
                        ),
                      ),
                    );
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
