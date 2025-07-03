import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JurnalAjarHarianController extends GetxController {
  // RxString jenisKelamin = "".obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingTambahSiswa = false.obs;
   RxString selectedKelasObs = "".obs;
    RxString selectedMapelObs = "".obs; // Bisa juga untuk mapel jika 

  TextEditingController istirahatsholatC = TextEditingController();
  TextEditingController materimapelC = TextEditingController();
  TextEditingController kelasSiswaC = TextEditingController();
  TextEditingController mapelC = TextEditingController();
  TextEditingController catatanjurnalC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = 'P9984539';
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  // Saat kelasSiswaC berubah, update juga selectedKelasObs
  void onKelasChanged(String? value) {
    if (value != null) {
      kelasSiswaC.text = value;
      selectedKelasObs.value = value; // Update observable
      mapelC.clear(); // Kosongkan mapel
      selectedMapelObs.value = ""; // Kosongkan observable mapel jika ada
      // print("Kelas dipilih: ${selectedKelasObs.value}");
    } else {
      kelasSiswaC.clear();
      selectedKelasObs.value = "";
    }
  }

  void onMapelChanged(String? value) {
    if (value != null) {
      mapelC.text = value;
      selectedMapelObs.value = value;
    } else {
      mapelC.clear();
      selectedMapelObs.value = "";
    }
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

  Future<QuerySnapshot<Map<String, dynamic>>> tampilkanJamPelajaran() async {
    try {
      return await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('jampelajaran')
          .get();
    } catch (e) {
      throw Exception(
        'Data Matapelajaran tidak bisa diakses, silahkan ulangi lagi',
      );
    }
  }

  Future<List<String>> getDataKelas() async {
    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasaktif')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataMapel() async {
  // 1. Validasi apakah kelas sudah dipilih
  if (kelasSiswaC.text.trim().isEmpty) {
    // Jika kelas belum dipilih, kembalikan list kosong.
    // DropdownSearch akan menampilkan "Tidak ada data" atau state kosongnya.
    // Get.snackbar bisa mengganggu jika ini dipanggil berkali-kali oleh DropdownSearch.
    // print("getDataMapel: Kelas belum dipilih, mengembalikan list kosong.");
    return [];
  }

  if (selectedKelasObs.value.trim().isEmpty) {
      return [];
    }

  // Opsional: Set state loading untuk dropdown mapel jika Anda punya
  // isLoadingMapel.value = true;
  // print("getDataMapel: Mengambil mapel untuk kelas: ${kelasSiswaC.text}");

  try {
    // 2. Dapatkan tahun ajaran terakhir (fungsi ini sudah ada dan di-await)
    final String tahunAjaranRaw = await getTahunAjaranTerakhir();
    final String idTahunAjaranFormatted = tahunAjaranRaw.replaceAll("/", "-");

    // 3. Bangun path query ke Firestore
    // Pastikan semua ID (idSekolah, idUser, idTahunAjaranFormatted, kelasSiswaC.text) valid
    final QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser) // Mengambil mapel yang diajar oleh guru ini
        .collection('tahunajaran')
        .doc(idTahunAjaranFormatted)
        .collection('kelasnya')
        .doc(kelasSiswaC.text) // Kelas yang dipilih
        .collection('matapelajaran') // Koleksi matapelajaran yang diajar guru di kelas tsb
        .get();

    // 4. Proses hasil query
    final List<String> mapelList = [];
    if (querySnapshot.docs.isNotEmpty) {
      for (var docSnapshot in querySnapshot.docs) {
        // Asumsi ID dokumen adalah nama mata pelajaran
        mapelList.add(docSnapshot.id);
      }
      // print("getDataMapel: Mapel ditemukan: $mapelList");
    } else {
      // print("getDataMapel: Tidak ada mapel ditemukan untuk kelas ${kelasSiswaC.text} atau path tidak valid.");
      // Jika tidak ada dokumen, berarti tidak ada mapel yang terdaftar untuk guru/kelas tersebut.
      // Tidak perlu Get.snackbar di sini, biarkan DropdownSearch menampilkan "Tidak ada data".
    }
    return mapelList;

  } catch (e) {
    // 5. Tangani error jika terjadi
    // print("getDataMapel: Error saat mengambil data mapel - $e");
    Get.snackbar(
      "Error",
      "Gagal mengambil data mata pelajaran. Silakan coba lagi.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
    );
    return []; // Kembalikan list kosong jika terjadi error
  } finally {
    // Opsional: Set state loading false setelah selesai
    // isLoadingMapel.value = false;
  }
}

  
  Future<void> simpanDataJurnal(String jampelajaran) async {
  isLoading.value = true; // Tambahkan loading indicator
  try {
    // --- Persiapan Data (Setup) ---
    final String tahunAjaran = await getTahunAjaranTerakhir();
    final String idTahunAjaran = tahunAjaran.replaceAll("/", "-");
    final String docIdJurnal = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String idKelas = kelasSiswaC.text;
    final String namamapel = mapelC.text;

    // Ambil data guru sekali saja
    final guruDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
    if (!guruDoc.exists) {
      throw Exception("Data penginput tidak ditemukan.");
    }
    final String namaGuru = guruDoc.data()?['alias'] ?? 'Tanpa Nama';

    // --- Buat Write Batch ---
    final WriteBatch batch = firestore.batch();
    final Timestamp serverTimestamp = Timestamp.now(); // Gunakan timestamp yang sama untuk semua

    // Data Jurnal Utama yang akan di-copy ke banyak tempat
    final Map<String, dynamic> dataJurnalUtama = {
      'namamapel': namamapel,
      'kelas': idKelas,
      'tanggalinput': serverTimestamp, // Gunakan Timestamp
      'idpenginput': idUser,
      'emailpenginput': emailAdmin,
      'namapenginput': namaGuru,
      'materipelajaran': materimapelC.text.trim(),
      'jampelajaran': jampelajaran,
      'uidtanggal': docIdJurnal,
      'catatanjurnal': catatanjurnalC.text.trim(),
    };

    // 1. Path yang dibaca oleh HomeController (PALING PENTING)
    final refJurnalDiKelasAktif = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelasaktif').doc(idKelas)
        .collection('tanggaljurnal').doc(docIdJurnal)
        .collection('jurnalkelas').doc(jampelajaran);
    batch.set(refJurnalDiKelasAktif, dataJurnalUtama);

    // 2. Path untuk header tanggal jurnal (untuk wali/ortu)
    final refHeaderTanggalJurnal = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelasaktif').doc(idKelas)
        .collection('tanggaljurnal').doc(docIdJurnal);
    batch.set(refHeaderTanggalJurnal, {
      'kelas': idKelas,
      'tanggalinput': serverTimestamp,
      'idpenginput': idUser,
    }, SetOptions(merge: true)); // Gunakan merge agar tidak menimpa data jam lain

    // 3. Path untuk catatan jurnal di profil guru
    final refJurnalDiProfilGuru = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('pegawai').doc(idUser)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('tanggaljurnal').doc(docIdJurnal)
        .collection('jurnalkelas').doc(jampelajaran);
    batch.set(refJurnalDiProfilGuru, dataJurnalUtama);

    // Anda bisa tambahkan path lain ke dalam batch jika masih ada
    // Contoh:
    // final refJurnalHarian = firestore...
    // batch.set(refJurnalHarian, ...);

    // --- Jalankan semua operasi dalam satu transaksi ---
    await batch.commit();

    Get.back(); // Tutup bottom sheet
    Get.snackbar("Berhasil", "Data jurnal berhasil disimpan", backgroundColor: Colors.green, colorText: Colors.white);
    
  } catch (e) {
    Get.snackbar("Error", "Gagal menyimpan jurnal: ${e.toString()}", backgroundColor: Colors.red, colorText: Colors.white);
  } finally {
    isLoading.value = false;
  }
}

  Stream<QuerySnapshot<Map<String, dynamic>>> tampilkanjurnal() async* {
  try {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    DateTime now = DateTime.now();
    // --- UBAH BARIS INI AGAR KONSISTEN ---
    String docIdJurnal = DateFormat('yyyy-MM-dd').format(now);

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('tanggaljurnal')
        .doc(docIdJurnal)
        .collection('jurnalkelas')
        .orderBy('tanggalinput', descending: true) // Tambahkan order by agar jurnal terbaru di atas
        .snapshots();
  } catch (e) {
    // Jika terjadi error (misal, tahun ajaran tidak ketemu), kembalikan stream kosong
    print("Error di stream tampilkanjurnal: $e");
    yield* Stream<QuerySnapshot<Map<String, dynamic>>>.empty(); // Kembalikan stream kosong dengan tipe yang benar
  }
}
}
