import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pemberian_guru_mapel_controller.dart';

class PemberianGuruMapelView extends GetView<PemberianGuruMapelController> {
  const PemberianGuruMapelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atur Guru Mapel Kelas ${controller.namaKelas}'),
        backgroundColor: Colors.indigo,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: controller.getAssignedMapelStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Buat map untuk memudahkan pencarian guru yang sudah ditugaskan
            final assignedMapelData = {
              for (var doc in snapshot.data?.docs ?? [])
                doc.data()['namamatapelajaran']: doc.data()['guru']
            };

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: controller.daftarMapel.length,
              itemBuilder: (context, index) {
                final mapel = controller.daftarMapel[index];
                final namaMapel = mapel['namamatapelajaran'] as String;
                final guruDitugaskan = assignedMapelData[namaMapel];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 2.0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: guruDitugaskan != null
                        ? Text('Guru: $guruDitugaskan', style: TextStyle(color: Colors.indigo[800]))
                        : const Text('Belum ada guru', style: TextStyle(fontStyle: FontStyle.italic)),
                    trailing: guruDitugaskan != null
                        ? IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                            tooltip: 'Hapus Guru',
                            onPressed: () => _showConfirmationDialog(
                              context,
                              title: 'Hapus Guru',
                              content: 'Anda yakin ingin menghapus guru dari mapel $namaMapel?',
                              onConfirm: () => controller.removeGuruFromMapel(namaMapel),
                            ),
                          )
                        : ElevatedButton(
                            child: const Text('Pilih Guru'),
                            onPressed: () => _showGuruSelectionDialog(context, namaMapel),
                          ),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }

  void _showGuruSelectionDialog(BuildContext context, String namaMapel) {
    Get.defaultDialog(
      title: 'Pilih Guru untuk $namaMapel',
      content: Container(
        width: Get.width * 0.8,
        height: 100, // Beri tinggi agar tidak overflow
        child: DropdownSearch<Map<String, String>>(
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                labelText: 'Cari Guru',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          items: (f, cs) => controller.daftarGuru,
          itemAsString: (guru) => guru['nama'] ?? '',
          compareFn: (item, selectedItem) => item['uid'] == selectedItem['uid'],
          decoratorProps: const DropDownDecoratorProps(
            decoration: InputDecoration(
              labelText: "Pilih Guru",
              border: OutlineInputBorder(),
            ),
          ),
          onChanged: (Map<String, String>? selectedGuru) {
            if (selectedGuru != null) {
              Get.back(); // Tutup dialog pilih guru
              Future.delayed(const Duration(seconds: 1), () {
              _showConfirmationDialog(
                context,
                title: 'Konfirmasi',
                content: 'Tugaskan ${selectedGuru['nama']} ke mapel $namaMapel?',
                onConfirm: () => controller.assignGuruToMapel(
                  selectedGuru['uid']!,
                  selectedGuru['nama']!,
                  namaMapel,
                ),
              );
              });
            }
          },
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    Get.defaultDialog(
      title: title,
      middleText: content,
      textConfirm: 'Ya',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back(); // Tutup dialog konfirmasi
        onConfirm();
      },
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';

// import 'package:get/get.dart';

// import '../controllers/pemberian_guru_mapel_controller.dart';

// class PemberianGuruMapelView extends GetView<PemberianGuruMapelController> {
//   PemberianGuruMapelView({super.key});

//   final dataKelas = Get.arguments;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(130),
//         child: AppBar(
//           backgroundColor: Colors.indigo,
//           title: Text('Pemberian Guru Mapel $dataKelas'),
//           centerTitle: true,
//           flexibleSpace: Padding(
//             padding: const EdgeInsets.fromLTRB(30, 50, 20, 5),
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: DropdownSearch<String>(
//                 decoratorProps: DropDownDecoratorProps(
//                   decoration: InputDecoration(
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(50),
//                       borderSide: BorderSide(color: Colors.white, width: 1),
//                     ),
//                     filled: true,
//                     prefixText: 'Guru Mapel : ',
//                     // labelText: 'Guru Mapel',
//                     hintText: 'Guru Mapel',
//                     labelStyle: TextStyle(fontSize: 15),
//                     hintStyle: TextStyle(fontSize: 15, color: Colors.grey),

//                     // prefixStyle: TextStyle(fontSize: 15),
//                     // suffixStyle: TextStyle(fontSize: 15),
//                     // suffixText: 'Saya',
//                     // suffixStyle: TextStyle(fontSize: 15),
//                     suffixIcon: Icon(Icons.person),
//                     // suffixIconColor: Colors.blue,
//                     // suffixIconSize: 20,
//                     // suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
//                     // suffixIcon: Icon(Icons.person),
//                     // suffixIconColor: Colors.blue,
//                     // suffixIconSize: 20,
//                     // suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
//                     // suffixIcon: Icon(Icons.person),
//                     // suffixIconColor: Colors.blue,
//                   ),
//                 ),
//                 // selectedItem: controller.kelasSiswaC.text,
//                 selectedItem: controller.guruMapelC.text,
//                 items: (f, cs) => controller.getDataGuruMapel(),
//                 onChanged: (String? value) {
//                   controller.guruMapelC.text = value!;
//                 },
//                 popupProps: PopupProps.menu(
//                   // disabledItemFn: (item) => item == '1A',
//                   fit: FlexFit.tight,
//                 ),
//               ),
//             ),
//           ), // Default return statement
//           // },
//           // ),
//         ),
//       ),

//       body: Column(
//         children: [
//           FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
//             future: controller.tampilkanMapel(),
//             builder: (context, snapTampilMapel) {
//               return ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: snapTampilMapel.data?.docs.length ?? 0,
//                 itemBuilder: (context, index) {
//                   if (snapTampilMapel.connectionState ==
//                       ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   }
//                   if (snapTampilMapel.hasData) {
//                     var data = snapTampilMapel.data!.docs[index].data();
//                     // return ListTile(
//                     //   onTap: () {
//                     //     print("yang ke ${index + 1}");
//                     //   },
//                     //   title: Text(data['namamatapelajaran']),
//                     //   subtitle: Text(dataKelas),
//                     // );

//                     return Padding(
//                       padding: const EdgeInsets.only(top: 10),
//                       child: Material(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(15),
//                         child: InkWell(
//                           onTap: () {
//                             if (controller.guruMapelC.text.isEmpty) {
//                               Get.snackbar(
//                                 "Error",
//                                 "Guru Mapel tidak boleh kosong",
//                               );
//                             } else {
//                               controller.simpanMapel(data['namamatapelajaran']);
//                               controller.tampilkan();
//                             }
//                           },
//                           child: Container(
//                             margin: EdgeInsets.fromLTRB(20, 10, 10, 0),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(data['namamatapelajaran']),
//                                 SizedBox(height: 3),
//                                 Text(dataKelas),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }
//                   // Add a default return for other cases
//                   return Text("Tidak bisa memuat data, silahkan ulangi lagi");
//                 },
//               );
//             },
//           ),
//           // Divider(height: 3),
//           Container(height: 2, color: Colors.grey),
//           // ElevatedButton(onPressed: ()=>controller.refreshTampilan(), child: Text("test")),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//               stream: controller.tampilkan(),
//               builder: (context, snapshotTampil) {
//                 if (snapshotTampil.connectionState == ConnectionState.waiting) {
//                   return Center(child: CircularProgressIndicator());
//                 }
//                 // ignore: prefer_is_empty
//                 if (snapshotTampil.data == null ||
//                     snapshotTampil.data?.docs.length == 0) {
//                   return Center(child: Text('belum ada data'));
//                 }
//                 return ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: snapshotTampil.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     Map<String, dynamic> data =
//                         snapshotTampil.data!.docs[index].data() as Map<String, dynamic>;
//                     return ListTile(
//                       title: Text(data['namamatapelajaran']),
//                       subtitle: Text("subtitle mapel"),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
