// lib/app/models/halaqah_group_with_count_model.dart


import 'halaqah_group_model.dart';

class HalaqahGroupWithCount extends HalaqahGroupModel {
  final int memberCount;

  HalaqahGroupWithCount({
    required String id,
    required String namaGrup,
    required String idPengampu,
    required String namaPengampu,
    required String aliasPengampu, // [DIUBAH] Tambahkan parameter yang dibutuhkan super
    required String semester,      // [DIUBAH] Tambahkan parameter yang dibutuhkan super
    String? profileImageUrl, 
    this.memberCount = 0,
  }) : super(
          id: id,
          namaGrup: namaGrup,
          idPengampu: idPengampu,
          namaPengampu: namaPengampu,
          aliasPengampu: aliasPengampu, // [DIUBAH] Teruskan ke super
          semester: semester,          // [DIUBAH] Teruskan ke super
          profileImageUrl: profileImageUrl,
        );
}