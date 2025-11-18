// lib/app/modules/create_edit_halaqah_group/controllers/create_edit_halaqah_group_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/pegawai_simple_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/siswa_simple_model.dart';

import '../../../models/halaqah_group_model.dart';
import 'dart:developer' as developer;

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
      existingGroup = argument;
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

  // Future<void> _fetchEligiblePengampu() async {
  //   final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
    
  //   // 1. Dapatkan daftar ID pengampu yang sudah punya grup
  //   final groupSnapshot = await _firestore
  //       .collection('Sekolah').doc(configC.idSekolah)
  //       .collection('tahunajaran').doc(tahunAjaran)
  //       .collection('halaqah_grup').get();
    
  //   final assignedPengampuIds = groupSnapshot.docs.map((doc) => doc.data()['idPengampu'] as String).toSet();

  //   // 2. Filter daftar pengampu
  //   final List<PegawaiSimpleModel> eligiblePengampu = [];
  //   for (var doc in snapshot.docs) {
  //     final data = doc.data();
  //     final tugas = List<String>.from(data['tugas'] ?? []);
      
  //     final bool isPengampuRole = tugas.any((t) => ['Pengampu', 'Koordinator Halaqah Ikhwan', 'Koordinator Halaqah Akhwat'].contains(t));
      
  //     if (isPengampuRole) {
  //       // Jika mode edit dan UID pengampu ini adalah pengampu grup yang sedang diedit, izinkan.
  //       if (isEditMode.value && doc.id == existingGroup?.idPengampu) {
  //           eligiblePengampu.add(PegawaiSimpleModel.fromFirestore(doc));
  //       } 
  //       // Jika pengampu belum punya grup, izinkan.
  //       else if (!assignedPengampuIds.contains(doc.id)) {
  //           eligiblePengampu.add(PegawaiSimpleModel.fromFirestore(doc));
  //       }
  //     }
  //   }
    
  //   eligiblePengampu.sort((a, b) => a.nama.compareTo(b.nama));
  //   daftarPengampu.assignAll(eligiblePengampu);
  // }

  Future<void> _fetchEligiblePengampu() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
    
    final groupSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup').get();
    
    final assignedPengampuIds = groupSnapshot.docs
        .map((doc) => doc.data()['idPengampu'] as String?)
        .where((id) => id != null)
        .toSet();

    final List<PegawaiSimpleModel> eligiblePengampu = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final tugas = List<String>.from(data['tugas'] ?? []);
      
      // [PERBAIKAN KUNCI] Ambil juga data 'role' dengan aman
      final role = data['role'] as String? ?? '';

      // [PERBAIKAN KUNCI] Logika diperkaya untuk memeriksa 'tugas' ATAU 'role'
      final bool isPengampuRole = tugas.any((t) => 
          t == 'Pengampu' || 
          t == 'Koordinator Halaqah' ||
          t == 'Koordinator Halaqah Ikhwan' || 
          t == 'Koordinator Halaqah Akhwat'
      ) || role == 'Pengampu'; // <-- KONDISI 'ATAU' DITAMBAHKAN DI SINI
      
      if (isPengampuRole) {
        if (!assignedPengampuIds.contains(doc.id) || (isEditMode.value && doc.id == existingGroup?.idPengampu)) {
          eligiblePengampu.add(PegawaiSimpleModel.fromFirestore(doc));
        }
      }
    }
    
    eligiblePengampu.sort((a, b) => a.nama.compareTo(b.nama));
    daftarPengampu.assignAll(eligiblePengampu);
  }


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

  // Future<void> fetchAvailableStudentsByClass(String kelasId) async {
  //   selectedKelasFilter.value = kelasId;
  //   siswaTersedia.clear();
  //   searchC.clear();

  //   // --- [FIX] LANGKAH 1: Ambil SEMUA siswa di kelas, HAPUS filter grupHalaqah ---
  //   final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
  //     .collection('siswa')
  //     .where('kelasId', isGreaterThanOrEqualTo: kelasId)
  //     .where('kelasId', isLessThan: '$kelasId\uf8ff')
  //     .get();
      
  //   // --- [FIX] LANGKAH 2: Lakukan penyaringan di sini, di dalam aplikasi ---
  //   final keySemester = "$tahunAjaran\_$semester";
  //   final List<SiswaSimpleModel> availableStudents = [];

  //   for (var doc in snapshot.docs) {
  //     final data = doc.data();
  //     // Cek apakah map 'grupHalaqah' ada, dan apakah key untuk semester ini ada di dalamnya.
  //     if (!data.containsKey('grupHalaqah') || !(data['grupHalaqah'] as Map).containsKey(keySemester)) {
  //       // Jika tidak ada, berarti siswa ini tersedia.
  //       availableStudents.add(SiswaSimpleModel.fromFirestore(doc));
  //     }
  //   }
    
  //   siswaTersedia.assignAll(availableStudents);
  // }

  Future<void> fetchAvailableStudentsByClass(String kelasId) async {
    selectedKelasFilter.value = kelasId;
    siswaTersedia.clear();
    searchC.clear();

    // Langkah 1: Ambil semua siswa dari kelas yang dipilih. Query ini sudah benar.
    final snapshot = await _firestore
        .collection('Sekolah')
        .doc(configC.idSekolah)
        .collection('siswa')
        .where('kelasId', isGreaterThanOrEqualTo: kelasId)
        .where('kelasId', isLessThan: '$kelasId\uf8ff')
        .get();

    // Langkah 2: Lakukan penyaringan cerdas di sisi aplikasi.
    final List<SiswaSimpleModel> availableStudents = [];
    final Set<String> currentMemberIds = anggotaGrup.map((s) => s.uid).toSet();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final siswa = SiswaSimpleModel.fromFirestore(doc);
      
      // Lewati siswa yang sudah ada di daftar anggota grup saat ini.
      if (currentMemberIds.contains(siswa.uid)) {
        continue;
      }
      
      // Dapatkan data grup halaqah dari dokumen siswa.
      final Map? grupData = data['grupHalaqah'] as Map?;

      // Kondisi 1: Siswa sepenuhnya tersedia (tidak punya data grup sama sekali).
      if (grupData == null) {
        availableStudents.add(siswa);
        continue; // Lanjut ke siswa berikutnya.
      }

      // Kondisi 2: (Hanya berlaku di Mode Edit)
      // Siswa memiliki data grup, tapi itu adalah grup yang sedang kita edit.
      // Ini memungkinkan siswa yang "dihapus" dari anggota untuk muncul kembali di daftar tersedia.
      if (isEditMode.value) {
        final String assignedGroupId = grupData['idGrup'] ?? '';
        if (assignedGroupId == groupId) {
          availableStudents.add(siswa);
        }
        // Jika assignedGroupId tidak sama dengan groupId, berarti siswa milik grup LAIN.
        // Dalam kasus itu, kita tidak melakukan apa-apa (dia tidak ditambahkan ke daftar).
      }
      
      // Jika bukan mode edit dan siswa punya data grup, maka dia tidak tersedia.
      // Tidak perlu ada 'else' karena kita hanya menambahkan yang memenuhi syarat.
    }
    
    // Langkah 3: Update daftar siswa yang tersedia di UI.
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
          if (checkSnapshot.docs.first.id != groupId) {
            isAlreadyAssigned = true;
          }
        } else {
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
        .collection('halaqah_grup').doc(groupId);

      // 3. Simpan/Perbarui Dokumen Grup Utama
      batch.set(groupRef, {
        'namaGrup': namaGrupC.text.trim(),
        'idPengampu': selectedPengampu.value!.uid,
        'namaPengampu': selectedPengampu.value!.nama,
        'aliasPengampu': selectedPengampu.value!.alias,
        'profileImageUrl': selectedPengampu.value!.profileImageUrl,
        'semester': semester,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // --- [PERBAIKAN KUNCI DIMULAI DI SINI] ---

      // 4. Proses Siswa yang DIHAPUS dari grup
      final finalMemberIds = anggotaGrup.map((s) => s.uid).toSet();
      final removedSiswa = _initialMembers.where((s) => !finalMemberIds.contains(s.uid)).toList();
      
      for (var siswa in removedSiswa) {
        // Hapus dari sub-koleksi 'anggota' grup
        batch.delete(groupRef.collection('anggota').doc(siswa.uid));
        // Hapus data grup dari dokumen siswa
        batch.update(_firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid), {
          fieldGrupSiswa: FieldValue.delete(),
          'grupHalaqah': FieldValue.delete(),
        });
      }

      // 4B. Proses SEMUA ANGGOTA FINAL di dalam grup
      // Loop ini akan memastikan semua anggota (lama dan baru) memiliki data grup terbaru.
      for (var siswa in anggotaGrup) {
        // a. Tambahkan/update siswa di sub-koleksi 'anggota' grup
        batch.set(groupRef.collection('anggota').doc(siswa.uid), {
          'namaSiswa': siswa.nama, 
          'kelasAsal': siswa.kelasId
        });

        // b. Tulis/Timpa data denormalisasi di dokumen utama setiap siswa
        batch.update(_firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid), {
          fieldGrupSiswa: groupRef.id, 
          'grupHalaqah': {
            'idGrup': groupRef.id,
            'namaGrup': namaGrupC.text.trim(),
            'idPengampu': selectedPengampu.value!.uid,
            'namaPengampu': selectedPengampu.value!.nama,
            'aliasPengampu': selectedPengampu.value!.alias, // Ini yang paling penting
          }
        });
      }

      // --- [PERBAIKAN KUNCI SELESAI] ---
      
      // 5. Proses Denormalisasi untuk Pengampu
      final newPengampuId = selectedPengampu.value!.uid;
      final keySemester = "$tahunAjaran\_$semester";

      if (isEditMode.value && _initialPengampuId != null && _initialPengampuId != newPengampuId) {
        final oldPengampuRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(_initialPengampuId!);
        batch.update(oldPengampuRef, {
          'grupHalaqahDiampu.$keySemester': FieldValue.arrayRemove([groupRef.id])
        });
      }
      
      final newPengampuRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(newPengampuId);
      batch.update(newPengampuRef, {
        'grupHalaqahDiampu.$keySemester': FieldValue.arrayUnion([groupRef.id])
      });
      
      // 6. Jalankan Semua Operasi
      await batch.commit();
      
      Get.back();
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