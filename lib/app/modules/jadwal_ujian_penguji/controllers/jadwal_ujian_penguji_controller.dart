// lib/app/modules/jadwal_ujian_penguji/controllers/jadwal_ujian_penguji_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pengajuan_ujian_model.dart'; // Reuse model
import 'package:sdtq_telagailmu_yogyakarta/app/services/notifikasi_service.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/utils/halaqah_utils.dart';

class JadwalUjianPengujiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  final RxBool isLoading = true.obs;
  final RxList<PengajuanUjianModel> daftarJadwal = <PengajuanUjianModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchJadwal();
  }

  Future<void> _fetchJadwal() async {
    isLoading.value = true;
    try {
      final uid = authC.auth.currentUser!.uid;
      final tahunAjaran = configC.tahunAjaranAktif.value;
      final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_ujian')
        .where('uidPenguji', isEqualTo: uid)
        .where('status', isEqualTo: 'dijadwalkan')
        .orderBy('tanggalUjian')
        .get();
      
      daftarJadwal.assignAll(snapshot.docs.map((doc) => PengajuanUjianModel.fromFirestore(doc)).toList());
    } catch (e) { Get.snackbar("Error", "Gagal memuat jadwal: ${e.toString()}");
    print("Gagal memuat jadwal.. ${e.toString()}");
    } finally { isLoading.value = false; }
  }

  void showAssessmentDialog(PengajuanUjianModel jadwal) async {
    final Rxn<String> hasilUjian = Rxn<String>();
    final Rxn<String> tingkatSelanjutnya = Rxn<String>();
    final catatanC = TextEditingController();

    // Ambil data tingkatan siswa saat ini
    final siswaDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(jadwal.uidSiswa).get();
    final tingkatanSaatIni = (siswaDoc.data()?['halaqahTingkatan'] as Map<String, dynamic>?)?['nama'] as String?;

    Get.defaultDialog(
      title: "Penilaian: ${jadwal.namaSiswa}",
      content: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tingkatanSaatIni != null) Text("Tingkat Saat Ini: $tingkatanSaatIni", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            hint: const Text("Pilih Hasil Ujian"),
            value: hasilUjian.value,
            items: ['Lulus', 'Tidak Lulus'].map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
            onChanged: (val) => hasilUjian.value = val,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          if (hasilUjian.value == 'Lulus') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              hint: const Text("Pilih Kenaikan Tingkat"),
              value: tingkatSelanjutnya.value,
              items: _getTingkatBerikutnyaOptions(tingkatanSaatIni),
              onChanged: (val) => tingkatSelanjutnya.value = val,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 16),
          TextField(controller: catatanC, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Catatan penguji..."), maxLines: 3),
        ],
      )),
      textCancel: "Batal",
      textConfirm: "Simpan Hasil",
      onConfirm: () {
        if (hasilUjian.value == null) {
          Get.snackbar("Peringatan", "Hasil ujian harus dipilih."); return;
        }
        if (hasilUjian.value == 'Lulus' && tingkatSelanjutnya.value == null) {
          Get.snackbar("Peringatan", "Kenaikan tingkat harus dipilih."); return;
        }
        _simpanHasil(jadwal, hasilUjian.value!, catatanC.text, tingkatSelanjutnya.value);
      },
    );
  }

  List<DropdownMenuItem<String>> _getTingkatBerikutnyaOptions(String? tingkatanSaatIni) {
    if (tingkatanSaatIni == null) return HalaqahUtils.daftarTingkatan.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList();
    
    int currentIndex = HalaqahUtils.daftarTingkatan.indexOf(tingkatanSaatIni);
    if (currentIndex == -1 || currentIndex == HalaqahUtils.daftarTingkatan.length - 1) {
      return [DropdownMenuItem(value: tingkatanSaatIni, child: Text("Tetap di $tingkatanSaatIni (Puncak)"))];
    }
    // Hanya tampilkan tingkatan yang lebih tinggi
    return HalaqahUtils.daftarTingkatan.sublist(currentIndex + 1).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList();
  }

  Future<void> _simpanHasil(PengajuanUjianModel jadwal, String hasil, String catatan, String? tingkatBaru) async {
    Get.back();
    try {
      final tahunAjaran = configC.tahunAjaranAktif.value;
      WriteBatch batch = _firestore.batch();
      
      final docUjianRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran).collection('halaqah_ujian').doc(jadwal.id);
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(jadwal.uidSiswa);

      // 1. Update Dokumen Ujian
      batch.update(docUjianRef, {
        'status': 'selesai', 'hasilUjian': hasil, 'catatanPenguji': catatan,
        'tanggalPenilaian': FieldValue.serverTimestamp(),
      });

      // 2. Update Dokumen Siswa
      batch.update(siswaRef, {'statusUjianHalaqah': FieldValue.delete()});
      if (hasil == 'Lulus' && tingkatBaru != null) {
        batch.update(siswaRef, {
          'halaqahTingkatan': {
            'nama': tingkatBaru,
            'warna': HalaqahUtils.getWarnaTingkatan(tingkatBaru).value.toRadixString(16),
          }
        });
      }

      // 3. Kirim Notifikasi
      final notifIsi = (hasil == 'Lulus')
          ? "Alhamdulillah, hasil ujian ananda ${jadwal.namaSiswa} telah keluar dengan hasil LULUS dan naik ke tingkat $tingkatBaru. Silakan buka aplikasi untuk melihat catatan detail dari penguji."
          : "Hasil ujian ananda ${jadwal.namaSiswa} telah keluar. Mohon untuk terus memberikan semangat dan mendampingi muroja'ah di rumah untuk persiapan ujian berikutnya. Silakan buka aplikasi untuk melihat catatan detail dari penguji.";
      
      await NotifikasiService.kirimNotifikasi(
        uidPenerima: jadwal.uidSiswa,
        judul: "Hasil Ujian Halaqah Telah Keluar",
        isi: notifIsi, tipe: "HALAQAH",
      );

      // 4. Commit & Update UI
      await batch.commit();
      daftarJadwal.removeWhere((j) => j.id == jadwal.id);
      Get.snackbar("Berhasil", "Hasil ujian telah disimpan.");

    } catch (e) { Get.snackbar("Error", "Gagal menyimpan hasil: ${e.toString()}"); }
  }
}