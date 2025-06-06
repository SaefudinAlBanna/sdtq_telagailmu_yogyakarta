//lib/app/modules/tambah_pegawai/controllers/tambah_pegawai_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
// import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi lokal

class TambahPegawaiController extends GetxController {

  RxString jenisKelamin = "".obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingTambahPegawai = false.obs;
   
   // Kunci Global untuk Form
  final formKey = GlobalKey<FormState>();

  // TextEditingControllers untuk setiap field
  late TextEditingController namaC;
  late TextEditingController nipC;
  late TextEditingController jabatanC;
  late TextEditingController emailC;
  late TextEditingController teleponC;
  late TextEditingController alamatC;
  late TextEditingController passAdminC;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idSekolah = "P9984539";

   // Untuk tanggal bergabung (opsional)
  final Rx<DateTime?> tanggalBergabung = Rx<DateTime?>(null);
  late TextEditingController tanggalBergabungC;


@override
  void onInit() {
    super.onInit();
    // Inisialisasi lokal untuk format tanggal Indonesia
    // initializeDateFormatting('id_ID', null);

    namaC = TextEditingController();
    nipC = TextEditingController();
    jabatanC = TextEditingController();
    emailC = TextEditingController();
    teleponC = TextEditingController();
    alamatC = TextEditingController();
    tanggalBergabungC = TextEditingController();
    passAdminC = TextEditingController();
  }

   onChangeJenisKelamin(String nilai) {
    jenisKelamin.value = nilai;
  }



  @override
  void onClose() {
    namaC.dispose();
    nipC.dispose();
    jabatanC.dispose();
    emailC.dispose();
    teleponC.dispose();
    alamatC.dispose();
    tanggalBergabungC.dispose();
    super.onClose();
  }

  // Fungsi untuk memilih tanggal
  // Future<void> pilihTanggalBergabung(BuildContext context) async {
  //   final DateTime? pickedDate = await showDatePicker(
  //     context: context,
  //     initialDate: tanggalBergabung.value ?? DateTime.now(),
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime(2101),
  //     // locale: const Locale('id', 'ID'), // Set locale ke Indonesia
  //   );
  //   if (pickedDate != null) {
  //     tanggalBergabung.value = pickedDate;
  //     // Format tanggal ke dalam string untuk ditampilkan di TextFormField
  //     tanggalBergabungC.text =
  //         DateFormat('dd MMMM yyyy', 'id_ID').format(pickedDate);
  //   }
  // }

  void simpanPegawai_x() {
    if (formKey.currentState!.validate()) {
      // Proses penyimpanan data
      // Contoh:
      print('Nama: ${namaC.text}');
      print('NIP: ${nipC.text}');
      print('Jabatan: ${jabatanC.text}');
      print('Email: ${emailC.text}');
      print('Telepon: ${teleponC.text}');
      print('Alamat: ${alamatC.text}');
      if (tanggalBergabung.value != null) {
        print('Tanggal Bergabung: ${DateFormat('yyyy-MM-dd').format(tanggalBergabung.value!)}');
      }

      // TODO: Tambahkan logika untuk menyimpan ke Firebase Firestore atau database lain
      // Contoh:
      // try {
      //   await FirebaseFirestore.instance.collection('pegawai').add({
      //     'nama': namaController.text,
      //     'nip': nipController.text,
      //     // ... data lainnya
      //     'tanggal_bergabung': tanggalBergabung.value, // Simpan sebagai Timestamp
      //     'createdAt': FieldValue.serverTimestamp(),
      //   });
      //   Get.snackbar('Sukses', 'Data pegawai berhasil disimpan', backgroundColor: Colors.green, colorText: Colors.white);
      //   Get.back(); // Kembali ke halaman sebelumnya
      // } catch (e) {
      //   Get.snackbar('Error', 'Gagal menyimpan data: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
      // }

      Get.snackbar(
        'Sukses',
        'Data pegawai berhasil divalidasi (belum disimpan)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Gagal',
        'Mohon lengkapi semua field yang wajib diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> pegawaiDitambahkan() async {

    String aliasNama = (jenisKelamin.value == "Laki-Laki") ? "Ustadz" : "Ustazah";

    if (passAdminC.text.isNotEmpty) {
      isLoadingTambahPegawai.value = true;
      try {
        String emailAdmin = auth.currentUser!.email!;

        // (jangan dihapus)
        // ignore: unused_local_variable
        UserCredential userCredentialAdmin  = await auth.signInWithEmailAndPassword(
          email: emailAdmin,
          password: passAdminC.text,
        );

        UserCredential pegawaiCredential =
            await auth.createUserWithEmailAndPassword(
          email: emailC.text,
          password: 'telagailmu',
        );
        // print(pegawaiCredential);

        if (pegawaiCredential.user != null) {
          String uid = pegawaiCredential.user!.uid;

          await firestore
              .collection("Sekolah")
              .doc(idSekolah)
              .collection('pegawai')
              .doc(uid)
              .set({
            "alias": ("$aliasNama ${namaC.text}"),
            "alamat" : alamatC.text,
            "nip": nipC.text,
            "telepon" : teleponC.text,
            "tglgabung" :  tanggalBergabungC.text,
            "nama": namaC.text,
            "email": emailC.text,
            "role": jabatanC.text,
            "jeniskelamin" : jenisKelamin.value,
            "uid": uid,
            "tanggalinput": DateTime.now().toIso8601String(),
            "emailpenginput" : emailAdmin
          });

          await pegawaiCredential.user!.sendEmailVerification();

          await auth.signOut();

          //disini login ulang admin penginput (jangan dihapus)
          // ignore: unused_local_variable
          UserCredential userCredentialAdmin  = await auth.signInWithEmailAndPassword(
          email: emailAdmin,
          password: passAdminC.text,
        );

          Get.back(); // tutup dialog
          Get.back(); // back to home

          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM,
              'Berhasil',
              'Karyawan berhasil ditambahkan');
        }
        isLoadingTambahPegawai.value = false;
      } on FirebaseAuthException catch (e) {
        isLoadingTambahPegawai.value = false;
        if (e.code == 'weak-password') {
          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM,
              'Terjadi Kesalahan',
              'Password terlalu singkat');
        } else if (e.code == 'email-already-in-use') {
          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM,
              'Terjadi Kesalahan',
              'email pegawai sudah terdaftar');
        } else if (e.code == 'invalid-credential') {
          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM,
              'Terjadi Kesalahan',
              'password salah');
        } else {
          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM, 'Terjadi Kesalahan', e.code);
        }
      } catch (e) {
        isLoadingTambahPegawai.value = false;
        Get.snackbar(
            snackPosition: SnackPosition.BOTTOM,
            'Terjadi Kesalahan',
            'Tidak dapat menambahkan pegawai, harap dicoba lagi');
      }
    } else {
      isLoading.value = false;
      Get.snackbar(
          snackPosition: SnackPosition.BOTTOM,
          'Error',
          'Password Admin wajib diisi');
    }
  }

  Future<void> simpanPegawai() async {
    if (isLoading.value = true) {
      Get.defaultDialog(
        title: 'Verifikasi Admnin',
        content: Column(
          children: [
            Text('Masukan password'),
            SizedBox(height: 10),
            TextField(
              controller: passAdminC,
              obscureText: true,
              autocorrect: false,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: 'Password',
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              isLoading.value = false;
              Get.back();
            },
            child: Text('CANCEL'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: () async {
                if (isLoadingTambahPegawai.isFalse) {
                  await pegawaiDitambahkan();
                }
                isLoading.value = false;
              },
              child: Text(
                isLoadingTambahPegawai.isFalse
                    ? 'Tambah Pegawai'
                    : 'LOADING...',
              ),
            ),
          ),
        ],
      );
    } else {
      Get.snackbar(
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color.fromARGB(255, 156, 151, 151),
        'Terjadi Kesalahan',
        '* Wajib di isi',
      );
    }
  }
}