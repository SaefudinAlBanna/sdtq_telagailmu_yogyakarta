// lib/app/models/rapor_model.dart (VERSI LENGKAP & FINAL DEFINITIF)

import 'package:cloud_firestore/cloud_firestore.dart';

// == KELAS UTAMA UNTUK DOKUMEN RAPOR ==
class RaporModel {
  final String id;
  final String idSekolah;
  final String idTahunAjaran;
  final String idKelas;
  final String semester;
  final DateTime tanggalGenerate;
  final String idWaliKelas;
  final String namaWaliKelas;
  final String idSiswa;
  final String namaSiswa;
  final String nisn;
  final String namaOrangTua;
  final List<NilaiMapelRapor> daftarNilaiMapel;
  final DataHalaqahRapor dataHalaqah;
  final List<DataEkskulRapor> daftarEkskul;
  final RekapAbsensi rekapAbsensi;
  final String catatanWaliKelas;
  final bool isShared;

  RaporModel({
    required this.id, required this.idSekolah, required this.idTahunAjaran,
    required this.idKelas, required this.semester, required this.tanggalGenerate,
    required this.idWaliKelas, required this.namaWaliKelas, required this.idSiswa,
    required this.namaSiswa, required this.nisn, required this.namaOrangTua, 
    required this.daftarNilaiMapel,
    required this.dataHalaqah, required this.daftarEkskul, required this.rekapAbsensi,
    required this.catatanWaliKelas, this.isShared = false,
  });
  
  RaporModel copyWith({bool? isShared}) {
    return RaporModel(
      id: id, idSekolah: idSekolah, idTahunAjaran: idTahunAjaran, idKelas: idKelas,
      semester: semester, tanggalGenerate: tanggalGenerate, idWaliKelas: idWaliKelas,
      namaWaliKelas: namaWaliKelas, idSiswa: idSiswa, namaSiswa: namaSiswa, nisn: nisn,
      namaOrangTua: namaOrangTua,
      daftarNilaiMapel: daftarNilaiMapel, dataHalaqah: dataHalaqah,
      daftarEkskul: daftarEkskul, rekapAbsensi: rekapAbsensi,
      catatanWaliKelas: catatanWaliKelas, isShared: isShared ?? this.isShared,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 'idSekolah': idSekolah, 'idTahunAjaran': idTahunAjaran,
      'idKelas': idKelas, 'semester': semester,
      'tanggalGenerate': Timestamp.fromDate(tanggalGenerate),
      'idWaliKelas': idWaliKelas, 'namaWaliKelas': namaWaliKelas,
      'idSiswa': idSiswa, 'namaSiswa': namaSiswa, 'nisn': nisn,
      'namaOrangTua': namaOrangTua,
      'daftarNilaiMapel': daftarNilaiMapel.map((e) => e.toJson()).toList(),
      'dataHalaqah': dataHalaqah.toJson(),
      'daftarEkskul': daftarEkskul.map((e) => e.toJson()).toList(),
      'rekapAbsensi': rekapAbsensi.toJson(),
      'catatanWaliKelas': catatanWaliKelas, 'isShared': isShared,
    };
  }

  factory RaporModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RaporModel(
      id: data['id'] ?? '',
      idSekolah: data['idSekolah'] ?? '',
      idTahunAjaran: data['idTahunAjaran'] ?? '',
      idKelas: data['idKelas'] ?? '',
      semester: data['semester'] ?? '',
      tanggalGenerate: (data['tanggalGenerate'] as Timestamp? ?? Timestamp.now()).toDate(),
      idWaliKelas: data['idWaliKelas'] ?? '',
      namaWaliKelas: data['namaWaliKelas'] ?? '',
      idSiswa: data['idSiswa'] ?? '',
      namaSiswa: data['namaSiswa'] ?? '',
      nisn: data['nisn'] ?? '',
      namaOrangTua: data['namaOrangTua'] ?? '',
      daftarNilaiMapel: (data['daftarNilaiMapel'] as List<dynamic>? ?? [])
          .map((item) => NilaiMapelRapor.fromJson(item as Map<String, dynamic>))
          .toList(),
      dataHalaqah: DataHalaqahRapor.fromJson(data['dataHalaqah'] as Map<String, dynamic>? ?? {}),
      daftarEkskul: (data['daftarEkskul'] as List<dynamic>? ?? [])
          .map((item) => DataEkskulRapor.fromJson(item as Map<String, dynamic>))
          .toList(),
      rekapAbsensi: RekapAbsensi.fromJson(data['rekapAbsensi'] as Map<String, dynamic>? ?? {}),
      catatanWaliKelas: data['catatanWaliKelas'] ?? '',
      isShared: data['isShared'] ?? false,
    );
  }
}

// == SUB-MODEL DENGAN FACTORY CONSTRUCTOR LENGKAP ==

class NilaiMapelRapor {
  final String idMapel;
  final String namaMapel;
  final String namaGuru;
  final double nilaiAkhir;
  final String deskripsiCapaian;

  NilaiMapelRapor({ required this.idMapel, required this.namaMapel, required this.namaGuru, required this.nilaiAkhir, required this.deskripsiCapaian, });

  Map<String, dynamic> toJson() => {
    'idMapel': idMapel, 'namaMapel': namaMapel, 'namaGuru': namaGuru,
    'nilaiAkhir': nilaiAkhir, 'deskripsiCapaian': deskripsiCapaian,
  };

  factory NilaiMapelRapor.fromJson(Map<String, dynamic> json) {
    return NilaiMapelRapor(
      idMapel: json['idMapel'] ?? '',
      namaMapel: json['namaMapel'] ?? '',
      namaGuru: json['namaGuru'] ?? '',
      nilaiAkhir: (json['nilaiAkhir'] as num?)?.toDouble() ?? 0.0,
      deskripsiCapaian: json['deskripsiCapaian'] ?? '',
    );
  }
}

class DataHalaqahRapor {
  final String tingkatan;
  final String pencapaian;
  final int? nilaiAkhir;
  final String catatan;

  DataHalaqahRapor({ required this.tingkatan, required this.pencapaian, this.nilaiAkhir, required this.catatan, });

  Map<String, dynamic> toJson() => {
    'tingkatan': tingkatan, 'pencapaian': pencapaian,
    'nilaiAkhir': nilaiAkhir, 'catatan': catatan,
  };

  factory DataHalaqahRapor.fromJson(Map<String, dynamic> json) {
    return DataHalaqahRapor(
      tingkatan: json['tingkatan'] ?? '',
      pencapaian: json['pencapaian'] ?? '',
      nilaiAkhir: json['nilaiAkhir'] as int?,
      catatan: json['catatan'] ?? '',
    );
  }
}

class DataEkskulRapor {
  final String namaEkskul;
  final String nilai;
  final String catatan;

  DataEkskulRapor({ required this.namaEkskul, required this.nilai, required this.catatan, });

  Map<String, dynamic> toJson() => {
    'namaEkskul': namaEkskul, 'nilai': nilai, 'catatan': catatan,
  };

  factory DataEkskulRapor.fromJson(Map<String, dynamic> json) {
    return DataEkskulRapor(
      namaEkskul: json['namaEkskul'] ?? '',
      nilai: json['nilai'] ?? '',
      catatan: json['catatan'] ?? '',
    );
  }
}

class RekapAbsensi {
  final int sakit;
  final int izin;
  final int alpa;

  RekapAbsensi({ required this.sakit, required this.izin, required this.alpa, });

  Map<String, dynamic> toJson() => {
    'sakit': sakit, 'izin': izin, 'alpa': alpa,
  };

  factory RekapAbsensi.fromJson(Map<String, dynamic> json) {
    return RekapAbsensi(
      sakit: json['sakit'] ?? 0,
      izin: json['izin'] ?? 0,
      alpa: json['alpa'] ?? 0,
    );
  }
}