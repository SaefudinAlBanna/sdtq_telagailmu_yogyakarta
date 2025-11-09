// lib/app/modules/penjadwalan_ujian/controllers/penjadwalan_ujian_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_simple_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pengajuan_ujian_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/services/notifikasi_service.dart';

class PenjadwalanUjianController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  final RxBool isLoading = true.obs;
  final RxList<PengajuanUjianModel> daftarPengajuan = <PengajuanUjianModel>[].obs;
  final RxList<PegawaiSimpleModel> daftarPenguji = <PegawaiSimpleModel>[].obs;

  // State untuk dialog/bottom sheet
  final Rxn<PegawaiSimpleModel> pengujiTerpilih = Rxn<PegawaiSimpleModel>();
  final Rx<DateTime> tanggalTerpilih = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    isLoading.value = true;
    try {
      // Jalankan kedua fetch secara paralel
      await Future.wait([
        _fetchDaftarPengajuan(),
        _fetchDaftarPenguji(),
      ]);
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchDaftarPengajuan() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_ujian')
        .where('status', isEqualTo: 'diajukan')
        .get();
    
    daftarPengajuan.assignAll(snapshot.docs.map((doc) => PengajuanUjianModel.fromFirestore(doc)).toList());
  }

  Future<void> _fetchDaftarPenguji() async {
    final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('pengaturan').doc('halaqah_config').get();

    if (doc.exists && doc.data() != null) {
      final Map<String, dynamic> pengujiMap = doc.data()!['daftarPenguji'] ?? {};
      final List<PegawaiSimpleModel> tempList = [];
      
      // Ambil detail pegawai untuk mendapatkan alias
      final pegawaiSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
      final Map<String, PegawaiSimpleModel> pegawaiMap = { for (var p in pegawaiSnapshot.docs) p.id : PegawaiSimpleModel.fromFirestore(p) };

      pengujiMap.forEach((uid, nama) {
        tempList.add(pegawaiMap[uid] ?? PegawaiSimpleModel(uid: uid, nama: nama as String, alias: ''));
      });
      daftarPenguji.assignAll(tempList);
    }
  }
  
  void showSchedulingDialog(PengajuanUjianModel pengajuan) {
    // Reset state
    pengujiTerpilih.value = null;
    tanggalTerpilih.value = DateTime.now();

    Get.defaultDialog(
      title: "Atur Jadwal: ${pengajuan.namaSiswa}",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => DropdownButtonFormField<PegawaiSimpleModel>(
            value: pengujiTerpilih.value,
            items: daftarPenguji.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
            onChanged: (val) => pengujiTerpilih.value = val,
            decoration: const InputDecoration(labelText: 'Pilih Penguji', border: OutlineInputBorder()),
          )),
          const SizedBox(height: 16),
          Obx(() => ListTile(
            title: const Text("Tanggal Ujian"),
            subtitle: Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggalTerpilih.value)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          )),
        ],
      ),
      textCancel: "Batal",
      textConfirm: "Simpan Jadwal",
      confirmTextColor: Colors.white,
      onConfirm: () => _saveSchedule(pengajuan),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: tanggalTerpilih.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) tanggalTerpilih.value = picked;
  }
  
  Future<void> _saveSchedule(PengajuanUjianModel pengajuan) async {
    if (pengujiTerpilih.value == null) {
      Get.snackbar("Peringatan", "Silakan pilih penguji terlebih dahulu.");
      return;
    }

    Get.back(); // Tutup dialog
    try {
      final tahunAjaran = configC.tahunAjaranAktif.value;
      final WriteBatch batch = _firestore.batch();

      // 1. Update dokumen ujian
      final docUjianRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('halaqah_ujian').doc(pengajuan.id);

      final penguji = pengujiTerpilih.value!;
      batch.update(docUjianRef, {
        'status': 'dijadwalkan',
        'tanggalUjian': Timestamp.fromDate(tanggalTerpilih.value),
        'uidPenguji': penguji.uid,
        'namaPenguji': penguji.displayName, // [IMPLEMENTASI] Gunakan displayName
      });

      // 2. Update denormalisasi di dokumen siswa
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').doc(pengajuan.uidSiswa);
      batch.update(siswaRef, {'statusUjianHalaqah': 'dijadwalkan'});

      // 3. Kirim notifikasi
      await NotifikasiService.kirimNotifikasi(
        uidPenerima: pengajuan.uidSiswa,
        judul: "Ujian Halaqah Telah Dijadwalkan!",
        isi: "Alhamdulillah, jadwal ujian ananda ${pengajuan.namaSiswa} telah ditetapkan pada ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggalTerpilih.value)} dengan penguji ${penguji.displayName}.",
        tipe: "HALAQAH",
      );

      // 4. Commit dan update UI
      await batch.commit();
      daftarPengajuan.removeWhere((p) => p.id == pengajuan.id); // Hapus dari daftar "diajukan"
      Get.snackbar("Berhasil", "Jadwal ujian untuk ${pengajuan.namaSiswa} telah disimpan.");

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan jadwal: ${e.toString()}");
    }
  }
}