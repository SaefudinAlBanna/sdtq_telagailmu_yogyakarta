// lib/app/modules/daftar_siswa_permapel/controllers/daftar_siswa_permapel_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/siswa_model.dart';
import '../../../routes/app_pages.dart';

class DaftarSiswaPermapelController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String idKelas, idMapel, namaMapel, idGuru, namaGuru;
  late bool isPengganti;

  // --- FITUR EVALUASI & RANKING ---
  final RxList<Map<String, dynamic>> dataRanking = <Map<String, dynamic>>[].obs;
  final isRankingLoading = false.obs;

  // State untuk loading bar
  final RxDouble progressGenerate = 0.0.obs;
  final RxBool isMassGenerating = false.obs;

  final isLoading = true.obs;
  final isDialogLoading = false.obs;
  final RxList<SiswaModel> daftarSiswa = <SiswaModel>[].obs;
  
  // State untuk mendeteksi apakah pengguna adalah Wali Kelas
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
    
    _checkIsWaliKelas(); // [DIPERBAIKI] Panggil fungsi pengecekan
    _fetchDaftarSiswa();
  }

  // --- [PERBAIKAN UTAMA: LOGIKA MULTI WALI KELAS] ---
  void _checkIsWaliKelas() {
    // Ambil data dari ConfigController
    List<dynamic>? group = configC.infoUser['waliKelasGroup'];
    String? single = configC.infoUser['kelasDiampu'];

    // Gabungkan ke dalam Set untuk pencarian cepat
    final Set<String> myKelasList = {};
    
    if (group != null && group.isNotEmpty) {
      myKelasList.addAll(group.map((e) => e.toString()));
    }
    if (single != null && single.isNotEmpty) {
      myKelasList.add(single);
    }

    // Cek apakah ID Kelas halaman ini ada di daftar kelas yang saya ampu
    if (myKelasList.contains(idKelas)) {
      isWaliKelas.value = true;
    } else {
      isWaliKelas.value = false;
    }
    
    // Debugging untuk memastikan
    print("DEBUG: Cek Wali Kelas di $idKelas. My List: $myKelasList -> Result: ${isWaliKelas.value}");
  }
  // --- [AKHIR PERBAIKAN] ---

  @override
  void onClose() {
    judulTugasC.dispose();
    deskripsiTugasC.dispose();
    super.onClose();
  }

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

      // Pecah UID menjadi beberapa bagian (chunk) @ 30
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

  void showRankingDialog() {
    // Reset data
    dataRanking.clear();
    _hitungRankingKelas();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Evaluasi & Peringkat Kelas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text("Berdasarkan Rata-rata Nilai Akhir Mapel", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(),
              Expanded(
                child: Obx(() {
                  if (isRankingLoading.value) return const Center(child: CircularProgressIndicator());
                  if (dataRanking.isEmpty) return const Center(child: Text("Data nilai belum lengkap / belum digenerate."));
                  
                  return ListView.builder(
                    itemCount: dataRanking.length,
                    itemBuilder: (context, index) {
                      final item = dataRanking[index];
                      // Juara 1, 2, 3 dikasih warna beda
                      Color? cardColor;
                      if (index == 0) cardColor = Colors.amber.shade100; // Emas
                      else if (index == 1) cardColor = Colors.grey.shade200; // Perak
                      else if (index == 2) cardColor = Colors.orange.shade100; // Perunggu

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo,
                            child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${item['jumlah_mapel']} Mapel Dinilai"),
                          trailing: Text(
                            (item['rata_rata'] as double).toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text("Tutup"),
                onPressed: () => Get.back(),
              )
            ],
          ),
        ),
      )
    );
  }

  Future<void> _hitungRankingKelas() async {
    isRankingLoading.value = true;
    try {
      final semester = configC.semesterAktif.value;
      final tahun = configC.tahunAjaranAktif.value;
      
      // List penampung hasil
      final List<Map<String, dynamic>> hasil = [];

      // Loop semua siswa di kelas ini (daftarSiswa sudah di-load di onInit)
      // Gunakan Future.wait agar cepat
      final futures = daftarSiswa.map((siswa) async {
        // Ambil SEMUA nilai mapel anak ini di semester ini
        // NOTE: Ini query yang lumayan berat (N siswa x 1 query).
        // Pastikan Firestore index sudah optimal.
        final snapshot = await _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(tahun)
            .collection('kelastahunajaran').doc(idKelas)
            .collection('daftarsiswa').doc(siswa.uid)
            .collection('semester').doc(semester)
            .collection('matapelajaran')
            .where('nilai_akhir', isGreaterThan: 0) // Hanya mapel yang sudah ada nilainya
            .get();

        if (snapshot.docs.isNotEmpty) {
          double totalNilai = 0;
          int jumlahMapel = 0;
          
          for (var doc in snapshot.docs) {
            final val = (doc.data()['nilai_akhir'] as num?)?.toDouble() ?? 0.0;
            if (val > 0) {
              totalNilai += val;
              jumlahMapel++;
            }
          }

          if (jumlahMapel > 0) {
            final rataRata = totalNilai / jumlahMapel;
            hasil.add({
              'nama': siswa.namaLengkap,
              'rata_rata': rataRata,
              'jumlah_mapel': jumlahMapel,
              'total_nilai': totalNilai
            });
          }
        }
      }).toList();

      await Future.wait(futures);

      // Urutkan dari nilai tertinggi
      hasil.sort((a, b) => (b['rata_rata'] as double).compareTo(a['rata_rata'] as double));
      dataRanking.assignAll(hasil);

    } catch (e) {
      Get.snackbar("Error", "Gagal menghitung peringkat: $e");
    } finally {
      isRankingLoading.value = false;
    }
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
                child: ListView.builder(
                  itemCount: daftarSiswa.length,
                  itemBuilder: (context, index) {
                    final siswa = daftarSiswa[index];
                    return Obx(() => CheckboxListTile(
                          title: Text(siswa.namaLengkap),
                          value: siswaTerpilih[siswa.uid] ?? false,
                          onChanged: (bool? value) {
                            siswaTerpilih[siswa.uid] = value ?? false;
                          },
                        ));
                  },
                ),
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
        
        batch.set(semesterDocRef, {'catatanWaliKelas': catatan}, SetOptions(merge: true));
      }

      await batch.commit();
      Get.back();
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

  Future<void> confirmGenerateMassal() async {
    // 1. CEK KUOTA HARIAN DULU SEBELUM TAMPILKAN DIALOG
    final canGenerate = await _checkGenerateQuota();
    if (!canGenerate) {
      Get.snackbar(
        "Batas Tercapai", 
        "Untuk efisiensi sistem, Generate Massal dibatasi maksimal 2x sehari per kelas.\nSilakan coba lagi besok, atau update per siswa jika mendesak.",
        backgroundColor: Colors.orange, colorText: Colors.white, duration: const Duration(seconds: 5)
      );
      return;
    }

    Get.defaultDialog(
      title: "Update Peringkat Kelas",
      middleText: "Sistem akan menghitung ulang Rata-rata Nilai Akademik untuk ${daftarSiswa.length} siswa.\n\n"
                  "CATATAN: Proses ini HANYA mengupdate Nilai & Peringkat. Data Ekskul/Absensi tidak akan berubah.",
      textConfirm: "Mulai Proses",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _prosesGenerateMassal();
      }
    );
  }

  Future<bool> _checkGenerateQuota() async {
    try {
      final docRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('kelastahunajaran').doc(idKelas);

      final doc = await docRef.get();
      final data = doc.data();
      
      if (data == null) return true; // Dokumen baru, boleh

      final log = data['massGenerateLog'] as Map<String, dynamic>?;
      if (log == null) return true; // Belum pernah generate, boleh

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastDate = log['date'] ?? '';
      final count = log['count'] ?? 0;

      if (lastDate != todayStr) {
        return true; // Hari baru, reset kuota (akan direset saat save)
      }

      if (count >= 2) {
        return false; // Kuota habis hari ini
      }

      return true; // Masih ada kuota
    } catch (e) {
      print("Error check quota: $e");
      return true; // Fail-safe: jika error, izinkan saja agar tidak memblokir user
    }
  }

  // Fungsi Update Kuota (Dipanggil setelah sukses)
  Future<void> _incrementGenerateQuota() async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('kelastahunajaran').doc(idKelas);

      // Gunakan Transaction atau logic sederhana get-set
      // Disini logic sederhana get-set cukup
      final doc = await docRef.get();
      final log = doc.data()?['massGenerateLog'] as Map<String, dynamic>?;
      
      int newCount = 1;
      if (log != null && log['date'] == todayStr) {
        newCount = (log['count'] ?? 0) + 1;
      }

      await docRef.set({
        'massGenerateLog': {
          'date': todayStr,
          'count': newCount,
          'lastUser': configC.infoUser['nama'] // Opsional: Siapa yang klik
        }
      }, SetOptions(merge: true));
      
    } catch (e) {
      print("Gagal update log kuota: $e");
    }
  }

  Future<void> _prosesGenerateMassal() async {
    isMassGenerating.value = true;
    progressGenerate.value = 0.0;
    
    int processed = 0;
    int total = daftarSiswa.length;

    try {
      // Loop setiap siswa
      for (var siswa in daftarSiswa) {
        await _generateRaporSingleLightweight(siswa);
        
        processed++;
        progressGenerate.value = processed / total;
      }
      
      // Update Kuota Penggunaan
      await _incrementGenerateQuota();
      
      Get.snackbar("Selesai", "Data Peringkat Kelas telah diperbarui.");
      
      // Tampilkan hasil ranking langsung
      showRankingDialog(); 

    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: $e");
    } finally {
      isMassGenerating.value = false;
    }
  }

  Future<void> _generateRaporSingleLightweight(SiswaModel siswa) async {
    final semesterId = configC.semesterAktif.value;
    final tahunId = configC.tahunAjaranAktif.value;
    
    // 1. Ambil Nilai Mapel (Hanya ini yang dibaca, HEMAT READS)
    final mapelSnap = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunId)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('daftarsiswa').doc(siswa.uid)
        .collection('semester').doc(semesterId)
        .collection('matapelajaran')
        .get();
        
    // 2. Hitung Rata-rata
    double totalNilai = 0;
    int jumlahMapel = 0;
    
    for (var doc in mapelSnap.docs) {
      // Ambil nilai_akhir, pastikan tipe data aman
      final val = (doc.data()['nilai_akhir'] as num?)?.toDouble() ?? 0.0;
      
      // Hanya hitung mapel yang sudah ada nilainya (> 0)
      if (val > 0) {
        totalNilai += val;
        jumlahMapel++;
      }
    }
    
    // Hindari pembagian dengan nol
    double rataRata = jumlahMapel > 0 ? (totalNilai / jumlahMapel) : 0.0;

    // 3. Simpan/Update Dokumen Rapor (Hanya Field Penting)
    final raporRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunId)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('rapor').doc('${siswa.uid}_$semesterId');

    // Gunakan SetOptions(merge: true) agar data Ekskul/Absensi/Catatan TIDAK HILANG
    await raporRef.set({
      'id': '${siswa.uid}_$semesterId', // Pastikan ID tersimpan
      'idSekolah': configC.idSekolah,
      'idTahunAjaran': tahunId,
      'idKelas': idKelas,
      'semester': semesterId,
      'idSiswa': siswa.uid,
      'namaSiswa': siswa.namaLengkap, // Update nama barangkali ada revisi nama
      'nisn': siswa.nisn,
      'nilaiRataRata': rataRata, // <--- INI INTI DARI GENERATE MASSAL
      // Jangan update 'tanggalGenerate' agar walas tau kapan terakhir generate FULL
      'lastRankingUpdate': FieldValue.serverTimestamp(), 
    }, SetOptions(merge: true));
  }
}