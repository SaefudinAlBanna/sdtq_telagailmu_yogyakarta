// lib/app/widgets/avatar_pengampu.dart

import 'package:flutter/material.dart';

class AvatarPengampu extends StatelessWidget {
  final String? imageUrl;
  final String nama;
  final double radius;

  const AvatarPengampu({
    Key? key,
    required this.imageUrl,
    required this.nama,
    this.radius = 25.0, // Ukuran default
  }) : super(key: key);

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> names = name.trim().split(' ');
    if (names.length > 1 && names[1].isNotEmpty) {
      // Ambil huruf pertama dari dua kata pertama
      return names[0][0].toUpperCase() + names[1][0].toUpperCase();
    } else {
      // Ambil satu atau dua huruf pertama dari satu kata
      return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah URL valid
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    // print("DEBUG AVATAR: Nama: $nama, URL: ->$imageUrl<-, HasImage: $hasImage"); //DEBUG

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.indigo.shade100,
      // Jika ada gambar, gunakan NetworkImage. Jika tidak, tampilkan null.
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      // Jika TIDAK ada gambar, tampilkan widget Text dengan inisial.
      child: !hasImage
          ? Text(
              _getInitials(nama),
              style: TextStyle(
                fontSize: radius * 0.8, // Ukuran font dinamis
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
            )
          : null,
    );
  }
}