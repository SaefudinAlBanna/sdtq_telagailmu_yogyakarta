// lib/app/modules/rekap_absensi/controllers/rekap_absensi_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/absensi_rekap_model.dart';
import '../../../services/pdf_helper_service.dart';

// [MODEL BARU] Untuk menampung rekap per siswa
class SiswaAbsensiRekap {
  String nama;
  int sakit = 0;
  int izin = 0;
  int alfa = 0;
  SiswaAbsensiRekap({required this.nama});
}

class RekapAbsensiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  final isProcessingPdf = false.obs;
  final RxString scope = "kelas".obs;
  final Rxn<String> selectedKelasId = Rxn<String>();
  final RxList<Map<String, String>> daftarKelas = <Map<String, String>>[].obs;
  
  final RxInt selectedMonth = DateTime.now().month.obs;
  final RxInt selectedYear = DateTime.now().year.obs;
  final RxList<int> availableYears = <int>[].obs;

  final RxList<AbsensiRekapModel> rekapDataHarian = <AbsensiRekapModel>[].obs;
  final RxMap<String, int> totalRekap = {'hadir': 0, 'sakit': 0, 'izin': 0, 'alfa': 0}.obs;
  
  // [STATE BARU] Untuk rekap per siswa
  final RxList<SiswaAbsensiRekap> rekapPerSiswa = <SiswaAbsensiRekap>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeBasedOnScope();
  }

  Future<void> _initializeBasedOnScope() async {
    isLoading.value = true;
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    scope.value = args['scope'] ?? 'kelas';
    
    _generateAvailableYears();

    if (scope.value == 'sekolah') {
      await _fetchDaftarKelas();
      if (daftarKelas.isNotEmpty) {
        selectedKelasId.value = daftarKelas.first['id'];
        await fetchRekapData();
      }
    } else {
      selectedKelasId.value = configC.infoUser['kelasDiampu'];
      await fetchRekapData();
    }
    isLoading.value = false;
  }
  
  void _generateAvailableYears() {
      final ta = configC.tahunAjaranAktif.value;
      if (ta.isEmpty || ta.contains('TIDAK')) {
        availableYears.add(DateTime.now().year);
        return;
      }
      final startYear = int.tryParse(ta.split('-').first);
      if (startYear != null) {
          availableYears.assignAll([startYear, startYear + 1]);
          if (!availableYears.contains(DateTime.now().year)) {
              availableYears.add(DateTime.now().year);
              availableYears.sort();
          }
      } else {
          availableYears.add(DateTime.now().year);
      }
  }

  Future<void> _fetchDaftarKelas() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('kelastahunajaran').orderBy('namaKelas').get();
    
    daftarKelas.assignAll(snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'nama': data['namaKelas']?.toString() ?? 'Tanpa Nama'};
    }).toList());
  }

  Future<void> fetchRekapData() async {
    if (selectedKelasId.value == null) return;
    isLoading.value = true;
    try {
      // 1. Fetch Data Harian (Logika Lama - Tetap Jalan)
      final startDate = DateTime(selectedYear.value, selectedMonth.value, 1);
      final endDate = DateTime(selectedYear.value, selectedMonth.value + 1, 0);

      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('kelastahunajaran').doc(selectedKelasId.value)
          .collection('semester').doc(configC.semesterAktif.value)
          .collection('absensi')
          .where('tanggal', isGreaterThanOrEqualTo: startDate)
          .where('tanggal', isLessThanOrEqualTo: endDate)
          .orderBy('tanggal', descending: true)
          .get();

      rekapDataHarian.assignAll(snapshot.docs.map((doc) => AbsensiRekapModel.fromFirestore(doc)).toList());
      
      // 2. Fetch Data Manual Semester (LOGIKA BARU)
      // Kita perlu mengambil daftar siswa di kelas ini dulu
      final siswaSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('kelastahunajaran').doc(selectedKelasId.value)
          .collection('daftarsiswa')
          .get();
      
      // Map untuk menyimpan data manual: {'uid': {s:1, i:0, a:2}}
      final Map<String, Map<String, int>> manualDataMap = {};

      // Fetch parallel dokumen semester per siswa
      await Future.wait(siswaSnap.docs.map((doc) async {
        final semDoc = await doc.reference.collection('semester').doc(configC.semesterAktif.value).get();
        if (semDoc.exists) {
          final manual = semDoc.data()?['rekapAbsensiManual'];
          if (manual != null) {
            manualDataMap[doc.id] = {
              'sakit': (manual['sakit'] as num?)?.toInt() ?? 0,
              'izin': (manual['izin'] as num?)?.toInt() ?? 0,
              'alfa': (manual['alfa'] as num?)?.toInt() ?? 0, // 'alfa' atau 'alpa' sesuaikan key
            };
          }
        }
      }));

      // 3. Kalkulasi Gabungan
      _calculateTotalRekap(); // Hitung total dari harian dulu
      _calculateRekapPerSiswa(manualDataMap, siswaSnap.docs); // Pass data manual & daftar siswa

    } catch (e) { 
      print("Gagal memuat rekap: $e");
    } finally { isLoading.value = false; }
  }

  // REVISI FUNGSI KALKULASI PER SISWA
  // REVISI FUNGSI KALKULASI (FILTER ONLY S.I.A)
  void _calculateRekapPerSiswa(
    Map<String, Map<String, int>> manualDataMap, 
    List<QueryDocumentSnapshot> daftarSiswaDocs
  ) {
      final Map<String, SiswaAbsensiRekap> siswaMap = {};

      // 1. Masukkan Data dari Harian (Otomatis)
      for (var rekapHarian in rekapDataHarian) {
          rekapHarian.siswa.forEach((uid, data) {
              final status = data['status'] as String?;
              // Hanya proses jika status BUKAN Hadir
              if (status != 'Hadir') {
                  if (!siswaMap.containsKey(uid)) {
                      String nama = data['nama'] ?? 'Tanpa Nama';
                      siswaMap[uid] = SiswaAbsensiRekap(nama: nama);
                  }

                  if (status == 'Sakit') siswaMap[uid]!.sakit++;
                  else if (status == 'Izin') siswaMap[uid]!.izin++;
                  else if (status == 'Alfa') siswaMap[uid]!.alfa++;
              }
          });
      }

      // 2. OVERRIDE dengan Data Manual (Dadakan)
      manualDataMap.forEach((uid, dataManual) {
        // Cek apakah siswa ini punya S/I/A > 0?
        // Jika manualnya 0 semua, kita tidak perlu menambahkannya ke map (kecuali mau menimpa data harian jadi 0)
        
        // Logika: Kita cari nama dulu
        final siswaDoc = daftarSiswaDocs.firstWhere((d) => d.id == uid, orElse: () => daftarSiswaDocs.first); 
        String nama = (siswaDoc.data() as Map<String, dynamic>)['namaLengkap'] ?? 'Siswa';

        // Reset/Timpa data di map dengan data manual
        siswaMap[uid] = SiswaAbsensiRekap(nama: nama); 
        siswaMap[uid]!.sakit = dataManual['sakit']!;
        siswaMap[uid]!.izin = dataManual['izin']!;
        siswaMap[uid]!.alfa = dataManual['alfa']!;
      });

      // 3. [FILTER UTAMA] Hapus siswa yang S, I, dan A nya KOSONG SEMUA
      // Kita konversi ke list, lalu filter.
      final filteredList = siswaMap.values.where((siswa) {
        // Tampilkan hanya jika salah satu ada isinya
        return siswa.sakit > 0 || siswa.izin > 0 || siswa.alfa > 0;
      }).toList();

      // 4. Sortir berdasarkan Nama
      filteredList.sort((a, b) => a.nama.compareTo(b.nama));
      
      // 5. Assign ke Observable
      rekapPerSiswa.assignAll(filteredList);
      
      // 6. Update Total Rekap (Untuk Header)
      int tS = 0, tI = 0, tA = 0;
      // Kita hitung dari filteredList (hasilnya sama saja dengan raw, karena 0 tetap 0)
      for (var s in filteredList) {
        tS += s.sakit; 
        tI += s.izin; 
        tA += s.alfa;
      }
      
      // Update state total agar di grafik/header juga sinkron
      totalRekap['sakit'] = tS; 
      totalRekap['izin'] = tI; 
      totalRekap['alfa'] = tA;
      // Total 'hadir' kita biarkan dari hitungan harian atau diabaikan karena fokusnya ke ketidakhadiran
  }

  void _calculateTotalRekap() {
    int hadir = 0, sakit = 0, izin = 0, alfa = 0;
    for (var rekap in rekapDataHarian) {
      // [PERBAIKAN] Lakukan casting yang aman dari num ke int
      hadir += (rekap.rekap['hadir'] as num?)?.toInt() ?? 0;
      sakit += (rekap.rekap['sakit'] as num?)?.toInt() ?? 0;
      izin += (rekap.rekap['izin'] as num?)?.toInt() ?? 0;
      alfa += (rekap.rekap['alfa'] as num?)?.toInt() ?? 0;
    }
    totalRekap['hadir'] = hadir;
    totalRekap['sakit'] = sakit;
    totalRekap['izin'] = izin;
    totalRekap['alfa'] = alfa;
  }


  //--------------------------------------------------------------
  // REKAP ABSENSI LAMA (SEBELUM FITUR MANUAL)
  //--------------------------------------------------------------

  // Future<void> fetchRekapData() async {
  //   if (selectedKelasId.value == null) return;
  //   isLoading.value = true;
  //   try {
  //     final startDate = DateTime(selectedYear.value, selectedMonth.value, 1);
  //     final endDate = DateTime(selectedYear.value, selectedMonth.value + 1, 0);

  //     final snapshot = await _firestore
  //         .collection('Sekolah').doc(configC.idSekolah)
  //         .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
  //         .collection('kelastahunajaran').doc(selectedKelasId.value)
  //         .collection('semester').doc(configC.semesterAktif.value)
  //         .collection('absensi')
  //         .where('tanggal', isGreaterThanOrEqualTo: startDate)
  //         .where('tanggal', isLessThanOrEqualTo: endDate)
  //         .orderBy('tanggal', descending: true)
  //         .get();

  //     rekapDataHarian.assignAll(snapshot.docs.map((doc) => AbsensiRekapModel.fromFirestore(doc)).toList());
  //     _calculateTotalRekap();
  //     _calculateRekapPerSiswa(); // [BARU] Panggil fungsi kalkulasi per siswa

  //   } catch (e) { 
  //     Get.snackbar("Error", "Gagal memuat rekap: $e"); 
  //     print("Gagal memuat rekap: $e");
  //     } 
    
  //   finally { isLoading.value = false; }
  // }
  
  //// [FUNGSI BARU] Untuk menghitung rekap per siswa
  // void _calculateRekapPerSiswa() {
  //     final Map<String, SiswaAbsensiRekap> siswaMap = {};

  //     for (var rekapHarian in rekapDataHarian) {
  //         rekapHarian.siswa.forEach((uid, data) {
  //             final status = data['status'] as String?;
  //             if (status != 'Hadir') {
  //                 final nama = data['nama'] as String? ?? 'Tanpa Nama';
                  
  //                 // Inisialisasi jika siswa belum ada di map
  //                 if (!siswaMap.containsKey(uid)) {
  //                     siswaMap[uid] = SiswaAbsensiRekap(nama: nama);
  //                 }

  //                 // Tambah counter berdasarkan status
  //                 if (status == 'Sakit') siswaMap[uid]!.sakit++;
  //                 if (status == 'Izin') siswaMap[uid]!.izin++;
  //                 if (status == 'Alfa') siswaMap[uid]!.alfa++;
  //             }
  //         });
  //     }
  //     // Konversi map ke list dan urutkan berdasarkan nama
  //     rekapPerSiswa.assignAll(siswaMap.values.toList()..sort((a,b) => a.nama.compareTo(b.nama)));
  // }

  //--------------------------------------------------------------
  // AKHIR REKAP ABSENSI LAMA
  //--------------------------------------------------------------



  Future<void> exportPdf() async {
    if (rekapDataHarian.isEmpty) {
      Get.snackbar("Peringatan", "Tidak ada data untuk diekspor.");
      return;
    }
    isProcessingPdf.value = true;
    try {
      final doc = pw.Document();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final logoImage = pw.MemoryImage((await rootBundle.load('assets/png/logo.png')).buffer.asUint8List());
      final regularFont = await PdfGoogleFonts.poppinsRegular();
      
      final infoSekolahDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah).get();
      final infoSekolah = infoSekolahDoc.data() ?? {};
      
      final bulan = DateFormat('MMMM', 'id_ID').format(DateTime(0, selectedMonth.value));
      final periode = "$bulan ${selectedYear.value}";

      // [PERBAIKAN KUNCI DI SINI] Logika pengambilan nama kelas yang cerdas
      String namaKelas;
      String namaWaliKelas;

      if (scope.value == 'sekolah') {
        // Logika untuk Pimpinan: cari dari daftar
        namaKelas = daftarKelas.firstWhere((k) => k['id'] == selectedKelasId.value, orElse: () => {'nama': 'N/A'})['nama']!;
        // Karena pimpinan bisa melihat kelas siapa saja, kita coba ambil nama wali kelas dari data absensi
        namaWaliKelas = rekapDataHarian.first.namaWaliKelas ?? 'Tidak Tercatat';
      } else {
        // Logika untuk Wali Kelas: ambil dari ID kelas dan data login
        namaKelas = selectedKelasId.value?.split('-').first ?? 'Kelas Saya';
        namaWaliKelas = configC.infoUser['alias'] ?? configC.infoUser['nama'] ?? 'Wali Kelas';
      }
      // --- AKHIR PERBAIKAN ---

      final content = await PdfHelperService.buildAbsensiReportContent(
        rekapDataHarian: rekapDataHarian,
        totalRekap: totalRekap,
        rekapPerSiswa: rekapPerSiswa,
      );

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => PdfHelperService.buildHeaderA4(infoSekolah: infoSekolah, logoImage: logoImage, boldFont: boldFont, regularFont: regularFont,),
          footer: (context) => PdfHelperService.buildFooter(context, regularFont),
          build: (context) => [
            pw.SizedBox(height: 20),
            pw.Text("Laporan Rekapitulasi Absensi", style: pw.TextStyle(font: boldFont, fontSize: 16), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 12),
            pw.Table(
              columnWidths: { 0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(2) },
              children: [
                pw.TableRow(children: [ pw.Text("Kelas", style: pw.TextStyle(font: boldFont)), pw.Text(": $namaKelas") ]),
                pw.TableRow(children: [ pw.Text("Wali Kelas", style: pw.TextStyle(font: boldFont)), pw.Text(": $namaWaliKelas") ]),
                pw.TableRow(children: [ pw.Text("Periode", style: pw.TextStyle(font: boldFont)), pw.Text(": $periode") ]),
              ]
            ),
            pw.SizedBox(height: 20),
            ...content,
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'rekap_absensi_${namaKelas}_${selectedYear.value}-${selectedMonth.value}.pdf'
      );

    } catch (e) {
      Get.snackbar("Error", "Gagal membuat PDF: $e");
    } finally {
      isProcessingPdf.value = false;
    }
  }
}