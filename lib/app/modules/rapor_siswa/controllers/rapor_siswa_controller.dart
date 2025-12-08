// lib/app/modules/rapor_siswa/controllers/rapor_siswa_controller.dart (SUDAH DIPERBAIKI)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../services/pdf_helper_service.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/rapor_model.dart';
import '../../../models/siswa_model.dart';

class RaporSiswaController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final RxBool isLoading = true.obs;
  final RxBool isGenerating = false.obs;
  final Rxn<RaporModel> raporData = Rxn<RaporModel>();

  final RxBool isPrinting = false.obs;
  final RxBool isSharing = false.obs;
  final RxBool isUpdating = false.obs;

  final RxString namaKepalaSekolah = ".........................".obs;

  late SiswaModel siswa;
  late String kelasId, semesterId, tahunAjaranId;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _fetchInfoSekolah(); // Panggil di init
  }
  
  void _initializeData() {
    isLoading.value = true;
    try {
      final args = Get.arguments as Map<String, dynamic>? ?? {};
      siswa = args['siswa'];
      kelasId = args['kelasId'];
      semesterId = args['semesterId'];
      tahunAjaranId = configC.tahunAjaranAktif.value;

      _loadExistingRapor(); 
      
      if (kelasId.isEmpty || semesterId.isEmpty) {
        throw Exception("ID Kelas atau Semester tidak valid.");
      }

    } catch (e) {
      Get.snackbar("Error Kritis", "Gagal memuat data awal rapor: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchInfoSekolah() async {
    try {
      final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah).get();
      final data = doc.data();
      if (data != null) {
        // Update value .obs
        namaKepalaSekolah.value = data['kepalasekolah'] ?? "Kepala Sekolah";
      }
    } catch (e) {
      print("Error fetch info sekolah: $e");
    }
  }


  void confirmAndUpdateRapor() {
    Get.defaultDialog(
      title: "Perbarui Rapor?",
      middleText: "Anda yakin ingin memperbarui rapor dengan data terbaru? Semua nilai, absensi, dan catatan akan diambil ulang dari sistem. Tindakan ini tidak dapat dibatalkan.",
      textConfirm: "Ya, Perbarui",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back(); // Tutup dialog
        // Panggil fungsi generateRapor yang sudah ada, tapi dengan state loading yang berbeda
        _updateRapor(); 
      },
    );
  }

  Future<void> _updateRapor() async {
    isUpdating.value = true;
    await generateRapor(); // Kita gunakan kembali mesin utama kita
    isUpdating.value = false;
  }

  Future<void> _loadExistingRapor() async {
    final raporId = '${siswa.uid}_$semesterId';
    final raporRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranId)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('rapor').doc(raporId);

    final doc = await raporRef.get();
    if (doc.exists) {
      raporData.value = RaporModel.fromFirestore(doc);
    }
  }

  Future<void> toggleShareRapor() async {
    if (raporData.value == null) return;

    isSharing.value = true;
    try {
      final bool newStatus = !raporData.value!.isShared;
      final raporId = raporData.value!.id;

      final raporRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranId)
          .collection('kelastahunajaran').doc(kelasId)
          .collection('rapor').doc(raporId);

      await raporRef.update({'isShared': newStatus});

      // Update state lokal
      raporData.value = raporData.value!.copyWith(isShared: newStatus);

      if (newStatus) {
        // await NotifikasiService.kirimNotifikasi(...);
      }
      Get.snackbar("Berhasil", newStatus ? "Rapor telah dibagikan." : "Pembagian rapor dibatalkan.");

    } catch (e) { Get.snackbar("Error", "Gagal mengubah status: $e"); } 
    finally { isSharing.value = false; }
  }
  
 Future<void> generateRapor() async {
    isGenerating.value = true;
    try {
      // 1. Ambil Info Sekolah dulu agar nama KS update
      await _fetchInfoSekolah();

      final results = await Future.wait([
        _fetchNilaiAkademik(),
        _fetchRekapAbsensi(),
        _fetchDataPengembanganDiri(),
        _fetchCatatanWaliKelas(),
      ]);

      final List<NilaiMapelRapor> daftarNilai = results[0] as List<NilaiMapelRapor>;
      final RekapAbsensi rekapAbsensi = results[1] as RekapAbsensi;
      final Map<String, dynamic> dataPengembangan = results[2] as Map<String, dynamic>;
      final String namaOrtu = dataPengembangan['namaOrangTua'] as String;
      final String catatanWalas = results[3] as String;
      final DataHalaqahRapor dataHalaqah = dataPengembangan['halaqah'] as DataHalaqahRapor;
      final List<DataEkskulRapor> daftarEkskul = dataPengembangan['ekskul'] as List<DataEkskulRapor>;

      double totalNilai = 0;
      int jumlahMapel = 0;
      for (var n in daftarNilai) {
        if (n.nilaiAkhir > 0) {
          totalNilai += n.nilaiAkhir;
          jumlahMapel++;
        }
      }
      double rataRata = jumlahMapel > 0 ? (totalNilai / jumlahMapel) : 0.0;

      final RaporModel hasilRapor = RaporModel(
        id: '${siswa.uid}_$semesterId',
        idSekolah: configC.idSekolah,
        idTahunAjaran: tahunAjaranId,
        idKelas: kelasId,
        semester: semesterId,
        tanggalGenerate: DateTime.now(),
        idWaliKelas: configC.infoUser['uid'],
        namaWaliKelas: configC.infoUser['alias'] ?? configC.infoUser['nama'],
        idSiswa: siswa.uid,
        namaSiswa: siswa.namaLengkap,
        nisn: siswa.nisn,
        namaOrangTua: namaOrtu,
        daftarNilaiMapel: daftarNilai,
        dataHalaqah: dataHalaqah,
        daftarEkskul: daftarEkskul,
        rekapAbsensi: rekapAbsensi,
        // catatanWaliKelas: "Terus tingkatkan semangat belajar ya sholih-sholihah, dan jangan ragu untuk bertanya.",
        catatanWaliKelas: catatanWalas,
        nilaiRataRata: rataRata,
      );
      
      await _saveRaporToFirestore(hasilRapor);
      raporData.value = hasilRapor; // Update state UI
      Get.snackbar("Berhasil", "Rapor berhasil digenerate.");
      
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat rapor: ${e.toString()}");
    } finally {
      isGenerating.value = false;
    }
  }

  Future<String> _fetchCatatanWaliKelas() async {
    try {
      final semesterDocRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranId)
          .collection('kelastahunajaran').doc(kelasId)
          .collection('daftarsiswa').doc(siswa.uid)
          .collection('semester').doc(semesterId);

      final doc = await semesterDocRef.get();

      if (doc.exists && doc.data() != null) {
        final catatan = doc.data()!['catatanWaliKelas'] as String?;
        if (catatan != null && catatan.isNotEmpty) {
          return catatan;
        }
      }
      // Jika dokumen/field tidak ada, atau field kosong, kembalikan placeholder
      return "Terus tingkatkan semangat belajar ya sholih-sholihah, dan jangan ragu untuk bertanya.";
    } catch (e) {
      print("### Error fetching catatan walas: $e");
      return "Gagal memuat catatan."; // Fallback jika terjadi error
    }
  }

  // --- FUNGSI-FUNGSI PEMBANTU (Tidak ada perubahan di sini) ---
  Future<List<NilaiMapelRapor>> _fetchNilaiAkademik() async {
    final snapshot = await _firestore
      .collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaranId)
      .collection('kelastahunajaran').doc(kelasId)
      .collection('daftarsiswa').doc(siswa.uid)
      .collection('semester').doc(semesterId)
      .collection('matapelajaran')
      .get();
      
    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return NilaiMapelRapor(
        idMapel: doc.id,
        namaMapel: data['namaMapel'] ?? 'Tanpa Nama',
        namaGuru: data['namaGuru'] ?? 'N/A',
        nilaiAkhir: (data['nilai_akhir'] as num?)?.toDouble() ?? 0.0,
        deskripsiCapaian: data['deskripsi_capaian'] ?? 'Capaian belum diisi.',
      );
    }).toList();
  }

  Future<RekapAbsensi> _fetchRekapAbsensi() async {
    // 1. Controller ini menunjuk ke path yang SANGAT SPESIFIK:
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranId)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('daftarsiswa').doc(siswa.uid) // <-- Hanya untuk siswa ini
        .collection('semester').doc(semesterId)
        .collection('absensi_siswa') // <-- Koleksi absensi individual
        .get();

    if (snapshot.docs.isEmpty) return RekapAbsensi(sakit: 0, izin: 0, alpa: 0);

    // 2. Ia lalu menghitung total S, I, A dari semua dokumen di koleksi tersebut.
    int sakit = 0, izin = 0, alpa = 0;
    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] as String?;
      if (status == 'Sakit') sakit++;
      else if (status == 'Izin') izin++;
      else if (status == 'Alpa') alpa++;
    }

    return RekapAbsensi(sakit: sakit, izin: izin, alpa: alpa);
  }

  Future<Map<String, dynamic>> _fetchDataPengembanganDiri() async {
    // 1. Ambil dokumen utama siswa (ini sudah kita lakukan dan ini adalah langkah KUNCI)
    final siswaDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid).get();
    final siswaData = siswaDoc.data() ?? {};
    final String namaOrtu = siswaData['namaAyah'] ?? siswaData['namaIbu'] ?? 'Orang Tua/Wali';

    // --- Logika Halaqah (tidak berubah, sudah benar) ---
    final tingkatanMap = siswaData['halaqahTingkatan'] as Map<String, dynamic>? ?? {};
    final setoranTerakhirMap = siswaData['setoranTerakhirHalaqah'] as Map<String, dynamic>? ?? {};
    final tugasMap = setoranTerakhirMap['tugas'] as Map<String, dynamic>? ?? {};
    final raporHalaqahMap = siswaData['raporHalaqahSemester'] as Map<String, dynamic>? ?? {};
    final dataSemesterIni = raporHalaqahMap[semesterId] as Map<String, dynamic>? ?? {};

    final String tingkatan = tingkatanMap['nama'] ?? 'Belum ada tingkatan';
    String pencapaian = "Sabak: ${tugasMap['sabak'] ?? '-'} | Sabqi: ${tugasMap['sabqi'] ?? '-'}";
    if (pencapaian == "Sabak: - | Sabqi: -") pencapaian = "Belum ada setoran terakhir.";

    final dataHalaqah = DataHalaqahRapor(
      tingkatan: tingkatan,
      pencapaian: pencapaian,
      nilaiAkhir: dataSemesterIni['nilai'] as int?,
      catatan: dataSemesterIni['catatan'] as String? ?? 'Belum ada catatan akhir dari pengampu.',
    );

    // --- [LOGIKA FINAL EKSKUL - SANGAT EFISIEN] ---
    List<DataEkskulRapor> daftarEkskul = [];
    try {
      // a. Baca map 'ekskulTerdaftar' langsung dari data siswa yang sudah kita ambil
      final ekskulTerdaftarMap = siswaData['ekskulTerdaftar'] as Map<String, dynamic>? ?? {};

      // b. Ambil semua ID ekskul dari keys map tersebut
      final List<String> idIkutEkskul = ekskulTerdaftarMap.keys.toList();

      // c. Jika siswa terdaftar di ekskul, ambil detailnya
      if (idIkutEkskul.isNotEmpty) {
        final ekskulDetailsSnap = await _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('ekskul_ditawarkan')
            .where(FieldPath.documentId, whereIn: idIkutEkskul)
            .get();

        daftarEkskul = ekskulDetailsSnap.docs.map((doc) {
          final data = doc.data();
          return DataEkskulRapor(
            namaEkskul: data['namaEkskul'] ?? 'Tanpa Nama',
            nilai: 'Baik', // Placeholder
            catatan: 'Aktif mengikuti kegiatan.', // Placeholder
          );
        }).toList();
      }
    } catch (e) {
      print("### Error fetching ekskul data from denormalized field: $e");
      // Biarkan daftarEkskul kosong jika terjadi error
    }
    // --- [AKHIR LOGIKA FINAL EKSKUL] ---

    return {
      'halaqah': dataHalaqah,
      'ekskul': daftarEkskul,
      'namaOrangTua': namaOrtu,
    };
  }

  Future<void> exportRaporPdf() async {
    if (raporData.value == null) {
      Get.snackbar("Peringatan", "Data rapor belum tersedia untuk dicetak.");
      return;
    }
    isPrinting.value = true;
    try {
      final doc = pw.Document();
      
      // 1. Muat semua aset (Font & Gambar)
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final regularFont = await PdfGoogleFonts.poppinsRegular();
      final italicFont = await PdfGoogleFonts.poppinsItalic();
      final logoImage = pw.MemoryImage((await rootBundle.load('assets/png/logo.png')).buffer.asUint8List());
      
      // 2. Ambil data info sekolah
      final infoSekolahDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah).get();
      final infoSekolah = infoSekolahDoc.data() ?? {};
      
      // 3. Pastikan nama Kepala Sekolah sudah terambil (Safety Check)
      if (namaKepalaSekolah.value == ".........................") {
         await _fetchInfoSekolah();
      }

      // 4. Ambil Widget Konten (Tabel Nilai, dll) - TANPA TANDA TANGAN
      final contentWidgets = await PdfHelperService.buildRaporDigitalContent(
        rapor: raporData.value!,
        regularFont: regularFont,
        boldFont: boldFont,
        italicFont: italicFont,
      );

      // 5. Rakit Dokumen PDF dengan FOOTER SPESIAL
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          
          // HEADER: Muncul di setiap halaman
          header: (context) => PdfHelperService.buildHeaderA4(
            infoSekolah: infoSekolah, logoImage: logoImage, 
            boldFont: boldFont, regularFont: regularFont
          ),
          
          // FOOTER: Logika "Tanda Tangan Paling Bawah"
          footer: (context) {
            return pw.Column(
              mainAxisSize: pw.MainAxisSize.min, // Agar tidak memakan space kosong
              children: [
                // LOGIKA: Jika ini halaman terakhir, tampilkan Tanda Tangan
                if (context.pageNumber == context.pagesCount) ...[
                   pw.SizedBox(height: 30), // Spasi pemisah dari konten rapor
                   PdfHelperService.buildSignatureFooter(
                     rapor: raporData.value!,
                     namaKepalaSekolah: namaKepalaSekolah.value, // Ambil dari .obs
                     regularFont: regularFont,
                     boldFont: boldFont,
                   ),
                   pw.SizedBox(height: 20), // Spasi kecil ke nomor halaman
                ],
                
                // Nomor Halaman (Muncul di semua halaman)
                PdfHelperService.buildFooter(context, regularFont),
              ]
            );
          },
          
          // KONTEN UTAMA
          build: (context) => contentWidgets,
        ),
      );

      // 6. Bagikan PDF
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'rapor_${raporData.value!.namaSiswa}_${raporData.value!.idTahunAjaran}.pdf'
      );

    } catch (e) {
      Get.snackbar("Error", "Gagal membuat PDF: $e");
      print("PDF ERROR: $e");
    } finally {
      isPrinting.value = false;
    }
  }


  Future<void> _saveRaporToFirestore(RaporModel rapor) async {
    final raporRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranId)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('rapor').doc(rapor.id);
        
    await raporRef.set(rapor.toJson());
  }
}