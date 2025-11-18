// lib/app/modules/halaqah_grading/controllers/halaqah_grading_controller.dart


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_group_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/halaqah_setoran_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_simple_model.dart';
import 'package:intl/intl.dart';

import '../../../controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../services/notifikasi_service.dart';
import '../views/halaqah_grading_view.dart';


class AnggotaGrupDetail {
  final SiswaSimpleModel siswa;
  final Map<String, dynamic>? tingkatan;
  AnggotaGrupDetail({required this.siswa, this.tingkatan});
}

class HalaqahGradingController extends GetxController {
  late HalaqahGroupModel group;
  // late Future<List<SiswaSimpleModel>> listAnggotaFuture;
  late Future<List<AnggotaGrupDetail>> listAnggotaFuture;


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  final RxMap<String, Timestamp> antrianMap = <String, Timestamp>{}.obs;
  // final RxSet<String> siswaDiajukanUids = <String>{}.obs;
  final RxMap<String, String> siswaUjianStatusMap = <String, String>{}.obs;

  final RxBool isSavingRapor = false.obs;

  @override
  void onInit() {
    super.onInit();
    group = Get.arguments as HalaqahGroupModel;
    listAnggotaFuture = fetchAnggota();
    // listAnggotaFuture = fetchAnggota() as Future<List<SiswaSimpleModel>>;
  }

  void goToRiwayatSiswa(SiswaSimpleModel siswa) {
    Get.toNamed(Routes.HALAQAH_RIWAYAT_PENGAMPU, arguments: siswa);
  }

  void goToSetoranPage(SiswaSimpleModel siswa) {
    Get.toNamed(
      Routes.HALAQAH_SETORAN_SISWA,
      arguments: {
        'siswa': siswa,
        'isPengganti': group.isPengganti,
        // --- [BARU] Kirim juga data pengampu utama ---
        'pengampuUtama': {
          'id': group.idPengampu,
          'nama': group.namaPengampu,
          'alias': group.aliasPengampu,
        }
      },
    );
  }

  // Future<List<AnggotaGrupDetail>> fetchAnggota() async {
  //   final tahunAjaran = configC.tahunAjaranAktif.value;

  //   final groupRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
  //       .collection('tahunajaran').doc(tahunAjaran)
  //       .collection('halaqah_grup').doc(group.id);
    
  //   final ujianRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
  //       .collection('tahunajaran').doc(tahunAjaran)
  //       .collection('halaqah_ujian');

  //   final results = await Future.wait([
  //     groupRef.collection('anggota').get(),
  //     groupRef.get(),
  //     ujianRef.where('idGrup', isEqualTo: group.id).get(),
  //   ]);

  //   final anggotaSnapshot = results[0] as QuerySnapshot;
  //   final groupSnapshot = results[1] as DocumentSnapshot;
  //   final ujianSnapshot = results[2] as QuerySnapshot;

  //   final dataAntrian = (groupSnapshot.data() as Map<String, dynamic>?)?['antrianSetoran'] as Map<String, dynamic>? ?? {};
  //   antrianMap.clear();
  //   dataAntrian.forEach((uid, data) {
  //     antrianMap[uid] = data['waktu'] as Timestamp;
  //   });

  //   siswaUjianStatusMap.clear();
  //   for (var doc in ujianSnapshot.docs) {
  //     // [FIX 1 & 2] Casting doc.data() menjadi Map<String, dynamic>
  //     final data = doc.data() as Map<String, dynamic>?; 

  //     final status = data?['status'] as String?;
  //     final uidSiswa = data?['uidSiswa'] as String?;

  //     if (uidSiswa != null && (status == 'diajukan' || status == 'dijadwalkan')) {
  //       siswaUjianStatusMap[uidSiswa] = status!;
  //     }
  //   }

  //   final semuaSiswaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
  //     .collection('siswa').get();
      
  //   final Map<String, Map<String, dynamic>> semuaSiswaDataMap = {
  //     for (var doc in semuaSiswaSnapshot.docs) doc.id: doc.data()
  //   };

  //   // Buat Map UID anggota untuk pencarian cepat
  //   final Set<String> anggotaUids = anggotaSnapshot.docs.map((doc) => doc.id).toSet();

  //   List<AnggotaGrupDetail> listAnggotaDetail = [];

  //   // Filter dan gabungkan data di sisi klien
  //   for (String uid in anggotaUids) {
  //     if (semuaSiswaDataMap.containsKey(uid)) {
  //       final dataSiswa = semuaSiswaDataMap[uid]!;
  //       // Ambil nama dari data anggota asli untuk konsistensi
  //       final namaSiswaDiGrup = (anggotaSnapshot.docs.firstWhere((doc) => doc.id == uid).data() as Map)['namaSiswa'];

  //       listAnggotaDetail.add(
  //         AnggotaGrupDetail(
  //           siswa: SiswaSimpleModel(
  //             uid: uid,
  //             nama: namaSiswaDiGrup ?? 'Tanpa Nama',
  //             kelasId: (dataSiswa['kelasId'] as String?) ?? 'N/A',
  //           ),
  //           tingkatan: dataSiswa['halaqahTingkatan'] as Map<String, dynamic>?,
  //         )
  //       );
  //     }
  //   }
  //   return listAnggotaDetail;
  // }

  Future<List<AnggotaGrupDetail>> fetchAnggota() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    final sekolahRef = _firestore.collection('Sekolah').doc(configC.idSekolah);
    final tahunAjaranRef = sekolahRef.collection('tahunajaran').doc(tahunAjaran);
    
    final groupRef = tahunAjaranRef.collection('halaqah_grup').doc(group.id);
    final ujianRef = tahunAjaranRef.collection('halaqah_ujian');

    // --- Tahap 1: Ambil data grup, anggota (hanya UID), dan data ujian secara paralel ---
    final results = await Future.wait([
      groupRef.collection('anggota').get(),
      groupRef.get(),
      ujianRef.where('idGrup', isEqualTo: group.id).get(),
    ]);

    final anggotaSnapshot = results[0] as QuerySnapshot;
    final groupSnapshot = results[1] as DocumentSnapshot;
    final ujianSnapshot = results[2] as QuerySnapshot;

    // --- Proses data grup dan ujian (tidak ada perubahan di sini) ---
    final dataAntrian = (groupSnapshot.data() as Map<String, dynamic>?)?['antrianSetoran'] as Map<String, dynamic>? ?? {};
    antrianMap.clear();
    dataAntrian.forEach((uid, data) {
      antrianMap[uid] = data['waktu'] as Timestamp;
    });

    siswaUjianStatusMap.clear();
    for (var doc in ujianSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?; 
      final status = data?['status'] as String?;
      final uidSiswa = data?['uidSiswa'] as String?;
      if (uidSiswa != null && (status == 'diajukan' || status == 'dijadwalkan')) {
        siswaUjianStatusMap[uidSiswa] = status!;
      }
    }

    // --- [STRATEGI BARU] - Mengambil data siswa secara efisien ---

    // 1. Kumpulkan semua UID anggota dari snapshot
    final List<String> anggotaUids = anggotaSnapshot.docs.map((doc) => doc.id).toList();

    // Jika tidak ada anggota, langsung selesaikan misi.
    if (anggotaUids.isEmpty) {
      return [];
    }

    // 2. Pecah daftar UID menjadi beberapa bagian (chunk) @ 30 UID per bagian
    // Ini untuk menghindari limit query 'whereIn' dari Firestore.
    const chunkSize = 30;
    List<List<String>> uidChunks = [];
    for (var i = 0; i < anggotaUids.length; i += chunkSize) {
      uidChunks.add(
        anggotaUids.sublist(i, i + chunkSize > anggotaUids.length ? anggotaUids.length : i + chunkSize)
      );
    }

    // 3. Buat dan jalankan query untuk setiap 'chunk' secara paralel
    List<Future<QuerySnapshot>> futures = [];
    final siswaCollectionRef = sekolahRef.collection('siswa');

    for (final chunk in uidChunks) {
      futures.add(
        siswaCollectionRef.where(FieldPath.documentId, whereIn: chunk).get()
      );
    }
    
    // Tunggu semua query 'chunk' selesai
    final List<QuerySnapshot> semuaSiswaSnapshots = await Future.wait(futures);

    // 4. Gabungkan hasil dari semua 'chunk' ke dalam satu map untuk pencarian cepat
    final Map<String, Map<String, dynamic>> semuaSiswaDataMap = {};
    for (final snapshot in semuaSiswaSnapshots) {
      for (final doc in snapshot.docs) {
        semuaSiswaDataMap[doc.id] = doc.data() as Map<String, dynamic>;
      }
    }

    // --- [STRATEGI LAMA DILANJUTKAN] - Dengan data yang sudah diambil secara efisien ---
    List<AnggotaGrupDetail> listAnggotaDetail = [];

    // Gunakan 'anggotaSnapshot' untuk memastikan data nama sesuai dengan yang ada di grup
    for (var anggotaDoc in anggotaSnapshot.docs) {
      final uid = anggotaDoc.id;
      if (semuaSiswaDataMap.containsKey(uid)) {
        final dataSiswa = semuaSiswaDataMap[uid]!;
        final namaSiswaDiGrup = (anggotaDoc.data() as Map)['namaSiswa'];

        listAnggotaDetail.add(
          AnggotaGrupDetail(
            siswa: SiswaSimpleModel(
              uid: uid,
              nama: namaSiswaDiGrup ?? 'Tanpa Nama',
              kelasId: (dataSiswa['kelasId'] as String?) ?? 'N/A',
              // [PERBAIKAN KUNCI] Teruskan URL gambar dari data siswa yang sudah kita ambil.
              profileImageUrl: dataSiswa['fotoProfilUrl'] as String?,
            ),
            tingkatan: dataSiswa['halaqahTingkatan'] as Map<String, dynamic>?,
          )
        );
      }
    }
    
    return listAnggotaDetail;
  }

  Future<void> ajukanSiswaUntukUjian(SiswaSimpleModel siswa) async {
    Get.defaultDialog(
      title: "Konfirmasi Pengajuan",
      middleText: "Apakah Anda yakin ingin mengajukan ${siswa.nama} untuk ujian/munaqosyah?",
      textConfirm: "Ya, Ajukan",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        try {
          final tahunAjaran = configC.tahunAjaranAktif.value;
          final WriteBatch batch = _firestore.batch();

          // 1. Buat dokumen pengajuan ujian
          final docUjianRef = _firestore
              .collection('Sekolah').doc(configC.idSekolah)
              .collection('tahunajaran').doc(tahunAjaran)
              .collection('halaqah_ujian').doc();

          final dataToSave = {
            'uidSiswa': siswa.uid, 'namaSiswa': siswa.nama, 'kelasId': siswa.kelasId,
            'idGrup': group.id, 'status': 'diajukan',
            'tanggalPengajuan': FieldValue.serverTimestamp(),
            'uidPengaju': authC.auth.currentUser!.uid, 'namaPengaju': configC.infoUser['nama'] ?? 'Pengampu',
          };
          batch.set(docUjianRef, dataToSave);

          // 2. Denormalisasi status ke dokumen siswa
          final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
          batch.update(siswaRef, {'statusUjianHalaqah': 'diajukan'});

          // 3. Kirim notifikasi (ini bukan bagian dari batch karena merupakan layanan terpisah)
          await NotifikasiService.kirimNotifikasi(
            uidPenerima: siswa.uid,
            judul: "Pengajuan Ujian Halaqah",
            isi: "Alhamdulillah, ananda ${siswa.nama} telah diajukan untuk mengikuti ujian/munaqosyah oleh pengampu. Mohon bantuannya untuk persiapan dan muroja'ah di rumah.",
            tipe: "HALAQAH",
          );

          // 4. Commit batch dan update UI
          await batch.commit();
          siswaUjianStatusMap[siswa.uid] = 'diajukan';
          Get.snackbar("Berhasil", "${siswa.nama} telah diajukan untuk ujian.");

        } catch (e) {
          Get.snackbar("Error", "Gagal mengajukan siswa: ${e.toString()}");
        }
      },
    );
  }

  Future<void> batalkanPengajuanUjian(SiswaSimpleModel siswa) async {
    Get.defaultDialog(
      title: "Konfirmasi Pembatalan",
      middleText: "Yakin ingin membatalkan pengajuan ujian untuk ${siswa.nama}?",
      textConfirm: "Ya, Batalkan",
      textCancel: "Tidak",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          final tahunAjaran = configC.tahunAjaranAktif.value;
          final WriteBatch batch = _firestore.batch();
          
          final querySnapshot = await _firestore
              .collection('Sekolah').doc(configC.idSekolah)
              .collection('tahunajaran').doc(tahunAjaran)
              .collection('halaqah_ujian')
              .where('uidSiswa', isEqualTo: siswa.uid)
              .where('status', isEqualTo: 'diajukan')
              .limit(1)
              .get();
          
          if (querySnapshot.docs.isEmpty) {
            Get.snackbar("Gagal", "Pengajuan tidak ditemukan atau statusnya sudah berubah.");
            siswaUjianStatusMap.remove(siswa.uid);
            return;
          }
  
          // 1. Hapus dokumen ujian
          batch.delete(querySnapshot.docs.first.reference);
  
          // 2. Hapus denormalisasi status dari dokumen siswa
          final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
          batch.update(siswaRef, {'statusUjianHalaqah': FieldValue.delete()});
  
          // 3. Kirim notifikasi
          await NotifikasiService.kirimNotifikasi(
            uidPenerima: siswa.uid,
            judul: "Pengajuan Ujian Dibatalkan",
            isi: "Pengajuan ujian untuk ananda ${siswa.nama} telah dibatalkan oleh pengampu. Mohon untuk terus meningkatkan setoran.",
            tipe: "HALAQAH",
          );
          
          // 4. Commit batch dan update UI
          await batch.commit();
          siswaUjianStatusMap.remove(siswa.uid);
          Get.snackbar("Berhasil", "Pengajuan ujian untuk ${siswa.nama} telah dibatalkan.");
  
        } catch (e) {
          Get.snackbar("Error", "Gagal membatalkan pengajuan: ${e.toString()}");
        }
      },
    );
  }

  void showInputNilaiRaporDialog() async {
    // Ambil daftar anggota dari future yang sudah ada
    final List<AnggotaGrupDetail> anggota = await listAnggotaFuture;
    if (anggota.isEmpty) {
      Get.snackbar("Informasi", "Tidak ada anggota di dalam grup ini.");
      return;
    }

    // Siapkan map controller untuk setiap siswa
    final Map<String, TextEditingController> nilaiControllers = {
      for (var detail in anggota) detail.siswa.uid: TextEditingController()
    };
    final Map<String, TextEditingController> catatanControllers = {
      for (var detail in anggota) detail.siswa.uid: TextEditingController()
    };

    // Tampilkan dialog kustom
    Get.dialog(
      AlertDialog(
        title: const Text("Input Nilai Rapor Halaqah"),
        content: HalaqahGradingDialogContent( // Widget dialog dari View
          anggota: anggota,
          nilaiControllers: nilaiControllers,
          catatanControllers: catatanControllers,
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Batal")),
          Obx(() => ElevatedButton(
                onPressed: isSavingRapor.value ? null : () {
                  _saveNilaiRaporMassal(anggota, nilaiControllers, catatanControllers);
                },
                child: isSavingRapor.value ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Simpan Semua"),
              )),
        ],
      ),
      // Penting: dispose semua controller saat dialog ditutup untuk menghindari memory leak
      barrierDismissible: false,
    ).whenComplete(() {
      nilaiControllers.values.forEach((c) => c.dispose());
      catatanControllers.values.forEach((c) => c.dispose());
    });
  }

  Future<void> _saveNilaiRaporMassal(
      List<AnggotaGrupDetail> anggota,
      Map<String, TextEditingController> nilaiControllers,
      Map<String, TextEditingController> catatanControllers) async {
    isSavingRapor.value = true;
    try {
      final semester = configC.semesterAktif.value;
      if (semester.isEmpty || semester == "0") {
        throw Exception("Semester aktif tidak valid.");
      }

      final WriteBatch batch = _firestore.batch();

      for (var detail in anggota) {
        final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(detail.siswa.uid);
        
        final nilai = int.tryParse(nilaiControllers[detail.siswa.uid]!.text);
        final catatan = catatanControllers[detail.siswa.uid]!.text.trim();

        // Hanya update jika ada data yang diinput
        if (nilai != null || catatan.isNotEmpty) {
          final dataToUpdate = {
            'nilai': nilai,
            'catatan': catatan,
            'diinputOleh': configC.infoUser['alias'] ?? configC.infoUser['nama'],
            'tanggalInput': FieldValue.serverTimestamp(),
          };
          
          // Gunakan dot notation untuk update field di dalam map
          batch.update(siswaRef, {'raporHalaqahSemester.$semester': dataToUpdate});
        }
      }

      await batch.commit();
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "Nilai rapor untuk ${anggota.length} siswa telah disimpan.");

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan nilai rapor: ${e.toString()}");
    } finally {
      isSavingRapor.value = false;
    }
  }
  
  @override
  void onClose() {
    super.onClose();
  }
}