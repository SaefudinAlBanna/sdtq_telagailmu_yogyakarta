import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PemberianNilaiHalaqohController extends GetxController {
  // --- State Observables ---
  final RxString keteranganHalaqoh = "".obs;
  final RxBool isLoading = false.obs;
  final RxString selectedSuratSabaq = ''.obs;
  final RxString selectedNilaiSabaq = ''.obs;
  final RxString selectedSuratSabqi = ''.obs;
  final RxString selectedNilaiSabqi = ''.obs;
  final RxString selectedSuratManzil = ''.obs;
  final RxString selectedNilaiManzil = ''.obs;
  final RxString selectedNilaiTugas = ''.obs;

  // --- Text Editing Controllers ---
  late TextEditingController sabaqC;
  late TextEditingController sabqiC;
  late TextEditingController manzilC;
  late TextEditingController tugasTambahanC;

  // --- Firebase & Data ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> dataArgs = {};
  static const String _defaultIdSekolah = 'P9984539';

  // --- Getters ---
  String get _currentUserId => _auth.currentUser!.uid;
  String get _currentUserEmail => _auth.currentUser!.email!;
  String get _idSekolah => dataArgs['id_sekolah'] ?? _defaultIdSekolah;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is Map<String, dynamic>) {
      dataArgs = arguments;
    } else {
      dataArgs = {};
      Get.snackbar("Error", "Data navigasi tidak valid.", backgroundColor: Colors.red);
    }
    sabaqC = TextEditingController();
    sabqiC = TextEditingController();
    manzilC = TextEditingController();
    tugasTambahanC = TextEditingController();
  }

  void onChangeKeterangan(String? catatan) {
    if (catatan != null) {
      keteranganHalaqoh.value = catatan;
    }
  }

  // Future<String?> ambilDataAlHusna() async {
  //   if (dataArgs.isEmpty || dataArgs['tahunajaran'] == null) {
  //     return "Data siswa tidak lengkap";
  //   }
  //   String idTahunAjaranRaw = dataArgs['tahunajaran'];
  //   String idTahunAjaran = idTahunAjaranRaw.replaceAll("/", "-");
  //   try {
  //     QuerySnapshot<Map<String, dynamic>> snapSemesterSiswa = await _firestore
  //         .collection('Sekolah').doc(_idSekolah)
  //         .collection('tahunajaran').doc(idTahunAjaran)
  //         .collection('kelompokmengaji').doc(dataArgs['fase'])
  //         .collection('pengampu').doc(dataArgs['namapengampu'])
  //         .collection('daftarsiswa').doc(dataArgs['nisn'])
  //         .collection('semester')
  //         .limit(1)
  //         .get();
  //     if (snapSemesterSiswa.docs.isNotEmpty) {
  //       Map<String, dynamic> dataSemester = snapSemesterSiswa.docs.first.data();
  //       return dataSemester['alhusna'] as String? ?? "Belum diinput";
  //     }
  //     return "Belum diinput";
  //   } catch (e) {
  //     return "Gagal memuat data";
  //   }
  // }

  Future<String?> ambilDataAlHusna() async {
  // 1. Validasi awal data arguments
  if (dataArgs.isEmpty || dataArgs['tahunajaran'] == null || dataArgs['nisn'] == null) {
    // print("Debug: Argumen tidak lengkap -> tahunajaran: ${dataArgs['tahunajaran']}, nisn: ${dataArgs['nisn']}");
    return "Data Argumen Tidak Lengkap";
  }

  try {
    // 2. Persiapkan variabel dengan aman
    final String tahunAjaranRaw = dataArgs['tahunajaran'];
    final String idTahunAjaran = tahunAjaranRaw.replaceAll("/", "-");
    final String fase = dataArgs['fase'] ?? 'fase-kosong';
    final String namaPengampu = dataArgs['namapengampu'] ?? 'pengampu-kosong';
    final String nisn = dataArgs['nisn'];

    // Baris ini bisa Anda uncomment untuk debugging di console
    // print("Debug: Mencari capaian di path -> .../tahunajaran/$idTahunAjaran/kelompokmengaji/$fase/pengampu/$namaPengampu/daftarsiswa/$nisn/semester");

    // 3. Buat kueri yang KONSISTEN dengan simpanNilai
    final QuerySnapshot<Map<String, dynamic>> snapSemesterSiswa = await _firestore
        .collection('Sekolah').doc(_idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(fase)
        .collection('pengampu').doc(namaPengampu)
        .collection('daftarsiswa').doc(nisn)
        .collection('semester')
        .orderBy('tanggalinput', descending: true) // <-- PERBAIKAN UTAMA: Selalu urutkan!
        .limit(1)
        .get();

    // 4. Proses hasil kueri
    if (snapSemesterSiswa.docs.isNotEmpty) {
      final Map<String, dynamic> dataSemester = snapSemesterSiswa.docs.first.data();
      
      // Ambil nilai 'alhusna' dan cek jika null atau bukan string
      final capaian = dataSemester['alhusna'];
      
      if (capaian != null && capaian is String && capaian.isNotEmpty) {
        return capaian;
      } else {
        // Ini terjadi jika field 'alhusna' ada tapi kosong atau null
        return "Capaian Belum Diisi";
      }
    } else {
      // Ini terjadi jika TIDAK ADA dokumen semester sama sekali
      return "Semester Tidak Ditemukan";
    }

  } catch (e) {
    // print("Error di ambilDataAlHusna: $e");
    return "Error: Gagal Memuat";
  }
}

  String? _validateInput() {
    if (sabaqC.text.trim().isEmpty) return 'Sabaq masih kosong';
    if (selectedNilaiSabaq.value.isEmpty) return 'Nilai sabaq masih kosong';
    if (sabqiC.text.trim().isEmpty) return 'Sabqi masih kosong';
    if (selectedNilaiSabqi.value.isEmpty) return 'Nilai sabqi masih kosong';
    if (manzilC.text.trim().isEmpty) return 'Manzil masih kosong';
    if (selectedNilaiManzil.value.isEmpty) return 'Nilai manzil masih kosong';
    if (tugasTambahanC.text.trim().isEmpty) return 'Tugas tambahan masih kosong';
    if (selectedNilaiTugas.value.isEmpty) return 'Nilai tugas tambahan masih kosong';
    if (keteranganHalaqoh.value.isEmpty) return 'Keterangan pengampu masih kosong';
    return null;
  }

  Future<void> simpanNilai() async {
    final validationError = _validateInput();
    if (validationError != null) {
      Get.snackbar('Peringatan', validationError, backgroundColor: Colors.orange.shade700, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;

    try {
      // --- PERUBAHAN KUNCI: Validasi data penting sebelum digunakan ---
      final dynamic tahunAjaranRaw = dataArgs['tahunajaran'];
      if (tahunAjaranRaw == null || tahunAjaranRaw is! String || tahunAjaranRaw.isEmpty) {
        throw Exception("Data 'tahunajaran' untuk siswa ini tidak valid atau hilang.");
      }
      final nisnSiswa = dataArgs['nisn'];
      if (nisnSiswa == null || nisnSiswa is! String || nisnSiswa.isEmpty) {
          throw Exception("Data 'NISN' siswa ini tidak valid atau hilang.");
      }
      // --- Akhir Perubahan Kunci ---

      String idTahunAjaran = tahunAjaranRaw.replaceAll("/", "-");
      DateTime now = DateTime.now();
      String docIdNilaiHarian = DateFormat('dd-MM-yyyy').format(now);

      QuerySnapshot<Map<String, dynamic>> snapSemesterSiswa = await _firestore
          .collection('Sekolah').doc(_idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(dataArgs['fase'] ?? 'fase-kosong')
          .collection('pengampu').doc(dataArgs['namapengampu'] ?? 'pengampu-kosong')
          .collection('daftarsiswa').doc(nisnSiswa)
          .collection('semester')
          .orderBy('tanggalinput', descending: true)
          .limit(1)
          .get();

      if (snapSemesterSiswa.docs.isEmpty) {
        throw Exception("Data semester siswa tidak ditemukan. Tidak bisa menyimpan nilai.");
      }
      
      DocumentSnapshot<Map<String, dynamic>> docSemesterSiswa = snapSemesterSiswa.docs.first;
      String namaSemester = docSemesterSiswa.data()?['namasemester'] ?? "Semester Tidak Diketahui";
      String alhusnaSaatIni = docSemesterSiswa.data()?['alhusna'] ?? "Al-Husna Tidak Diketahui";
      
      DocumentReference<Map<String, dynamic>> docNilaiRef = docSemesterSiswa.reference.collection('nilai').doc(docIdNilaiHarian);

      // --- PENAMBAHAN: Memberikan nilai default untuk mencegah null ---
      final Map<String, dynamic> dataNilai = {
        "tanggalinput": now.toIso8601String(),
        "emailpenginput": _currentUserEmail,
        "fase": dataArgs['fase'] ?? 'Data Kosong',
        "idpengampu": _currentUserId,
        "idsiswa": nisnSiswa,
        "kelas": dataArgs['kelas'] ?? 'Data Kosong',
        "kelompokmengaji": dataArgs['kelompokmengaji'] ?? 'Data Kosong',
        "namapengampu": dataArgs['namapengampu'] ?? 'Data Kosong',
        "namasemester": namaSemester,
        "namasiswa": dataArgs['namasiswa'] ?? 'Siswa Tidak Dikenali',
        "tahunajaran": tahunAjaranRaw, // Disimpan dalam format asli
        "suratsabaq": selectedSuratSabaq.value,
        "sabaq": sabaqC.text.trim(),
        "nilaisabaq": selectedNilaiSabaq.value,
        "suratsabqi": selectedSuratSabqi.value,
        "sabqi": sabqiC.text.trim(),
        "nilaisabqi": selectedNilaiSabqi.value,
        "suratmanzil": selectedSuratManzil.value,
        "manzil": manzilC.text.trim(),
        "nilaimanzil": selectedNilaiManzil.value,
        "tugastambahan": tugasTambahanC.text.trim(),
        "nilaitugastambahan": selectedNilaiTugas.value,
        "alhusna": alhusnaSaatIni,
        "keteranganpengampu": keteranganHalaqoh.value,
        "keteranganorangtua": "0",
        "uidnilai": docIdNilaiHarian,
        "last_updated": FieldValue.serverTimestamp(),
      };

      DocumentSnapshot<Map<String, dynamic>> cekNilaiHariIni = await docNilaiRef.get();

      if (cekNilaiHariIni.exists) {
        Get.defaultDialog(
          title: 'Konfirmasi Update',
          middleText: 'Nilai untuk hari ini sudah ada. Apakah Anda ingin memperbarui data nilai?',
          textConfirm: 'Ya, Update',
          textCancel: 'Batal',
          onConfirm: () async {
            Get.back();
            await docNilaiRef.update(dataNilai);
            Get.snackbar('Sukses', 'Nilai berhasil diperbarui.', backgroundColor: Colors.green, colorText: Colors.white);
            _clearFields();
          },
        );
      } else {
        await docNilaiRef.set(dataNilai);
        Get.snackbar('Sukses', 'Nilai berhasil disimpan.', backgroundColor: Colors.green, colorText: Colors.white);
        _clearFields();
      }
    } catch (e) {
      // Menampilkan pesan error yang lebih spesifik dari validasi di atas
      Get.snackbar('Error Kritis', 'Gagal menyimpan: ${e.toString()}', backgroundColor: Colors.red.shade700, colorText: Colors.white, duration: const Duration(seconds: 5));
    } finally {
      isLoading.value = false;
    }
  }

  void _clearFields() {
    sabaqC.clear();
    sabqiC.clear();
    manzilC.clear();
    tugasTambahanC.clear();
    selectedSuratSabaq.value = '';
    selectedNilaiSabaq.value = '';
    selectedSuratSabqi.value = '';
    selectedNilaiSabqi.value = '';
    selectedSuratManzil.value = '';
    selectedNilaiManzil.value = '';
    selectedNilaiTugas.value = '';
    keteranganHalaqoh.value = "";
  }

  @override
  void onClose() {
    sabaqC.dispose();
    sabqiC.dispose();
    manzilC.dispose();
    tugasTambahanC.dispose();
    super.onClose();
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class PemberianNilaiHalaqohController extends GetxController {
//   // --- State Observables ---
//   final RxString keteranganHalaqoh = "".obs;
//   final RxBool isLoading = false.obs;

//    // BARU: Gunakan RxString untuk menampung nilai terpilih dari DropdownSearch.
//   // Ini lebih efisien daripada menggunakan TextEditingController untuk dropdown.
//   final RxString selectedSuratSabaq = ''.obs;
//   final RxString selectedNilaiSabaq = ''.obs;
//   final RxString selectedSuratSabqi = ''.obs;
//   final RxString selectedNilaiSabqi = ''.obs;
//   final RxString selectedSuratManzil = ''.obs;
//   final RxString selectedNilaiManzil = ''.obs;
//   final RxString selectedNilaiTugas = ''.obs;

//   // --- Text Editing Controllers (hanya untuk TextField biasa) ---
//   late TextEditingController sabaqC;
//   late TextEditingController sabqiC;
//   late TextEditingController manzilC;
//   late TextEditingController tugasTambahanC;

//   // late final Map<String, dynamic> dataArgs;

//   // --- Firebase Instances ---
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // --- Data from Arguments ---
//   // Akan diinisialisasi di onInit dari Get.arguments
//   Map<String, dynamic> dataArgs = {};

//   // --- Constants (bisa dipindah ke file konfigurasi) ---
//   static const String _defaultIdSekolah = 'P9984539';

//   // --- Getters ---
//   String get _currentUserId => _auth.currentUser!.uid;
//   String get _currentUserEmail => _auth.currentUser!.email!;
//   String get _idSekolah => dataArgs['id_sekolah'] ?? _defaultIdSekolah; // Contoh jika id_sekolah bisa dari args

//     @override
//   void onInit() {
//     super.onInit();
//     final arguments = Get.arguments;
//     if (arguments is Map<String, dynamic>) {
//       dataArgs = arguments;
//     } else {
//       dataArgs = {};
//       Get.snackbar("Error", "Data navigasi tidak valid.", backgroundColor: Colors.red);
//     }
    
//     // Inisialisasi controller untuk TextField
//     sabaqC = TextEditingController();
//     sabqiC = TextEditingController();
//     manzilC = TextEditingController();
//     tugasTambahanC = TextEditingController();
//   }

//   void onChangeKeterangan(String? catatan) {
//     if (catatan != null) {
//       keteranganHalaqoh.value = catatan;
//     }
//   }

//   Future<String?> ambilDataAlHusna() async {
//     if (dataArgs.isEmpty || dataArgs['tahunajaran'] == null) {
//       // print("Error: Data arguments tidak lengkap untuk ambilDataUmi");
//       return "Data siswa tidak lengkap";
//     }

//     String idTahunAjaranRaw = dataArgs['tahunajaran'];
//     String idTahunAjaran = idTahunAjaranRaw.replaceAll("/", "-");

//     try {
//       // Path disesuaikan dengan asumsi 'namaSemester' adalah ID unik per siswa di bawah collection 'semester'
//       // atau kita perlu mengambil dokumen semester yang relevan.
//       // Kode asli mengambil `snapSemester.docs.first.data()`, mengasumsikan ada satu dokumen.
//       QuerySnapshot<Map<String, dynamic>> snapSemesterSiswa = await _firestore
//           .collection('Sekolah').doc(_idSekolah)
//           .collection('tahunajaran').doc(idTahunAjaran)
//           .collection('kelompokmengaji').doc(dataArgs['fase'])
//           .collection('pengampu').doc(dataArgs['namapengampu'])
//           // .collection('tempat').doc(dataArgs['tempatmengaji'])
//           .collection('daftarsiswa').doc(dataArgs['nisn'])
//           .collection('semester')
//           .limit(1) // Ambil dokumen semester terakhir/aktif
//           .get();

//       if (snapSemesterSiswa.docs.isNotEmpty) {
//         Map<String, dynamic> dataSemester = snapSemesterSiswa.docs.first.data();
//         return dataSemester['alhusna'] as String? ?? "Belum diinput";
//       }
//       return "Belum diinput"; // Jika tidak ada dokumen semester
//     } catch (e) {
//       // print("Error ambilDataUmi: $e");
//       return "Gagal memuat data";
//     }
//   }

//   String? _validateInput() {
//     // UBAH: Validasi menggunakan nilai dari RxString
//     if (sabaqC.text.trim().isEmpty) return 'Sabaq masih kosong';
//     if (selectedNilaiSabaq.value.isEmpty) return 'Nilai sabaq masih kosong';
//     if (sabqiC.text.trim().isEmpty) return 'Sabqi masih kosong';
//     if (selectedNilaiSabqi.value.isEmpty) return 'Nilai sabqi masih kosong';
//     if (manzilC.text.trim().isEmpty) return 'Manzil masih kosong';
//     if (selectedNilaiManzil.value.isEmpty) return 'Nilai manzil masih kosong';
//     if (tugasTambahanC.text.trim().isEmpty) return 'Tugas tambahan masih kosong';
//     if (selectedNilaiTugas.value.isEmpty) return 'Nilai tugas tambahan masih kosong';
//     if (keteranganHalaqoh.value.isEmpty) return 'Keterangan pengampu masih kosong';
//     return null;
//   }

//   Future<void> simpanNilai() async {
    
//     final validationError = _validateInput();
//     if (validationError != null) {
//       Get.snackbar('Peringatan', validationError,
//           backgroundColor: Colors.orange.shade700, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
//       return;
//     }

//     isLoading.value = true;

//     if (dataArgs.isEmpty) {
//       Get.snackbar('Error', 'Data siswa tidak lengkap untuk penyimpanan.',
//           backgroundColor: Colors.red.shade700, colorText: Colors.white);
//       isLoading.value = false;
//       return;
//     }

//     try {
//       String idTahunAjaranRaw = dataArgs['tahunajaran'];
//       String idTahunAjaran = idTahunAjaranRaw.replaceAll("/", "-");
//       DateTime now = DateTime.now();
//       String docIdNilaiHarian = DateFormat('dd-MM-yyyy').format(now); // ID untuk nilai harian

//       // Ambil data semester siswa (termasuk namaSemester dan UMI terakhir)
//       DocumentSnapshot<Map<String, dynamic>>? docSemesterSiswa;
//       QuerySnapshot<Map<String, dynamic>> snapSemesterSiswa = await _firestore
//           .collection('Sekolah').doc(_idSekolah)
//           .collection('tahunajaran').doc(idTahunAjaran)
//           .collection('kelompokmengaji').doc(dataArgs['fase'])
//           .collection('pengampu').doc(dataArgs['namapengampu'])
//           // .collection('tempat').doc(dataArgs['tempatmengaji'])
//           .collection('daftarsiswa').doc(dataArgs['nisn'])
//           .collection('semester')
//           .orderBy('tanggalinput', descending: true) // Asumsi ada field timestamp
//           .limit(1)
//           .get();

//       String namaSemester;
//       String alhusnaSaatIni;

//       if (snapSemesterSiswa.docs.isNotEmpty) {
//           docSemesterSiswa = snapSemesterSiswa.docs.first;
//           namaSemester = docSemesterSiswa.data()?['namasemester'] ?? "Semester Tidak Diketahui";
//           alhusnaSaatIni = docSemesterSiswa.data()?['alhusna'] ?? "al-husna Tidak Diketahui";
//       } else {
//           // Handle jika tidak ada data semester, mungkin perlu dibuat dulu atau error
//           Get.snackbar('Error', 'Data semester siswa tidak ditemukan.',
//               backgroundColor: Colors.red.shade700, colorText: Colors.white);
//           isLoading.value = false;
//           return;
//       }

//       CollectionReference<Map<String, dynamic>> colNilaiHarian = docSemesterSiswa!.reference.collection('nilai');
//       DocumentReference<Map<String, dynamic>> docNilaiRef = colNilaiHarian.doc(docIdNilaiHarian);

//       // int nilaiNumerik = int.parse(nilaiC.text);
//       // String grade = _getGrade(nilaiNumerik);

//       final Map<String, dynamic> dataNilai = {
//         // "tanggalinput": Timestamp.fromDate(now), // Simpan sebagai Timestamp
//         "tanggalinput": DateTime.now().toIso8601String(), // Rubah jadi String
//         "emailpenginput": _currentUserEmail,
//         "fase": dataArgs['fase'],
//         "idpengampu": _currentUserId,
//         "idsiswa": dataArgs['nisn'],
//         "kelas": dataArgs['kelas'],
//         "kelompokmengaji": dataArgs['kelompokmengaji'],
//         "namapengampu": dataArgs['namapengampu'],
//         "namasemester": namaSemester,
//         "namasiswa": dataArgs['namasiswa'],
//         "tahunajaran": dataArgs['tahunajaran'],
//         // "tempatmengaji": dataArgs['tempatmengaji'],
//         "suratsabaq": selectedSuratSabaq.value,
//         "sabaq": sabaqC.text.trim(),
//         "nilaisabaq": selectedNilaiSabaq.value,
//         "suratsabqi": selectedSuratSabqi.value,
//         "sabqi": sabqiC.text.trim(),
//         "nilaisabqi": selectedNilaiSabqi.value,
//         "suratmanzil": selectedSuratManzil.value,
//         "manzil": manzilC.text.trim(),
//         "nilaimanzil": selectedNilaiManzil.value,
//         "tugastambahan": tugasTambahanC.text.trim(),
//         "nilaitugastambahan": selectedNilaiTugas.value,
//         "alhusna": alhusnaSaatIni,
//         "keteranganpengampu": keteranganHalaqoh.value,
//         "keteranganorangtua": "0", // Default
//         "uidnilai": docIdNilaiHarian, // atau docNilaiRef.id
//         "last_updated": FieldValue.serverTimestamp(),
//         "lastupdatedsting": FieldValue.serverTimestamp().toString(),
//       };

//       DocumentSnapshot<Map<String, dynamic>> cekNilaiHariIni = await docNilaiRef.get();

//       if (cekNilaiHariIni.exists) {
//         Get.defaultDialog(
//           title: 'Konfirmasi Update',
//           titleStyle: const TextStyle(fontWeight: FontWeight.bold),
//           middleText: 'Nilai untuk hari ini sudah ada. Apakah Anda ingin memperbarui data nilai?',
//           textConfirm: 'Ya, Update',
//           textCancel: 'Batal',
//           confirmTextColor: Colors.white,
//           buttonColor: Get.theme.colorScheme.primary,
//           onConfirm: () async {
//             Get.back(); // Tutup dialog
//             await docNilaiRef.update(dataNilai);
//             Get.snackbar('Sukses', 'Nilai berhasil diperbarui.',
//                 backgroundColor: Colors.green, colorText: Colors.white);
//             _clearFields(); // Opsional: bersihkan field setelah update
//             // Get.back(); // Kembali ke halaman sebelumnya jika perlu
//           },
//           onCancel: () {}
//         );
//       } else {
//         await docNilaiRef.set(dataNilai);
//         Get.snackbar('Sukses', 'Nilai berhasil disimpan.',
//             backgroundColor: Colors.green, colorText: Colors.white);
//         _clearFields(); // Bersihkan field setelah simpan baru
//         // Get.back(); // Kembali ke halaman sebelumnya jika perlu
//       }
//       // Panggil method refresh() Anda jika ada dan dibutuhkan
//     } catch (e) {
//       print("Error simpanNilai: $e");
//       Get.snackbar('Error', 'Terjadi kesalahan saat menyimpan: ${e.toString()}',
//           backgroundColor: Colors.red.shade700, colorText: Colors.white);
//     } finally {
//       isLoading.value = false;
//     }
//   }

 

//    void _clearFields() {
//     // Bersihkan semua state
//     sabaqC.clear();
//     sabqiC.clear();
//     manzilC.clear();
//     tugasTambahanC.clear();
    
//     selectedSuratSabaq.value = '';
//     selectedNilaiSabaq.value = '';
//     selectedSuratSabqi.value = '';
//     selectedNilaiSabqi.value = '';
//     selectedSuratManzil.value = '';
//     selectedNilaiManzil.value = '';
//     selectedNilaiTugas.value = '';
    
//     keteranganHalaqoh.value = "";
//   }

//    @override
//   void onClose() {
//     // Dispose semua controller yang dibuat
//     sabaqC.dispose();
//     sabqiC.dispose();
//     manzilC.dispose();
//     tugasTambahanC.dispose();
//     super.onClose();
//   }
// }