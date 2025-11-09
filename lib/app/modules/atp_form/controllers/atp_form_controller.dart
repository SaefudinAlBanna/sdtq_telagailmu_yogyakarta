// lib/app/modules/atp_form/controllers/atp_form_controller.dart (FINAL DENGAN VALIDASI)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/atp_model.dart';
import '../../perangkat_ajar/controllers/perangkat_ajar_controller.dart';

class AtpFormController extends GetxController {
  final PerangkatAjarController _perangkatAjarC = Get.find<PerangkatAjarController>();
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var uuid = const Uuid();

  final RxBool isEditMode = false.obs;
  AtpModel? originalAtp;

  final RxBool isPenugasanLoading = true.obs;
  // --- [MODIFIKASI] penugasanGuru menyimpan semua data, termasuk idMapel ---
  final List<Map<String, dynamic>> penugasanGuru = [];

  final TextEditingController capaianPembelajaranC = TextEditingController();
  // --- [MODIFIKASI] State untuk menyimpan daftar mapel unik (dengan ID dan Nama) ---
  final RxList<Map<String, String>> daftarMapelUnik = <Map<String, String>>[].obs;
  final RxList<String> daftarKelasTersedia = <String>[].obs;

  // --- [MODIFIKASI] State sekarang menyimpan ID Mapel, bukan namanya ---
  final Rxn<String> idMapelTerpilih = Rxn<String>();
  final Rxn<String> kelasTerpilih = Rxn<String>();
  final RxString faseTerpilih = ''.obs;

  final RxList<UnitPembelajaranForm> unitPembelajaranForms = <UnitPembelajaranForm>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadPenugasanGuru();
    if (Get.arguments != null && Get.arguments is AtpModel) {
      isEditMode.value = true;
      originalAtp = Get.arguments as AtpModel;
      _fillFormWithData(originalAtp!);
    }
  }

  @override
  void onClose() {
    capaianPembelajaranC.dispose();
    for (var unitForm in unitPembelajaranForms) {
      unitForm.dispose();
    }
    super.onClose();
  }

  Future<void> _loadPenugasanGuru() async {
    isPenugasanLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('pegawai').doc(configC.infoUser['uid'])
          .collection('jadwal_mengajar').doc(configC.tahunAjaranAktif.value)
          .collection('mapel_diampu').get();

      penugasanGuru.assignAll(snapshot.docs.map((doc) => doc.data()).toList());
      
      // --- [MODIFIKASI] Membuat daftar mapel unik dengan ID dan Nama ---
      final mapelUnikMap = <String, String>{}; // Key: idMapel, Value: namaMapel
      for (var tugas in penugasanGuru) {
        if (tugas['idMapel'] != null && tugas['namaMapel'] != null) {
          mapelUnikMap[tugas['idMapel']] = tugas['namaMapel'];
        }
      }
      // Konversi map ke list of map untuk dropdown
      daftarMapelUnik.assignAll(mapelUnikMap.entries.map((e) => {'id': e.key, 'nama': e.value}).toList()
        ..sort((a, b) => a['nama']!.compareTo(b['nama']!)));

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data penugasan mengajar Anda.");
    } finally {
      isPenugasanLoading.value = false;
    }
  }

  void _fillFormWithData(AtpModel atp) {
    // --- [MODIFIKASI] Mengisi form dengan idMapel ---
    idMapelTerpilih.value = atp.idMapel;
    onMapelChanged(atp.idMapel); 
    kelasTerpilih.value = atp.kelas.toString();
    faseTerpilih.value = atp.fase;
    capaianPembelajaranC.text = atp.capaianPembelajaran;
    unitPembelajaranForms.value = atp.unitPembelajaran.map((unit) => UnitPembelajaranForm.fromModel(unit)).toList();
  }

  void onMapelChanged(String? newIdMapel) {
    idMapelTerpilih.value = newIdMapel;
    kelasTerpilih.value = null;
    faseTerpilih.value = '';
    daftarKelasTersedia.clear();

    if (newIdMapel != null) {
      final kelasSet = <String>{};
      for (var tugas in penugasanGuru) {
        // --- [MODIFIKASI] Filter berdasarkan idMapel ---
        if (tugas['idMapel'] == newIdMapel) {
          final kelasAngka = tugas['idKelas'].split('-').first.replaceAll(RegExp(r'[^0-9]'), '');
          if (kelasAngka.isNotEmpty) kelasSet.add(kelasAngka);
        }
      }
      daftarKelasTersedia.assignAll(kelasSet.toList()..sort());
    }
  }

  void onKelasChanged(String? newValue) {
    kelasTerpilih.value = newValue;
    if (newValue != null) {
      int kelasAngka = int.tryParse(newValue) ?? 0;
      if (kelasAngka <= 2) faseTerpilih.value = 'A';
      else if (kelasAngka <= 4) faseTerpilih.value = 'B';
      else if (kelasAngka <= 6) faseTerpilih.value = 'C';
      else faseTerpilih.value = '';
    }
  }

  void addUnitPembelajaran() {
    unitPembelajaranForms.add(UnitPembelajaranForm());
  }

  void removeUnitPembelajaran(int index) {
    unitPembelajaranForms[index].dispose();
    unitPembelajaranForms.removeAt(index);
  }

  Future<void> saveAtp() async {
    // --- [MODIFIKASI] Validasi berdasarkan idMapelTerpilih ---
    if (idMapelTerpilih.value == null || kelasTerpilih.value == null || capaianPembelajaranC.text.trim().isEmpty) {
      Get.snackbar("Validasi Gagal", "Informasi umum (Mapel, Kelas, CP) wajib diisi.", backgroundColor: Colors.orange);
      return;
    }
    if (unitPembelajaranForms.isEmpty) {
      Get.snackbar("Validasi Gagal", "Minimal harus ada satu Unit Pembelajaran.", backgroundColor: Colors.orange);
      return;
    }

    // --- [MODIFIKASI] Dapatkan nama mapel dari ID yang tersimpan ---
    final namaMapelTerpilih = daftarMapelUnik
      .firstWhere((mapel) => mapel['id'] == idMapelTerpilih.value, orElse: () => {'nama': ''})['nama']!;

    AtpModel atpData = AtpModel(
      idAtp: originalAtp?.idAtp ?? '',
      idSekolah: configC.idSekolah,
      idPenyusun: configC.infoUser['uid'],
      namaPenyusun: configC.infoUser['alias'] ?? configC.infoUser['nama'],
      idTahunAjaran: configC.tahunAjaranAktif.value,
      // --- [MODIFIKASI] Simpan idMapel dan namaMapel ---
      idMapel: idMapelTerpilih.value!,
      namaMapel: namaMapelTerpilih,
      fase: faseTerpilih.value,
      kelas: int.parse(kelasTerpilih.value!),
      capaianPembelajaran: capaianPembelajaranC.text.trim(),
      createdAt: originalAtp?.createdAt ?? Timestamp.now(),
      lastModified: Timestamp.now(),
      unitPembelajaran: unitPembelajaranForms.map((form) => form.toModel()).toList(),
    );

    if (isEditMode.value) {
      await _perangkatAjarC.updateAtp(atpData);
    } else {
      await _perangkatAjarC.createAtp(atpData);
    }
  }
}

// Helper class untuk mengelola state form per Unit Pembelajaran
  class UnitPembelajaranForm {
    late TextEditingController lingkupMateriC;
    late TextEditingController alokasiWaktuC;
    RxList<String> tujuanPembelajaran = <String>[].obs;

    UnitPembelajaranForm() {
      lingkupMateriC = TextEditingController();
      alokasiWaktuC = TextEditingController();
    }
    
    factory UnitPembelajaranForm.fromModel(UnitPembelajaran model) {
      final form = UnitPembelajaranForm();
      form.lingkupMateriC.text = model.lingkupMateri;
      form.alokasiWaktuC.text = model.alokasiWaktu;
      form.tujuanPembelajaran.value = List<String>.from(model.tujuanPembelajaran);
      return form;
    }

    UnitPembelajaran toModel() {
      return UnitPembelajaran(
        idUnit: const Uuid().v4(),
        urutan: 0,
        lingkupMateri: lingkupMateriC.text.trim(),
        alokasiWaktu: alokasiWaktuC.text.trim(),
        tujuanPembelajaran: List<String>.from(tujuanPembelajaran),
        // Atribut lain dari model Anda yang mungkin tidak ada di form ini
        jenisTeks: '', 
        gramatika: '',
        alurPembelajaran: [],
      );
    }

    void dispose() {
      lingkupMateriC.dispose();
      alokasiWaktuC.dispose();
    }
  }