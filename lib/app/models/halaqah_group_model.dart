import 'package:cloud_firestore/cloud_firestore.dart';

class HalaqahGroupModel {
  final String id;
  final String namaGrup;
  final String idPengampu;
  final String namaPengampu;
  final String aliasPengampu;
  final String semester;
  // [MODIFIKASI] Jadikan field ini non-final agar bisa di-override
  // oleh strategi di dashboard controller yang lebih baru.
  // Namun, kita akan utamakan penggunaan copyWith.
  String? profileImageUrl;
  bool isPengganti;

  HalaqahGroupModel({
    required this.id,
    required this.namaGrup,
    required this.idPengampu,
    required this.namaPengampu,
    required this.aliasPengampu,
    required this.semester,
    this.profileImageUrl,
    this.isPengganti = false,
  });

  factory HalaqahGroupModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HalaqahGroupModel(
      id: doc.id,
      namaGrup: data['namaGrup'] ?? 'Tanpa Nama Grup',
      idPengampu: data['idPengampu'] ?? '',
      namaPengampu: data['namaPengampu'] ?? 'Belum ada pengampu',
      aliasPengampu: data['aliasPengampu'] ?? 'N/A',
      semester: data['semester'] ?? 'N/A',
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // --- [SENJATA BARU] Metode copyWith ---
  // Metode ini membuat salinan objek HalaqahGroupModel,
  // memungkinkan kita untuk menimpa nilai field tertentu.
  HalaqahGroupModel copyWith({
    String? id,
    String? namaGrup,
    String? idPengampu,
    String? namaPengampu,
    String? aliasPengampu,
    String? semester,
    String? profileImageUrl,
    bool? isPengganti,
  }) {
    return HalaqahGroupModel(
      id: id ?? this.id,
      namaGrup: namaGrup ?? this.namaGrup,
      idPengampu: idPengampu ?? this.idPengampu,
      namaPengampu: namaPengampu ?? this.namaPengampu,
      aliasPengampu: aliasPengampu ?? this.aliasPengampu,
      semester: semester ?? this.semester,
      // Jika profileImageUrl baru disediakan, gunakan itu. Jika tidak, gunakan yang lama.
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isPengganti: isPengganti ?? this.isPengganti,
    );
  }
}