// lib/app/controllers/dashboard_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';
// --- [PERBAIKAN KUNCI] Import dari lokasi yang BENAR ---
import 'package:sdtq_telagailmu_yogyakarta/app/models/carousel_item_model.dart';

class DashboardController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Properti Carousel ---
  final RxBool isCarouselLoading = true.obs;
  final RxList<CarouselItemModel> daftarCarousel = <CarouselItemModel>[].obs;

  // --- SEMUA LOGIKA OTORISASI & NAVIGASI DASHBOARD PINDAH KE SINI ---

  bool get isPimpinan {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final role = user['role'] ?? '';
    final tugas = List<String>.from(user['tugas'] ?? []);
    final peranSistem = user['peranSistem'] ?? '';
    return ['Kepala Sekolah', 'Koordinator Kurikulum'].contains(role) || 
           tugas.contains('Koordinator Kurikulum') || 
           peranSistem == 'superadmin';
  }

  bool get kepalaSekolah {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final role = user['role'] ?? '';
    return ['Kepala Sekolah'].contains(role);
  }

  bool get canManageHalaqah {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final String peranSistem = user['peranSistem'] ?? '';
    final String role = user['role'] ?? '';
    final List<String> tugas = List<String>.from(user['tugas'] ?? []);
    final bool hasRequiredRole = ['Kepala Sekolah', 'TU', 'Tata Usaha', 'Admin'].contains(role);
    final bool hasRequiredTugas = tugas.any((t) => ['Koordinator Halaqah Ikhwan', 'Koordinator Halaqah Akhwat', 'Koordinator Kurikulum'].contains(t));
    return peranSistem == 'superadmin' || hasRequiredRole || hasRequiredTugas;
  }

  bool get isPengampuHalaqah {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    return user.containsKey('grupHalaqahDiampu') && (user['grupHalaqahDiampu'] as Map).isNotEmpty;
  }

  bool get canManageEkskul {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final String peranSistem = user['peranSistem'] ?? '';
    final String role = user['role'] ?? '';
    final List<String> tugas = List<String>.from(user['tugas'] ?? []);
    final bool hasRequiredRole = ['Kepala Sekolah', 'TU', 'Tata Usaha'].contains(role);
    final bool hasRequiredTugas = tugas.contains('Koordinator Kurikulum');
    return peranSistem == 'superadmin' || hasRequiredRole || hasRequiredTugas;
  }

  bool get canManageKbm {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final String peranSistem = user['peranSistem'] ?? '';
    final String role = user['role'] ?? '';
    // Untuk saat ini, kita samakan dengan Pimpinan
    return ['Kepala Sekolah', 'Koordinator Kurikulum'].contains(role) || peranSistem == 'superadmin';
  }

   @override
  void onReady() {
    super.onReady();
    // Gunakan listener agar carousel auto-refresh jika config berubah (misal setelah login)
    ever(configC.status, (AppStatus status) {
      if (status == AppStatus.authenticated) {
        fetchCarouselData();
      }
    });
    if (configC.status.value == AppStatus.authenticated) {
      fetchCarouselData();
    }
  }

  void showPesanEditorDialog() {
    // Ambil data awal dari ConfigController untuk mengisi form
    final Map<String, dynamic> config = configC.konfigurasiDashboard;
    final _pesanPimpinanC = TextEditingController(text: config['pesanPimpinan']?['pesan'] ?? '');
    final _pesanLiburC = TextEditingController(text: config['pesanDefaultLibur'] ?? '');
    final _pesanSelesaiC = TextEditingController(text: config['pesanDefaultSetelahKBM'] ?? '');
    
    // State khusus untuk dialog ini
    final Rx<DateTime> berlakuHingga = Rx<DateTime>((config['pesanPimpinan']?['berlakuHingga'] as Timestamp?)?.toDate() ?? DateTime.now());
    final RxBool isMenyimpan = false.obs;

    Get.defaultDialog(
      title: "Edit Pesan Dasbor",
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      content: SizedBox(
        width: Get.width,
        height: Get.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pesan Pengumuman Penting (Prioritas #0)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _pesanPimpinanC,
                decoration: const InputDecoration(labelText: 'Isi Pesan', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Obx(() => ListTile(
                title: const Text("Berlaku Sampai"),
                subtitle: Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(berlakuHingga.value)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: Get.context!,
                    initialDate: berlakuHingga.value,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    berlakuHingga.value = DateTime(picked.year, picked.month, picked.day, 23, 59, 59); // Set ke akhir hari
                  }
                },
              )),
              const Divider(height: 24),

              const Text("Pesan Default Saat Libur (Prioritas #2)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _pesanLiburC,
                decoration: const InputDecoration(labelText: 'Isi Pesan Libur', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const Divider(height: 24),
              
              const Text("Pesan Default Setelah KBM Usai (Prioritas #6)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _pesanSelesaiC,
                decoration: const InputDecoration(labelText: 'Isi Pesan Selesai KBM', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isMenyimpan.value ? null : () {
          _simpanKonfigurasiDashboard(
            pesanPimpinan: _pesanPimpinanC.text,
            berlakuHingga: berlakuHingga.value,
            pesanLibur: _pesanLiburC.text,
            pesanSelesai: _pesanSelesaiC.text,
            isSaving: isMenyimpan,
          );
        },
        child: Text(isMenyimpan.value ? "Menyimpan..." : "Simpan Perubahan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  Future<void> _simpanKonfigurasiDashboard({
    required String pesanPimpinan,
    required DateTime berlakuHingga,
    required String pesanLibur,
    required String pesanSelesai,
    required RxBool isSaving,
  }) async {
    isSaving.value = true;
    try {
      final ref = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('pengaturan').doc('konfigurasi_dashboard');

      await ref.set({
        'pesanPimpinan': {
          'pesan': pesanPimpinan,
          'berlakuHingga': Timestamp.fromDate(berlakuHingga),
        },
        'pesanDefaultLibur': pesanLibur,
        'pesanDefaultSetelahKBM': pesanSelesai,
      }, SetOptions(merge: true));

      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "Pesan dasbor berhasil diperbarui.");
      
      // Sinkronkan ulang config & carousel untuk refresh instan
      await configC.reloadKonfigurasiDashboard();
      await fetchCarouselData();

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan perubahan: $e");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> fetchCarouselData() async {
    isCarouselLoading.value = true;
    try {
      final now = DateTime.now();
      final todayWithoutTime = DateTime(now.year, now.month, now.day);
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final String semester = configC.semesterAktif.value;
      final String namaHari = DateFormat('EEEE', 'id_ID').format(now);

      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
        daftarCarousel.clear(); isCarouselLoading.value = false; return;
      }

      // --- [Prioritas #0: Pesan Pimpinan] ---
      final pesanPimpinan = configC.konfigurasiDashboard['pesanPimpinan'] as Map<String, dynamic>?;
      if (pesanPimpinan != null) {
        final berlakuHingga = (pesanPimpinan['berlakuHingga'] as Timestamp?)?.toDate();
        if (berlakuHingga != null && now.isBefore(berlakuHingga)) {
          daftarCarousel.assignAll([ CarouselItemModel( namaKelas: "Semua Staf & Guru", tipe: CarouselContentType.Prioritas, judul: "PENGUMUMAN PENTING", isi: pesanPimpinan['pesan'] as String? ?? '', ikon: Icons.campaign_rounded, warna: Colors.red.shade700) ]);
          isCarouselLoading.value = false; return;
        }
      }

      // --- [Prioritas #1: Kalender Akademik] ---
      final kalenderSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('kalender_akademik').where('tanggalMulai', isLessThanOrEqualTo: now).get();
      for (var doc in kalenderSnap.docs) {
        final data = doc.data();
        final tglSelesai = (data['tanggalSelesai'] as Timestamp).toDate();
        if (todayWithoutTime.isBefore(tglSelesai.add(const Duration(days: 1)))) {
          final isLibur = data['isLibur'] as bool? ?? false;
          // --- [PERBAIKAN WARNA] ---
          daftarCarousel.assignAll([ CarouselItemModel( namaKelas: "Info Sekolah", 
          tipe: CarouselContentType.Info, judul: isLibur ? "HARI LIBUR" : "INFO KEGIATAN", 
          isi: data['namaKegiatan'] as String? ?? 'Tanpa Judul', 
          ikon: isLibur ? Icons.weekend_rounded : Icons.event_note_rounded, 
          warna: isLibur ? Colors.red.shade400 : Colors.teal.shade700) ]);
          isCarouselLoading.value = false; return;
        }
      }

      // --- [Prioritas #2: Hari Libur (Sabtu/Minggu)] ---
      if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
        final String pesanLiburDariDb = configC.konfigurasiDashboard['pesanDefaultLibur'] as String? ?? "";
        final String pesanLiburFinal = pesanLiburDariDb.trim().isEmpty ? 
        "Tetap semangat belajar dan muroja'ah yaa.." : pesanLiburDariDb;
        // --- [PERBAIKAN WARNA] ---
        daftarCarousel.assignAll([ CarouselItemModel( namaKelas: "Info Sekolah", tipe: CarouselContentType.Default, 
        judul: "SELAMAT BERAKHIR PEKAN", isi: pesanLiburFinal, ikon: Icons.beach_access_rounded, 
        warna: Colors.blue.shade700) ]);
        isCarouselLoading.value = false; return;
      }

      // --- [Prioritas #3-#6: Logika KBM Hari Aktif (Dengan Arsitektur Peran)] ---
      final List<CarouselItemModel> carouselItems = [];
      final jadwalSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('jadwalkelas').get();
      final List<String> daftarKelas = jadwalSnap.docs.map((doc) => doc.id).toList()..sort();
      final nowTime = DateFormat("HH:mm").parse(DateFormat("HH:mm").format(now));

      // JALUR PIMPINAN: Mengambil data absensi
      if (isPimpinan) {
        final absensiSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('kelastahunajaran').get()
            .then((snap) => Future.wait(snap.docs.map((doc) => doc.reference.collection('semester').doc(semester).collection('absensi').doc(DateFormat('yyyy-MM-dd').format(now)).get())));
      final Map<String, Map<String, dynamic>?> petaAbsensi = {
        for (var doc in absensiSnap)
          if (doc.exists)
            doc.reference.parent.parent!.parent.id: doc.data() as Map<String, dynamic>?
      };

        for (String idKelas in daftarKelas) {
          final jadwalDoc = jadwalSnap.docs.firstWhere((doc) => doc.id == idKelas);
          final jadwalData = jadwalDoc.data() as Map<String, dynamic>;
          final listSlot = (jadwalData[namaHari] ?? jadwalData[namaHari.toLowerCase()]) as List? ?? [];
          listSlot.sort((a,b) => (a['jam'] as String).compareTo(b['jam'] as String));

          Map<String, dynamic>? slotBerlangsung;
          Map<String, dynamic>? slotBerikutnya;
          for (var slot in listSlot) { try { final timeParts = (slot['jam'] as String? ?? "00:00-00:00").split('-'); final startTime = DateFormat("HH:mm").parse(timeParts[0].trim()); final endTime = DateFormat("HH:mm").parse(timeParts[1].trim()); if (nowTime.isAtSameMomentAs(startTime) || (nowTime.isAfter(startTime) && nowTime.isBefore(endTime))) { slotBerlangsung = slot; break; } if (nowTime.isBefore(startTime) && slotBerikutnya == null) { slotBerikutnya = slot; } } catch(e) {} }

          CarouselItemModel itemForThisClass;
          if (slotBerlangsung != null) {
            itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.KBM, judul: "Saat Ini Berlangsung", isi: slotBerlangsung['namaMapel'] ?? 'N/A', subJudul: "Oleh: ${slotBerlangsung['namaGuru'] ?? 'N/A'}", ikon: Icons.school_rounded, warna: Colors.indigo.shade700);
          } else if (slotBerikutnya != null) {
            itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.KBM, judul: "Pelajaran Berikutnya", isi: slotBerikutnya['namaMapel'] ?? 'N/A', subJudul: "Jam: ${slotBerikutnya['jam'] ?? 'N/A'}", ikon: Icons.update_rounded, warna: Colors.blue.shade700);
          } else {
            final absensiData = petaAbsensi[idKelas];
            if (absensiData != null && absensiData['rekap'] != null) {
              final rekap = absensiData['rekap'];
              itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.Info, judul: "Kehadiran Hari Ini", isi: "H:${rekap['hadir']??0}, S:${rekap['sakit']??0}, I:${rekap['izin']??0}, A:${rekap['alfa']??0}", ikon: Icons.checklist_rtl_rounded, warna: Colors.green.shade800);
            } else {
              final String pesanSelesaiDariDb = configC.konfigurasiDashboard['pesanDefaultSetelahKBM'] as String? ?? ""; 
              final String pesanSelesaiFinal = pesanSelesaiDariDb.trim().isEmpty ? 
              "Aktivitas belajar telah usai." : pesanSelesaiDariDb;
              // --- [PERBAIKAN WARNA] ---
              itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, 
              tipe: CarouselContentType.Default, judul: "KBM Selesai", isi: pesanSelesaiFinal, 
              ikon: Icons.check_circle_outline_rounded, warna: Colors.blueGrey.shade700);
            }
          }
          carouselItems.add(itemForThisClass);
        }
      } 
      // JALUR GURU BIASA: Tanpa data absensi
      else {
        for (String idKelas in daftarKelas) {
          final jadwalDoc = jadwalSnap.docs.firstWhere((doc) => doc.id == idKelas);
          final jadwalData = jadwalDoc.data() as Map<String, dynamic>;
          final listSlot = (jadwalData[namaHari] ?? jadwalData[namaHari.toLowerCase()]) as List? ?? [];
          listSlot.sort((a,b) => (a['jam'] as String).compareTo(b['jam'] as String));

          Map<String, dynamic>? slotBerlangsung;
          Map<String, dynamic>? slotBerikutnya;
          for (var slot in listSlot) { try { final timeParts = (slot['jam'] as String? ?? "00:00-00:00").split('-'); final startTime = DateFormat("HH:mm").parse(timeParts[0].trim()); final endTime = DateFormat("HH:mm").parse(timeParts[1].trim()); if (nowTime.isAtSameMomentAs(startTime) || (nowTime.isAfter(startTime) && nowTime.isBefore(endTime))) { slotBerlangsung = slot; break; } if (nowTime.isBefore(startTime) && slotBerikutnya == null) { slotBerikutnya = slot; } } catch(e) {} }

          CarouselItemModel itemForThisClass;
          if (slotBerlangsung != null) {
            itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.KBM, judul: "Saat Ini Berlangsung", isi: slotBerlangsung['namaMapel'] ?? 'N/A', subJudul: "Oleh: ${slotBerlangsung['namaGuru'] ?? 'N/A'}", ikon: Icons.school_rounded, warna: Colors.indigo.shade700);
          } else if (slotBerikutnya != null) {
            itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.KBM, judul: "Pelajaran Berikutnya", isi: slotBerikutnya['namaMapel'] ?? 'N/A', subJudul: "Jam: ${slotBerikutnya['jam'] ?? 'N/A'}", ikon: Icons.update_rounded, warna: Colors.blue.shade700);
          } else {
            final String pesanSelesaiDariDb = configC.konfigurasiDashboard['pesanDefaultSetelahKBM'] as String? ?? ""; final String pesanSelesaiFinal = pesanSelesaiDariDb.trim().isEmpty ? "Aktivitas belajar telah usai." : pesanSelesaiDariDb;
            itemForThisClass = CarouselItemModel(namaKelas: idKelas.split('-').first, tipe: CarouselContentType.Default, judul: "KBM Selesai", isi: pesanSelesaiFinal, ikon: Icons.check_circle_outline_rounded, warna: Colors.grey.shade700);
          }
          carouselItems.add(itemForThisClass);
        }
      }
      daftarCarousel.assignAll(carouselItems);

    } catch (e) {
      print("### Gagal membangun carousel: $e");
      daftarCarousel.assignAll([ CarouselItemModel(namaKelas: "Error", tipe: CarouselContentType.Default, judul: "GAGAL MEMUAT DATA", isi: "Silakan muat ulang halaman.", ikon: Icons.error_outline_rounded, warna: Colors.grey.shade700) ]);
    } finally {
      isCarouselLoading.value = false;
    }
  }


  void goToEkskulPendaftaran() => Get.toNamed(Routes.EKSKUL_PENDAFTARAN_MANAGEMENT);
  
  void goToHalaqahManagement() => Get.toNamed(Routes.HALAQAH_MANAGEMENT);
  void goToHalaqahDashboard() => Get.toNamed(Routes.HALAQAH_DASHBOARD_PENGAMPU);
  
  // Fungsi ini sekarang akan mengirim argumen dengan benar
  void goToRekapAbsensiSekolah() {
    Get.toNamed(Routes.REKAP_ABSENSI, arguments: {'scope': 'sekolah'});
  }

  void goToAturGuruPengganti() {
    Get.toNamed(Routes.ATUR_GURU_PENGGANTI);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamInfoDashboard() {
    final String tahunAjaran = configC.tahunAjaranAktif.value;
    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
      return const Stream.empty();
    }
    return _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('info_sekolah')
        .orderBy('timestamp', descending: true)
        .limit(5) // Ambil hanya 5 terbaru
        .snapshots();
  }
}