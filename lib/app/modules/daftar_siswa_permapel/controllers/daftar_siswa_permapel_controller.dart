// lib/app/modules/daftar_siswa_permapel/controllers/daftar_siswa_permapel_controller.dart (SUDAH DIINTEGRASIKAN)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/siswa_model.dart';
import '../../../routes/app_pages.dart';

class DaftarSiswaPermapelController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String idKelas, idMapel, namaMapel, idGuru, namaGuru;
  late bool isPengganti;

  final isLoading = true.obs;
  final isDialogLoading = false.obs;
  final RxList<SiswaModel> daftarSiswa = <SiswaModel>[].obs;
  
  // [BARU] State untuk mendeteksi apakah pengguna adalah Wali Kelas
  final RxBool isWaliKelas = false.obs;

  final isSavingCatatan = false.obs;
  
  final TextEditingController judulTugasC = TextEditingController();
  final TextEditingController deskripsiTugasC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    idKelas = args['idKelas'] ?? '';
    idMapel = args['idMapel'] ?? '';
    namaMapel = args['namaMapel'] ?? 'Mata Pelajaran';
    idGuru = args['idGuru'] ?? '';
    namaGuru = args['namaGuru'] ?? '';
    isPengganti = args['isPengganti'] ?? false;
    
    _checkIsWaliKelas(); // [BARU] Panggil fungsi pengecekan
    _fetchDaftarSiswa();
  }

  // [BARU] Fungsi untuk memeriksa apakah pengguna adalah Wali Kelas dari kelas ini
  void _checkIsWaliKelas() {
    // Membandingkan id kelas yang diampu oleh pengguna (dari configC)
    // dengan idKelas halaman ini.
    if (configC.infoUser['kelasDiampu'] == idKelas) {
      isWaliKelas.value = true;
    }
  }

  @override
  void onClose() {
    judulTugasC.dispose();
    deskripsiTugasC.dispose();
    super.onClose();
  }

  // Future<void> _fetchDaftarSiswa() async {
  //   isLoading.value = true;
  //   try {
  //     final String tahunAjaran = configC.tahunAjaranAktif.value;
  //     if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
  //       throw Exception("Tahun ajaran aktif tidak valid.");
  //     }
  //     final snapshot = await _firestore
  //         .collection('Sekolah').doc(configC.idSekolah)
  //         .collection('tahunajaran').doc(tahunAjaran)
  //         .collection('kelastahunajaran').doc(idKelas)
  //         .collection('daftarsiswa').orderBy('namaLengkap').get();
  //     final allSiswa = snapshot.docs.map((doc) => 
  //         SiswaModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
  //         .toList();
  //     daftarSiswa.assignAll(allSiswa);
  //   } catch (e) {
  //     Get.snackbar("Error", "Gagal memuat daftar siswa: ${e.toString()}");
  //     print("[DaftarSiswaPermapelController] Error fetching students: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> _fetchDaftarSiswa() async {
    isLoading.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
        throw Exception("Tahun ajaran aktif tidak valid.");
      }

      // Langkah 1: Ambil daftar siswa (roster) dari sub-koleksi kelas.
      final rosterSnapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('daftarsiswa').get();

      if (rosterSnapshot.docs.isEmpty) {
        daftarSiswa.clear();
        isLoading.value = false;
        return;
      }

      final siswaUids = rosterSnapshot.docs.map((doc) => doc.id).toList();

      // --- [PERBAIKAN ANTI-CRASH] Pecah UID menjadi beberapa bagian (chunk) @ 30 ---
      const chunkSize = 30;
      List<List<String>> uidChunks = [];
      for (var i = 0; i < siswaUids.length; i += chunkSize) {
        uidChunks.add(
          siswaUids.sublist(i, i + chunkSize > siswaUids.length ? siswaUids.length : i + chunkSize)
        );
      }

      // Langkah 2: Ambil data profil LENGKAP secara paralel untuk setiap chunk.
      List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [];
      final siswaCollectionRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa');

      for (final chunk in uidChunks) {
        futures.add(
          siswaCollectionRef.where(FieldPath.documentId, whereIn: chunk).get()
        );
      }
      
      final List<QuerySnapshot<Map<String, dynamic>>> allProfileSnapshots = await Future.wait(futures);

      // Gabungkan semua hasil ke dalam satu Peta (Map) untuk pencarian cepat.
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> profileMap = {};
      for (final snapshot in allProfileSnapshots) {
        for (final doc in snapshot.docs) {
          profileMap[doc.id] = doc;
        }
      }

      // Langkah 3: Gabungkan data.
      final List<SiswaModel> hydratedSiswaList = [];
      for (final rosterDoc in rosterSnapshot.docs) {
        if (profileMap.containsKey(rosterDoc.id)) {
          final fullProfileDoc = profileMap[rosterDoc.id]!;
          hydratedSiswaList.add(SiswaModel.fromFirestore(fullProfileDoc));
        }
      }
      
      hydratedSiswaList.sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));
      daftarSiswa.assignAll(hydratedSiswaList);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar siswa: ${e.toString()}");
      print("[DaftarSiswaPermapelController] Error fetching students: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void goToInputNilaiSiswa(SiswaModel siswa) {
    Get.toNamed(
      Routes.INPUT_NILAI_SISWA,
      arguments: {
        'idKelas': idKelas,
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idGuru': idGuru,
        'namaGuru': namaGuru,
        'siswa': siswa,
      },
    );
  }

  // [BARU] Fungsi navigasi ke halaman rapor siswa
  void goToRaporSiswa(SiswaModel siswa) {
    Get.toNamed(
      Routes.RAPOR_SISWA,
      arguments: {
        'siswa': siswa,
        'kelasId': idKelas,
        'semesterId': configC.semesterAktif.value,
      },
    );
  }

  void showBuatTugasDialog(BuildContext context) {
    judulTugasC.clear();
    deskripsiTugasC.clear();
    Get.defaultDialog(
      title: "Buat Tugas / Ulangan Baru",
      content: Column(
        children: [
          TextField(controller: judulTugasC, decoration: const InputDecoration(labelText: 'Judul (Contoh: PR Bab 1)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: deskripsiTugasC, decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)', border: OutlineInputBorder()), maxLines: 3),
        ],
      ),
      actions: [
        OutlinedButton(onPressed: isDialogLoading.value ? null : () => buatTugasBaru("Ulangan"), child: isDialogLoading.value ? const CircularProgressIndicator() : const Text("Simpan Ulangan")),
        ElevatedButton(onPressed: isDialogLoading.value ? null : () => buatTugasBaru("PR"), child: isDialogLoading.value ? const CircularProgressIndicator() : const Text("Simpan PR")),
      ],
    );
  }

  Future<void> buatTugasBaru(String kategori) async {
    if (judulTugasC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Judul tidak boleh kosong.");
      return;
    }
    isDialogLoading.value = true;
    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final String semester = configC.semesterAktif.value;
      final WriteBatch batch = _firestore.batch();
      final refTugas = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(semester)
        .collection('tugas_ulangan');
      final newTugasRef = refTugas.doc();
      batch.set(newTugasRef, {
        'judul': judulTugasC.text.trim(),
        'kategori': kategori,
        'deskripsi': deskripsiTugasC.text.trim(),
        'tanggal_dibuat': Timestamp.now(),
        'status': 'diumumkan',
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idGuru': idGuru,
        'namaGuru': namaGuru,
      });
      final snapshotSiswaTerbaru = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('daftarsiswa').get();
      final List<DocumentSnapshot<Map<String, dynamic>>> daftarSiswaUntukNotif = 
          snapshotSiswaTerbaru.docs.cast<DocumentSnapshot<Map<String, dynamic>>>();
      final String judulNotif = (kategori == "PR") ? "PR Baru: $namaMapel" : "Ulangan Baru: $namaMapel";
      final String isiNotif = "Ananda mendapatkan tugas baru: '${judulTugasC.text.trim()}'.";
      for (var siswaDoc in daftarSiswaUntukNotif) {
        final siswaUid = siswaDoc.id;
        final siswaMapelRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(tahunAjaran)
            .collection('kelastahunajaran').doc(idKelas)
            .collection('daftarsiswa').doc(siswaUid)
            .collection('semester').doc(semester)
            .collection('matapelajaran').doc(idMapel);
  
        batch.set(siswaMapelRef, {
          'idMapel': idMapel,
          'namaMapel': namaMapel,
          'idGuru': idGuru,
          'namaGuru': namaGuru,
          'aliasGuruPencatatAkhir': configC.infoUser['alias'] ?? configC.infoUser['nama'],
        }, SetOptions(merge: true));
        final siswaDocRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswaUid);
        batch.set(siswaDocRef.collection('notifikasi').doc(), {
          'judul': judulNotif,
          'isi': isiNotif,
          'tipe': (kategori == "PR") ? 'TUGAS_BARU' : 'ULANGAN_BARU',
          'tanggal': FieldValue.serverTimestamp(),
          'isRead': false,
          'deepLink': '/akademik/tugas/${newTugasRef.id}',
        });
        final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');
        batch.set(metaRef, {'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));
      }
      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "$kategori baru telah dibuat dan notifikasi dikirim.");
    } catch(e) {
      Get.snackbar("Error", "Gagal membuat tugas: ${e.toString()}"); 
      print("[DaftarSiswaPermapelController] Error creating assignment: $e");
    } finally { 
      isDialogLoading.value = false; 
      judulTugasC.clear(); 
      deskripsiTugasC.clear(); 
    }
  }

  void showCatatanRaporDialog() {
    final catatanController = TextEditingController();
    final RxMap<String, bool> siswaTerpilih = <String, bool>{}.obs;

    for (var siswa in daftarSiswa) {
      siswaTerpilih[siswa.uid] = true;
    }

    Get.dialog(
      Scaffold(
        appBar: AppBar(
          title: const Text("Tulis Catatan Rapor"),
          actions: [
            Obx(() => TextButton(
              onPressed: isSavingCatatan.value ? null : () {
                final selectedUids = siswaTerpilih.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();
                _saveCatatanMassal(catatanController.text, selectedUids);
              },
              child: isSavingCatatan.value 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text("SIMPAN", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
            )),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(
                  labelText: "Tulis Catatan Wali Kelas",
                  hintText: "Contoh: Ananda menunjukkan peningkatan...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              const Text("Pilih Siswa Penerima Catatan:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                // --- [PERBAIKAN KUNCI DI SINI] ---
                // Obx sekarang dipindahkan ke dalam itemBuilder
                child: ListView.builder(
                  itemCount: daftarSiswa.length,
                  itemBuilder: (context, index) {
                    final siswa = daftarSiswa[index];
                    // Setiap CheckboxListTile dibungkus Obx-nya sendiri
                    return Obx(() => CheckboxListTile(
                          title: Text(siswa.namaLengkap),
                          value: siswaTerpilih[siswa.uid] ?? false,
                          onChanged: (bool? value) {
                            siswaTerpilih[siswa.uid] = value ?? false;
                          },
                        ));
                  },
                ),
                // --- [AKHIR PERBAIKAN] ---
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => catatanController.dispose());
  }

  Future<void> _saveCatatanMassal(String catatan, List<String> selectedUids) async {
    if (catatan.trim().isEmpty) {
      Get.snackbar("Peringatan", "Catatan tidak boleh kosong.");
      return;
    }
    if (selectedUids.isEmpty) {
      Get.snackbar("Peringatan", "Pilih minimal satu siswa.");
      return;
    }

    isSavingCatatan.value = true;
    try {
      final WriteBatch batch = _firestore.batch();
      final semester = configC.semesterAktif.value;

      for (String uid in selectedUids) {
        final semesterDocRef = _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
            .collection('kelastahunajaran').doc(idKelas)
            .collection('daftarsiswa').doc(uid)
            .collection('semester').doc(semester);
        
        // Gunakan Set dengan merge: true. Ini akan membuat dokumen jika belum ada,
        // atau hanya memperbarui field jika dokumen sudah ada.
        batch.set(semesterDocRef, {'catatanWaliKelas': catatan}, SetOptions(merge: true));
      }

      await batch.commit();
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "Catatan rapor telah disimpan untuk ${selectedUids.length} siswa.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan catatan: ${e.toString()}");
    } finally {
      isSavingCatatan.value = false;
    }
  }

  void goToManajemenTugas() {
    Get.toNamed(
      Routes.MANAJEMEN_TUGAS,
      arguments: {
        'idKelas': idKelas,
        'idMapel': idMapel,
        'namaMapel': namaMapel,
        'idGuru': idGuru,
        'namaGuru': namaGuru,
        'daftarSiswa': daftarSiswa.toList(),
      },
    );
  }
}