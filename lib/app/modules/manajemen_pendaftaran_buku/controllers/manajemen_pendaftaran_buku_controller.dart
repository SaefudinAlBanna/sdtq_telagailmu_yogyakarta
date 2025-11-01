// lib/app/modules/manajemen_pendaftaran_buku/controllers/manajemen_pendaftaran_buku_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/buku_model.dart';

class ManajemenPendaftaranBukuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final Rxn<DocumentSnapshot> pendaftaranAktif = Rxn<DocumentSnapshot>();

  final judulC = TextEditingController();
  final Rxn<DateTime> tanggalBuka = Rxn<DateTime>();
  final Rxn<DateTime> tanggalTutup = Rxn<DateTime>();

  late CollectionReference _pendaftaranRef;
  
  // State untuk rekap
  final RxList<BukuModel> daftarBukuDitawarkan = <BukuModel>[].obs;
  final RxMap<String, List<Map<String, dynamic>>> pendaftarPerBuku = <String, List<Map<String, dynamic>>>{}.obs;
  final RxList<String> daftarKelasFilter = <String>['Semua Kelas'].obs;
  final RxString kelasTerpilih = 'Semua Kelas'.obs;

  @override
  void onInit() {
    super.onInit();
    final tahunAjaran = configC.tahunAjaranAktif.value;
    _pendaftaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran).collection('pendaftaran_buku');
    ever(kelasTerpilih, (_) => _fetchPendaftar());
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await _fetchKelasFilter();
      final snapshot = await _pendaftaranRef.where('status', isEqualTo: 'Dibuka').limit(1).get();
      pendaftaranAktif.value = snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
      if (pendaftaranAktif.value != null) {
        await _fetchBukuDitawarkan();
        await _fetchPendaftar();
      }
    } catch (e) { Get.snackbar("Error", "Gagal memuat data pendaftaran: $e");
    } finally { isLoading.value = false; }
  }

  Future<void> _fetchKelasFilter() async {
    final kelasSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas')
        .where('tahunAjaran', isEqualTo: configC.tahunAjaranAktif.value).get();
    final kelasList = kelasSnap.docs.map((d) => d.id.split('-').first).toSet().toList();
    kelasList.sort();
    daftarKelasFilter.addAll(kelasList);
  }

  Future<void> _fetchBukuDitawarkan() async {
     final bukuSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('buku_ditawarkan').get();
    daftarBukuDitawarkan.assignAll(bukuSnap.docs.map((d) => BukuModel.fromFirestore(d)).toList());
  }

  Future<void> _fetchPendaftar() async {
    Query query = _pendaftaranRef;
    if (kelasTerpilih.value != 'Semua Kelas') {
      final kelasIdLengkap = '${kelasTerpilih.value}-${configC.tahunAjaranAktif.value}';
      query = query.where('kelasSiswa', isEqualTo: kelasIdLengkap);
    }
    final pendaftarSnap = await query.get();

    final Map<String, List<Map<String, dynamic>>> tempMap = {};
    for (var doc in pendaftarSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> bukuDipilih = data['bukuDipilih'] ?? [];
      for (var buku in bukuDipilih) {
        final bukuId = buku['bukuId'];
        if (tempMap[bukuId] == null) tempMap[bukuId] = [];
        tempMap[bukuId]!.add({'nama': data['namaSiswa'], 'kelas': data['kelasSiswa']});
      }
    }
    pendaftarPerBuku.value = tempMap;
  }

  Future<void> _loadPendaftaranAktif() async {
    isLoading.value = true;
    try {
      final snapshot = await _pendaftaranRef.where('status', isEqualTo: 'Dibuka').limit(1).get();
      pendaftaranAktif.value = snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data pendaftaran: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void pickDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (range != null) {
      tanggalBuka.value = range.start;
      tanggalTutup.value = range.end;
    }
  }

  Future<void> bukaPendaftaran() async {
    if (judulC.text.trim().isEmpty || tanggalBuka.value == null || tanggalTutup.value == null) {
      Get.snackbar("Peringatan", "Semua field wajib diisi."); return;
    }
    isSaving.value = true;
    try {
      await _pendaftaranRef.add({
        'judul': judulC.text.trim(),
        'tanggalBuka': Timestamp.fromDate(tanggalBuka.value!),
        'tanggalTutup': Timestamp.fromDate(tanggalTutup.value!),
        'status': 'Dibuka',
        'tahunAjaran': configC.tahunAjaranAktif.value,
      });
      Get.snackbar("Berhasil", "Periode pendaftaran buku telah dibuka.", backgroundColor: Colors.green);
      _loadPendaftaranAktif();
    } catch (e) { Get.snackbar("Error", "Gagal membuka pendaftaran: $e");
    } finally { isSaving.value = false; }
  }

  Future<void> tutupPendaftaran() async {
    if (pendaftaranAktif.value == null) return;
    Get.defaultDialog(
      title: "Konfirmasi",
      middleText: "Anda yakin ingin menutup periode pendaftaran buku ini?",
      onConfirm: () async {
        Get.back();
        isSaving.value = true;
        try {
          await pendaftaranAktif.value!.reference.update({'status': 'Ditutup'});
          Get.snackbar("Berhasil", "Periode pendaftaran telah ditutup.");
          _loadPendaftaranAktif();
        } catch (e) { Get.snackbar("Error", "Gagal menutup pendaftaran: $e");
        } finally { isSaving.value = false; }
      },
    );
  }

  // Nanti kita akan tambahkan logika untuk menampilkan rekap pendaftar di sini
}
