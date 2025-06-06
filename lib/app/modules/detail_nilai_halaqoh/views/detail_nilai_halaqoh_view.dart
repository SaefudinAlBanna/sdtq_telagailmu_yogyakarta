import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/detail_nilai_halaqoh_controller.dart';

class DetailNilaiHalaqohView extends GetView<DetailNilaiHalaqohController> {
  DetailNilaiHalaqohView({super.key});

  final dataArgumen = Get.arguments;
  @override
  Widget build(BuildContext context) {
    // print("dataArgumen= $dataArgumen");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Nilai'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Column(
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 30, bottom: 10),
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(40),
                      image: DecorationImage(
                        image: NetworkImage(
                          "https://ui-avatars.com/api/?name=${dataArgumen['namasiswa']}",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Text(dataArgumen['namasiswa']),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 10, left: 10, right: 10),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[300],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                                  // scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Ust.${dataArgumen['namapengampu']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat.yMMMEd().format(
                                          DateTime.parse(dataArgumen['tanggalinput']),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 7),
                                Divider(height: 2, color: Colors.black),
                                SizedBox(height: 7),
                                Text('Sabaq/Terbaru : ${dataArgumen['suratsabaq'] == "" ? dataArgumen['sabaq'] : dataArgumen['suratsabaq']}'),
                                SizedBox(height: 7),
                                Text('Nilai sabaq : ${dataArgumen['nilaisabaq']}'),
                                SizedBox(height: 7),
                                Text('Sabqi/Baru : ${dataArgumen['suratsabqi'] == "" ? dataArgumen['sabqi'] : dataArgumen['suratsabqi']}'),
                                SizedBox(height: 7),
                                Text('Nilai sabqi : ${dataArgumen['nilaisabqi']}'),
                                SizedBox(height: 7),
                                Text('Manzil/Lama : ${dataArgumen['suratmanzil'] == "" ? dataArgumen['manzil'] : dataArgumen['suratmanzil']}'),
                                SizedBox(height: 7),
                                Text('Nilai manzil : ${dataArgumen['nilaimanzil']}'),
                                SizedBox(height: 7),
                                Text('Tugas Tambahan : ${dataArgumen['tugastambahan'] == "" ? "" : dataArgumen['tugastambahan']}'),
                                SizedBox(height: 7),
                                Text('Nilai manzil : ${dataArgumen['nilaitugastambahan']}'),
                        SizedBox(height: 15),
                        Text(
                          'Catatan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Divider(),
                        // SizedBox(height: 3),
                        Text('pengampu : ${dataArgumen['keteranganpengampu']}'),
                        SizedBox(height: 7),
                        // Text('orangtua : ${dataArgumen['keteranganorangtua']}'),
                        // Text( "orangtua : ${dataArgumen == 0 ? (dataArgumen['keteranganorangtua'] ?? '-') : '-'}"),
                        Text(
                          'orangtua : ${dataArgumen['keteranganorangtua'] != "0" ? dataArgumen['keteranganorangtua'] : '-'}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
