import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

class DaftarSiswaPermapelController extends GetxController {
  final Map<String, dynamic> dataArgumen = Get.arguments; 

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = "P9984539";
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  String? _idTahunAjaranCache;
  String? idTahunAjaran;

  @override
  void onInit() async {
    super.onInit();
    String tahunajaranya = await getTahunAjaranTerakhir();
    idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    update();
  }

  void clearForm() {
    // tanggapankepalasekolahC.clear();
    // selectedDropdownItem.value = null; // Reset dropdown
    // Tambahkan pembersihan untuk widget lain di sini jika ada
    // print("Form dibersihkan!");
  }

  @override
  void onClose() {
    // Penting untuk dispose controller ketika GetX controller ditutup
    // tanggapankepalasekolahC.dispose();
    super.onClose();
  }

  // Helper untuk mendapatkan idTahunAjaran yang sudah diformat
  Future<String> getFormattedIdTahunAjaran() async {
    if (_idTahunAjaranCache != null) return _idTahunAjaranCache!;
    String tahunajaranya = await getTahunAjaranTerakhir();
    _idTahunAjaranCache = tahunajaranya.replaceAll("/", "-");
    return _idTahunAjaranCache!;
  }

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


  Future<String> getSemesterTerakhir() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    CollectionReference<Map<String, dynamic>> colSemester = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('semester');
    QuerySnapshot<Map<String, dynamic>> snapshotSemester =
        await colSemester.get();
    List<Map<String, dynamic>> listSemester =
        snapshotSemester.docs.map((e) => e.data()).toList();
    String semesterTerakhir =
        listSemester.map((e) => e['namasemester']).toList().last;
    return semesterTerakhir;
  }
 

 Future<QuerySnapshot<Map<String, dynamic>>> getDataSiswa() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String idKelas = dataArgumen['idKelas'];
       
          return await firestore
              .collection('Sekolah')
              .doc(idSekolah)
              .collection('tahunajaran')
              .doc(idTahunAjaran)
              .collection('kelastahunajaran')
              .doc(idKelas)
              .collection('daftarsiswa')
              .get();
    
  }
}
