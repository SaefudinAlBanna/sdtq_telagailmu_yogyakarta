import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class DaftarHalaqohPengampuController extends GetxController {
  var dataHalaqoh = Get.arguments;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idSekolah = 'P9984539';
  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSemester = 'Semester I';

  Future<String> getTahunAjaranTerakhir() async {
    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
        await colTahunAjaran.get();
    List<Map<String, dynamic>> listTahunAjaran =
        snapshotTahunAjaran.docs.map((e) => e.data()).toList();
    String tahunAjaranTerakhir =
        listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
    return tahunAjaranTerakhir;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getDaftarHalaqohPengampu() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    QuerySnapshot<Map<String, dynamic>> querySnapshotPengampu =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('uid', isEqualTo: idUser)
            .get();
    if (querySnapshotPengampu.docs.isNotEmpty) {
      Map<String, dynamic> dataNama = querySnapshotPengampu.docs.last.data();
      String namaPengampu = dataNama['alias'];

      // QuerySnapshot<Map<String, dynamic>> querySnapshotTempat =
      //     await firestore
      //         .collection('Sekolah')
      //         .doc(idSekolah)
      //         .collection('tahunajaran')
      //         .doc(idTahunAjaran)
      //         // .collection('semester')
      //         // .doc(idSemester)
      //         .collection('kelompokmengaji')
      //         .doc(dataHalaqoh)
      //         .collection('pengampu')
      //         // .doc(namaPengampu)
      //         // .collection('tempat')
      //         .get();
      // if (querySnapshotTempat.docs.isNotEmpty) {
      //   Map<String, dynamic> dataTampat = querySnapshotTempat.docs.last.data();
        // String namaTempat = dataTampat['tempatmengaji'];

        return await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            // .collection('semester')
            // .doc(idSemester)
            .collection('kelompokmengaji')
            .doc(dataHalaqoh) // ini nanti diganti otomatis
            .collection('pengampu')
            .doc(namaPengampu)
            // .collection('tempat')
            // .doc(namaTempat)
            .collection('daftarsiswa')
            .get();
      // }
    }
    throw Exception('No data found for daftar halaqoh');
  }

  // Future<QuerySnapshot<Map<String, dynamic>>> getDataUmi() async {
  //   QuerySnapshot<Map<String, dynamic>> dataUmi =
  //       await getDaftarHalaqohPengampu();
  //   if (dataUmi.docs.isNotEmpty) {
  //     print(dataUmi.docs.length);
  //     // Map<String..dynamic>
  //     // dataNama = dataUmi.docs.last.data();
  //     // String namaPengampu = dataNama['alias'];
  //     // QuerySnapshot<Map
  //     // ..dynamic>
  //     // querySnapshotTempat = await firestore
  //     // .collection('Sekolah')
  //     // .doc(idSekolah)
  //     // .collection('tahunajaran')
  //     // .doc(idTahunAjaran)
  //     // // .collection('semester')
  //     // // .doc(idSemester)
  //     // .collection('kelompokmengaji')
  //     // .doc(dataNama['idhalaqoh'])
  //     // .collection('pengampu')
  //     // .doc(namaPengampu)
  //     // .collection('tempat')
  //     // .get();
  //     // if (querySnapshotTempat.docs.isNotEmpty) {
  //     //   Map<String
  //     //   ..dynamic>
  //     //   dataTampat = querySnapshotTempat.docs.last.data();
  //     //   String namaTempat = dataTampat['tempatmengaji'];
  //     //   return await firestore
  //     //   .collection('Sekolah')
  //     //   .doc(idSekolah)
  //     //   .collection('tahunajaran')
  //     //   .doc(idTahunAjaran)
  //     //   // .collection('semester')
  //     //   // .doc(idSemester)
  //     //   .collection('kelompokmengaji')
  //     //   .doc(dataNama['idhalaqoh'])
  //     //   .collection('pengampu')
  //     //   .doc(namaPengampu)
  //     //   .collection('tempat')
  //     //   .doc(namaTempat)
  //     //   .collection('daftarsiswa')
  //     //   .get();
  //     //   } else {
  //     //     throw Exception('No data found for daftar siswa');
  //     //     }
  //     //     } else {
  //     //       throw Exception('No data found for daftar pengampu');
  //     //       }
  //   }
  //     return dataUmi;
  // }
}
