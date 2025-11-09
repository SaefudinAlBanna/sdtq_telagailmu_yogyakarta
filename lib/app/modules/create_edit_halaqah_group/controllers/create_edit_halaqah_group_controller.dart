// lib/app/modules/create_edit_halaqah_group/controllers/create_edit_halaqah_group_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_simple_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_simple_model.dart';

import '../../../models/halaqah_group_model.dart';

class CreateEditHalaqahGroupController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  // State
  final isEditMode = false.obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  String? groupId;
  HalaqahGroupModel? existingGroup;

  final namaGrupC = TextEditingController();
  final Rxn<PegawaiSimpleModel> selectedPengampu = Rxn<PegawaiSimpleModel>();
  final RxList<PegawaiSimpleModel> daftarPengampu = <PegawaiSimpleModel>[].obs;
  final RxList<String> daftarKelas = <String>[].obs;
  final RxString selectedKelasFilter = "".obs;
  
  final searchC = TextEditingController();
  final searchQuery = "".obs;

  final RxList<SiswaSimpleModel> anggotaGrup = <SiswaSimpleModel>[].obs;
  final RxList<SiswaSimpleModel> siswaTersedia = <SiswaSimpleModel>[].obs;

  String? _initialPengampuId; 
  late String tahunAjaran;
  late String semester;
  late String fieldGrupSiswa;
  List<SiswaSimpleModel> _initialMembers = [];

  List<SiswaSimpleModel> get filteredSiswaTersedia {
    if (searchQuery.value.isEmpty) return siswaTersedia;
    return siswaTersedia.where((siswa) => 
      siswa.nama.toLowerCase().contains(searchQuery.value.toLowerCase())
    ).toList();
  }



  @override
  void onInit() {
    super.onInit();
    final dynamic argument = Get.arguments;
    if (argument is HalaqahGroupModel) {
      isEditMode.value = true;
      groupId = argument.id;
      existingGroup = argument; // Simpan data grup yang diedit
    }
    
    tahunAjaran = configC.tahunAjaranAktif.value;
    semester = configC.semesterAktif.value;
    fieldGrupSiswa = "grupHalaqah.$tahunAjaran\_$semester";

    searchC.addListener(() => searchQuery.value = searchC.text);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await _fetchEligiblePengampu();
      await _fetchAvailableClasses();
      if (isEditMode.value && existingGroup != null) {
        await _loadGroupDataForEdit(existingGroup!);
      }
    } catch (e) { Get.snackbar("Error", "Gagal memuat data awal: $e"); } 
    finally { isLoading.value = false; }
  }

  Future<void> _fetchEligiblePengampu() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
    
    // 1. Dapatkan daftar ID pengampu yang sudah punya grup
    final groupSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup').get();
    
    final assignedPengampuIds = groupSnapshot.docs.map((doc) => doc.data()['idPengampu'] as String).toSet();

    // 2. Filter daftar pengampu
    final List<PegawaiSimpleModel> eligiblePengampu = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final tugas = List<String>.from(data['tugas'] ?? []);
      
      final bool isPengampuRole = tugas.any((t) => ['Pengampu', 'Koordinator Halaqah Ikhwan', 'Koordinator Halaqah Akhwat'].contains(t));
      
      if (isPengampuRole) {
        // Jika mode edit dan UID pengampu ini adalah pengampu grup yang sedang diedit, izinkan.
        if (isEditMode.value && doc.id == existingGroup?.idPengampu) {
            eligiblePengampu.add(PegawaiSimpleModel.fromFirestore(doc));
        } 
        // Jika pengampu belum punya grup, izinkan.
        else if (!assignedPengampuIds.contains(doc.id)) {
            eligiblePengampu.add(PegawaiSimpleModel.fromFirestore(doc));
        }
      }
    }
    
    eligiblePengampu.sort((a, b) => a.nama.compareTo(b.nama));
    daftarPengampu.assignAll(eligiblePengampu);
  }

  // Future<void> _fetchAvailableClasses() async {
  //   final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').get();
  //   daftarKelas.assignAll(snapshot.docs.map((doc) => doc.id).toList()..sort());
  // }

  Future<void> _fetchAvailableClasses() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
      daftarKelas.clear();
      return;
    }

    final snapshot = await _firestore
        .collection('Sekolah')
        .doc(configC.idSekolah)
        .collection('tahunajaran')
        .doc(tahunAjaran)
        .collection('kelastahunajaran')
        .get();

    final classNames = snapshot.docs
        .map((doc) => doc.id.split('-').first)
        .toSet()
        .toList();

    classNames.sort();
    daftarKelas.assignAll(classNames);
  }

  Future<void> _loadGroupDataForEdit(HalaqahGroupModel group) async {
    namaGrupC.text = group.namaGrup;
    selectedPengampu.value = daftarPengampu.firstWhereOrNull((p) => p.uid == group.idPengampu);
    _initialPengampuId = group.idPengampu; // Simpan ID pengampu lama

    final memberSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaran)
      .collection('halaqah_grup').doc(group.id).collection('anggota').get();
      
    anggotaGrup.assignAll(memberSnapshot.docs.map((doc) {
      final data = doc.data();
      return SiswaSimpleModel(uid: doc.id, nama: data['namaSiswa'], kelasId: data['kelasAsal']);
    }).toList());
    _initialMembers = List.from(anggotaGrup);
  }

  Future<void> fetchAvailableStudentsByClass(String kelasId) async {
    selectedKelasFilter.value = kelasId;
    siswaTersedia.clear();
    searchC.clear();

    // --- [FIX] LANGKAH 1: Ambil SEMUA siswa di kelas, HAPUS filter grupHalaqah ---
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('siswa')
      .where('kelasId', isGreaterThanOrEqualTo: kelasId)
      .where('kelasId', isLessThan: '$kelasId\uf8ff')
      .get();
      
    // --- [FIX] LANGKAH 2: Lakukan penyaringan di sini, di dalam aplikasi ---
    final keySemester = "$tahunAjaran\_$semester";
    final List<SiswaSimpleModel> availableStudents = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Cek apakah map 'grupHalaqah' ada, dan apakah key untuk semester ini ada di dalamnya.
      if (!data.containsKey('grupHalaqah') || !(data['grupHalaqah'] as Map).containsKey(keySemester)) {
        // Jika tidak ada, berarti siswa ini tersedia.
        availableStudents.add(SiswaSimpleModel.fromFirestore(doc));
      }
    }
    
    siswaTersedia.assignAll(availableStudents);
  }

  void addSiswaToGroup(SiswaSimpleModel siswa) {
    siswaTersedia.removeWhere((s) => s.uid == siswa.uid);
    anggotaGrup.add(siswa);
  }

  void removeSiswaFromGroup(SiswaSimpleModel siswa) {
    anggotaGrup.removeWhere((s) => s.uid == siswa.uid);
    // If the removed student belongs to the currently filtered class, add them back
    if (siswa.kelasId == selectedKelasFilter.value) {
      siswaTersedia.add(siswa);
    }
  }

  Future<void> saveGroup() async {
    if (selectedPengampu.value == null) {
      Get.snackbar("Peringatan", "Silakan pilih pengampu."); return;
    }
    if (namaGrupC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Nama grup tidak boleh kosong."); return;
    }
    
    isSaving.value = true;
    try {
      // Validasi Ganda sebelum commit
      final checkSnapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('halaqah_grup')
          .where('idPengampu', isEqualTo: selectedPengampu.value!.uid).get();

      bool isAlreadyAssigned = false;
      if (checkSnapshot.docs.isNotEmpty) {
        if (isEditMode.value) {
          // Jika mode edit, pastikan dokumen yang ditemukan bukan dokumen yang sedang kita edit
          if (checkSnapshot.docs.first.id != groupId) {
            isAlreadyAssigned = true;
          }
        } else {
          // Jika mode create, setiap dokumen yang ditemukan berarti sudah ada
          isAlreadyAssigned = true;
        }
      }

      if (isAlreadyAssigned) {
        Get.snackbar("Gagal", "Pengampu yang dipilih sudah memiliki grup lain.");
        isSaving.value = false;
        return;
      }
      
      final WriteBatch batch = _firestore.batch();
      final groupRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup').doc(groupId); // Jika groupId null, ID baru akan dibuat

      // 3. Simpan/Perbarui Dokumen Grup Utama
      batch.set(groupRef, {
        'namaGrup': namaGrupC.text.trim(),
        'idPengampu': selectedPengampu.value!.uid,
        'namaPengampu': selectedPengampu.value!.nama,
        'aliasPengampu': selectedPengampu.value!.alias,
        'profileImageUrl': selectedPengampu.value!.profileImageUrl,
        'semester': semester,
        'createdAt': FieldValue.serverTimestamp(), // Berguna untuk melacak kapan terakhir diubah
      }, SetOptions(merge: true));

      // 4. Proses Perubahan Anggota Siswa
      final initialMemberIds = _initialMembers.map((s) => s.uid).toSet();
      final finalMemberIds = anggotaGrup.map((s) => s.uid).toSet();
      
      final addedSiswa = anggotaGrup.where((s) => !initialMemberIds.contains(s.uid)).toList();
      final removedSiswa = _initialMembers.where((s) => !finalMemberIds.contains(s.uid)).toList();

      for (var siswa in addedSiswa) {
        // Tambahkan siswa ke sub-koleksi 'anggota' di grup
        batch.set(groupRef.collection('anggota').doc(siswa.uid), {
          'namaSiswa': siswa.nama, 
          'kelasAsal': siswa.kelasId
        });
        // Perbarui field di dokumen utama siswa
        batch.update(_firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid), {
          // 'fieldGrupSiswa' akan menjadi 'grupHalaqah.2025-2026_1' misalnya
          fieldGrupSiswa: groupRef.id, 
          // [BARU] Simpan data grup yang sudah didenormalisasi
          'grupHalaqah': {
            'idGrup': groupRef.id,
            'namaGrup': namaGrupC.text.trim(),
            'idPengampu': selectedPengampu.value!.uid,
            'namaPengampu': selectedPengampu.value!.nama,
          }
        });
      }
      
      for (var siswa in removedSiswa) {
        // Hapus siswa dari sub-koleksi 'anggota' di grup
        batch.delete(groupRef.collection('anggota').doc(siswa.uid));
        // Hapus field dari dokumen utama siswa
        batch.update(_firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid), {
          fieldGrupSiswa: FieldValue.delete(),
          'grupHalaqah': FieldValue.delete(), // [BARU] Hapus juga map denormalisasi
        });
      }
      
      // 5. Proses Denormalisasi untuk Pengampu
      final newPengampuId = selectedPengampu.value!.uid;
      final keySemester = "$tahunAjaran\_$semester";

      // Jika pengampu diganti (hanya dalam mode edit)
      if (isEditMode.value && _initialPengampuId != null && _initialPengampuId != newPengampuId) {
        // Hapus ID grup dari daftar milik pengampu LAMA
        final oldPengampuRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(_initialPengampuId!);
        batch.update(oldPengampuRef, {
          'grupHalaqahDiampu.$keySemester': FieldValue.arrayRemove([groupRef.id])
        });
      }
      
      // Selalu tambahkan ID grup ke daftar milik pengampu BARU (berlaku untuk mode create & edit ganti pengampu)
      final newPengampuRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(newPengampuId);
      batch.update(newPengampuRef, {
        'grupHalaqahDiampu.$keySemester': FieldValue.arrayUnion([groupRef.id])
      });
      
      // 6. Jalankan Semua Operasi
      await batch.commit();
      
      Get.back(); // Kembali ke halaman manajemen
      Get.snackbar("Berhasil", "Grup halaqah berhasil disimpan.");

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan grup: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }
  
  @override
  void onClose() {
    namaGrupC.dispose();
    searchC.dispose();
    super.onClose();
  }
}