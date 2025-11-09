// lib/app/models/atp_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AtpModel {
  String idAtp;
  String idSekolah;
  String idPenyusun;
  String namaPenyusun;
  final String idTahunAjaran;
  final String idMapel; 
  final String namaMapel;
  final String fase;
  final int kelas;
  final String capaianPembelajaran;
  Timestamp createdAt;
  Timestamp lastModified;
  final List<UnitPembelajaran> unitPembelajaran;

  AtpModel({
    required this.idAtp,
    required this.idSekolah,
    required this.idPenyusun,
    required this.namaPenyusun,
    required this.idTahunAjaran,
    required this.idMapel, 
    required this.namaMapel,
    required this.fase,
    required this.kelas,
    required this.capaianPembelajaran,
    required this.createdAt,
    required this.lastModified,
    required this.unitPembelajaran,
  });

  factory AtpModel.fromJson(Map<String, dynamic> json) {
    return AtpModel(
      idAtp: json['idAtp'] ?? '',
      idSekolah: json['idSekolah'] ?? '',
      idPenyusun: json['idPenyusun'] ?? '',
      namaPenyusun: json['namaPenyusun'] ?? '',
      idTahunAjaran: json['idTahunAjaran'] ?? '',
      idMapel: json['idMapel'] ?? '', 
      namaMapel: json['namaMapel'] ?? '',
      fase: json['fase'] ?? '',
      kelas: json['kelas'] ?? 0,
      capaianPembelajaran: json['capaianPembelajaran'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      lastModified: json['lastModified'] ?? Timestamp.now(),
      unitPembelajaran: (json['unitPembelajaran'] as List<dynamic>? ?? [])
          .map((unit) => UnitPembelajaran.fromJson(unit))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idAtp': idAtp,
      'idSekolah': idSekolah,
      'idPenyusun': idPenyusun,
      'namaPenyusun': namaPenyusun,
      'idTahunAjaran': idTahunAjaran,
      'idMapel': idMapel, 
      'namaMapel': namaMapel,
      'fase': fase,
      'kelas': kelas,
      'capaianPembelajaran': capaianPembelajaran,
      'createdAt': createdAt,
      'lastModified': lastModified,
      'unitPembelajaran': unitPembelajaran.map((unit) => unit.toJson()).toList(),
    };
  }
  
  // Fungsi copyWith tidak perlu diubah karena sudah menangani field dengan benar
  AtpModel copyWith({String? idAtp, String? idTahunAjaran}) {
    return AtpModel(
      idAtp: idAtp ?? this.idAtp,
      idSekolah: this.idSekolah,
      idPenyusun: this.idPenyusun,
      namaPenyusun: this.namaPenyusun,
      idTahunAjaran: idTahunAjaran ?? this.idTahunAjaran,
      idMapel: this.idMapel, // Pastikan field baru ikut disalin
      namaMapel: this.namaMapel,
      fase: this.fase,
      kelas: this.kelas,
      capaianPembelajaran: this.capaianPembelajaran,
      createdAt: Timestamp.now(),
      lastModified: Timestamp.now(),
      unitPembelajaran: this.unitPembelajaran.map((e) => e.copyWith()).toList(),
    );
  }
}

// Class UnitPembelajaran dan AlurPembelajaran tidak perlu diubah.
class UnitPembelajaran {
  final String idUnit;
  final int urutan;
  final String lingkupMateri;
  final String jenisTeks;
  final String gramatika;
  final String alokasiWaktu;
  final List<String> tujuanPembelajaran;
  final List<AlurPembelajaran> alurPembelajaran;
  int? semester;
  String? bulan;

  UnitPembelajaran({
    required this.idUnit,
    required this.urutan,
    required this.lingkupMateri,
    required this.jenisTeks,
    required this.gramatika,
    required this.alokasiWaktu,
    required this.tujuanPembelajaran,
    required this.alurPembelajaran,
    this.semester,
    this.bulan,
  });

  factory UnitPembelajaran.fromJson(Map<String, dynamic> json) {
    return UnitPembelajaran(
      idUnit: json['idUnit'] ?? '',
      urutan: json['urutan'] ?? 0,
      lingkupMateri: json['lingkupMateri'] ?? '',
      jenisTeks: json['jenisTeks'] ?? '',
      gramatika: json['gramatika'] ?? '',
      alokasiWaktu: json['alokasiWaktu'] ?? '',
      tujuanPembelajaran: List<String>.from(json['tujuanPembelajaran'] ?? []),
      alurPembelajaran: (json['alurPembelajaran'] as List<dynamic>? ?? [])
          .map((alur) => AlurPembelajaran.fromJson(alur))
          .toList(),
      semester: json['semester'],
      bulan: json['bulan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idUnit': idUnit,
      'urutan': urutan,
      'lingkupMateri': lingkupMateri,
      'jenisTeks': jenisTeks,
      'gramatika': gramatika,
      'alokasiWaktu': alokasiWaktu,
      'tujuanPembelajaran': tujuanPembelajaran,
      'alurPembelajaran': alurPembelajaran.map((alur) => alur.toJson()).toList(),
      'semester': semester,
      'bulan': bulan,
    };
  }
    
  UnitPembelajaran copyWith() {
    return UnitPembelajaran(
      idUnit: this.idUnit,
      urutan: this.urutan,
      lingkupMateri: this.lingkupMateri,
      jenisTeks: this.jenisTeks,
      gramatika: this.gramatika,
      alokasiWaktu: this.alokasiWaktu,
      tujuanPembelajaran: List<String>.from(this.tujuanPembelajaran),
      alurPembelajaran: this.alurPembelajaran.map((e) => e.copyWith()).toList(),
    );
  }
}

class AlurPembelajaran {
  final int urutan;
  final String deskripsi;

  AlurPembelajaran({required this.urutan, required this.deskripsi});

  factory AlurPembelajaran.fromJson(Map<String, dynamic> json) {
    return AlurPembelajaran(
      urutan: json['urutan'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urutan': urutan,
      'deskripsi': deskripsi,
    };
  }
    
  AlurPembelajaran copyWith() {
      return AlurPembelajaran(
      urutan: this.urutan,
      deskripsi: this.deskripsi,
      );
  }
}