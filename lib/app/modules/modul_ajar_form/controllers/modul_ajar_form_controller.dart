// lib/app/modules/modul_ajar_form/controllers/modul_ajar_form_controller.dart (FINAL & LENGKAP)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/atp_model.dart';
import '../../../models/modul_ajar_model.dart';
import '../../perangkat_ajar/controllers/perangkat_ajar_controller.dart';

class ModulAjarFormController extends GetxController {
  final PerangkatAjarController _perangkatAjarC = Get.find<PerangkatAjarController>();
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var uuid = const Uuid();

  final RxBool isEditMode = false.obs;
  ModulAjarModel? originalModul;
  final RxBool isSaving = false.obs;

  // Controllers untuk text fields
  final TextEditingController alokasiWaktuC = TextEditingController();
  final TextEditingController kompetensiAwalC = TextEditingController();
  final TextEditingController modelPembelajaranC = TextEditingController();
  final TextEditingController tujuanPembelajaranC = TextEditingController();
  final TextEditingController pemahamanBermaknaC = TextEditingController();

  // State untuk lists/dinamis
  final RxList<String> profilPancasila = <String>[].obs;
  final RxList<String> media = <String>[].obs;
  final RxList<String> sumberBelajar = <String>[].obs;
  final RxList<String> pertanyaanPemantik = <String>[].obs;

  // --- [MODIFIKASI] State untuk Dropdown & Penugasan ---
  final RxBool isPenugasanLoading = true.obs;
  final List<Map<String, dynamic>> penugasanGuru = [];
  final RxList<Map<String, String>> daftarMapelUnik = <Map<String, String>>[].obs;
  final RxList<String> daftarKelasTersedia = <String>[].obs;
  final Rxn<String> idMapelTerpilih = Rxn<String>(); // <- Berbasis ID
  final Rxn<String> kelasTerpilih = Rxn<String>();
  final RxString faseTerpilih = ''.obs;
  
  final RxList<SesiPembelajaranForm> sesiPembelajaranForms = <SesiPembelajaranForm>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is ModulAjarModel) {
      isEditMode.value = true;
      originalModul = Get.arguments as ModulAjarModel;
    }
    _loadPenugasanGuru(); 
  }



  void _fillFormWithData(ModulAjarModel modul) {
    idMapelTerpilih.value = modul.idMapel;
    onMapelChanged(modul.idMapel); 
    kelasTerpilih.value = modul.kelas.toString();
    faseTerpilih.value = modul.fase;
    alokasiWaktuC.text = modul.alokasiWaktu;
    kompetensiAwalC.text = modul.kompetensiAwal;
    modelPembelajaranC.text = modul.modelPembelajaran;
    tujuanPembelajaranC.text = modul.tujuanPembelajaran;
    pemahamanBermaknaC.text = modul.pemahamanBermakna;
    profilPancasila.value = modul.profilPancasila;
    media.value = modul.media;
    sumberBelajar.value = modul.sumberBelajar;
    pertanyaanPemantik.value = modul.pertanyaanPemantik;
    sesiPembelajaranForms.value = modul.kegiatanPembelajaran.map((sesi) => SesiPembelajaranForm.fromModel(sesi)).toList();
  }

  Future<void> imporTujuanPembelajaran() async {
    if (idMapelTerpilih.value == null || kelasTerpilih.value == null) {
      Get.snackbar("Informasi", "Silakan pilih 'Mata Pelajaran' dan 'Kelas' terlebih dahulu.");
      return;
    }
    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah).collection('atp')
          .where('idTahunAjaran', isEqualTo: configC.tahunAjaranAktif.value)
          // --- [PERBAIKAN KUNCI] Query menggunakan idMapel ---
          .where('idMapel', isEqualTo: idMapelTerpilih.value)
          .where('kelas', isEqualTo: int.parse(kelasTerpilih.value!))
          .limit(1).get();

      if (snapshot.docs.isEmpty) {
        Get.snackbar("Tidak Ditemukan", "Tidak ada ATP yang cocok untuk mata pelajaran dan kelas ini.");
        return;
      }
      
      final atp = AtpModel.fromJson(snapshot.docs.first.data());
      final semuaTp = atp.unitPembelajaran.expand((unit) => unit.tujuanPembelajaran).toList();
      tujuanPembelajaranC.text = semuaTp.map((tp) => "• $tp").join('\n');
      Get.snackbar("Berhasil", "Semua Tujuan Pembelajaran dari ATP terkait berhasil diimpor.");

    } catch (e) {
      Get.snackbar("Error", "Gagal mengimpor TP: $e");
    }
  }

  void addSesiPembelajaran() {
    sesiPembelajaranForms.add(SesiPembelajaranForm());
  }

  void removeSesiPembelajaran(int index) {
    sesiPembelajaranForms[index].dispose();
    sesiPembelajaranForms.removeAt(index);
  }

  Future<void> saveModulAjar() async {
    if (idMapelTerpilih.value == null || kelasTerpilih.value == null) {
      Get.snackbar("Validasi Gagal", "Informasi umum (Mapel, Kelas, Fase) wajib diisi.");
      return;
    }
    isSaving.value = true;
    try {
      // --- [MODIFIKASI] Dapatkan nama mapel dari ID yang tersimpan ---
      final namaMapelTerpilih = daftarMapelUnik
        .firstWhere((mapel) => mapel['id'] == idMapelTerpilih.value, orElse: () => {'nama': ''})['nama']!;
      
      final modulData = ModulAjarModel(
        idModul: originalModul?.idModul ?? '',
        idSekolah: configC.idSekolah,
        idPenyusun: configC.infoUser['uid'],
        namaPenyusun: configC.infoUser['alias'] ?? configC.infoUser['nama'],
        idTahunAjaran: configC.tahunAjaranAktif.value,
        idMapel: idMapelTerpilih.value!,
        mapel: namaMapelTerpilih,
        kelas: int.parse(kelasTerpilih.value!),
        fase: faseTerpilih.value,
        alokasiWaktu: alokasiWaktuC.text.trim(),
        kompetensiAwal: kompetensiAwalC.text.trim(),
        profilPancasila: profilPancasila.toList(),
        profilRahmatan: [],
        media: media.toList(),
        sumberBelajar: sumberBelajar.toList(),
        targetPesertaDidik: [],
        modelPembelajaran: modelPembelajaranC.text.trim(),
        elemen: [],
        tujuanPembelajaran: tujuanPembelajaranC.text.trim(),
        pemahamanBermakna: pemahamanBermaknaC.text.trim(),
        pertanyaanPemantik: pertanyaanPemantik.toList(),
        kegiatanPembelajaran: sesiPembelajaranForms.map((form) => form.toModel()).toList(),
        status: 'draf',
        createdAt: originalModul?.createdAt ?? Timestamp.now(),
        lastModified: Timestamp.now(),
      );

      if (isEditMode.value) {
        await _perangkatAjarC.updateModulAjar(modulData);
      } else {
        await _perangkatAjarC.createModulAjar(modulData);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan: $e");
    } finally {
      isSaving.value = false;
    }
  }


    @override
    void onClose() {
      alokasiWaktuC.dispose();
      kompetensiAwalC.dispose();
      modelPembelajaranC.dispose();
      tujuanPembelajaranC.dispose();
      pemahamanBermaknaC.dispose();
      for (var sesi in sesiPembelajaranForms) {
        sesi.dispose();
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
      
      final mapelUnikMap = <String, String>{}; 
      for (var tugas in penugasanGuru) {
        if (tugas['idMapel'] != null && tugas['namaMapel'] != null) {
          mapelUnikMap[tugas['idMapel']] = tugas['namaMapel'];
        }
      }
      daftarMapelUnik.assignAll(mapelUnikMap.entries.map((e) => {'id': e.key, 'nama': e.value}).toList()
        ..sort((a, b) => a['nama']!.compareTo(b['nama']!)));

      if (isEditMode.value && originalModul != null) {
        _fillFormWithData(originalModul!);
      }

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data penugasan mengajar Anda.");
    } finally {
      isPenugasanLoading.value = false;
    }
  }

  void onMapelChanged(String? newIdMapel) {
    idMapelTerpilih.value = newIdMapel;
    kelasTerpilih.value = null;
    faseTerpilih.value = '';
    daftarKelasTersedia.clear();

    if (newIdMapel != null) {
      final kelasSet = <String>{};
      for (var tugas in penugasanGuru) {
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
}

// Helper class untuk form Sesi Pembelajaran
class SesiPembelajaranForm {
  late TextEditingController judulSesiC;
  late TextEditingController pendahuluanC;
  late TextEditingController kegiatanIntiC;
  late TextEditingController penutupC;

  SesiPembelajaranForm() {
    judulSesiC = TextEditingController();
    pendahuluanC = TextEditingController();
    kegiatanIntiC = TextEditingController();
    penutupC = TextEditingController();
  }

  factory SesiPembelajaranForm.fromModel(SesiPembelajaran model) {
    final form = SesiPembelajaranForm();
    form.judulSesiC.text = model.judulSesi;
    form.pendahuluanC.text = model.pendahuluan;
    form.kegiatanIntiC.text = model.kegiatanInti;
    form.penutupC.text = model.penutup;
    return form;
  }

  SesiPembelajaran toModel() {
    return SesiPembelajaran(
      sesi: 0, // Bisa ditambahkan logika urutan jika perlu
      judulSesi: judulSesiC.text,
      pendahuluan: pendahuluanC.text,
      kegiatanInti: kegiatanIntiC.text,
      penutup: penutupC.text,
    );
  }
  
  void dispose() {
    judulSesiC.dispose();
    pendahuluanC.dispose();
    kegiatanIntiC.dispose();
    penutupC.dispose();
  }
}