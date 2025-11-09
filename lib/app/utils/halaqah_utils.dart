// lib/app/utils/halaqah_utils.dart

import 'package:flutter/material.dart';

class HalaqahUtils {
  // Data terpusat untuk semua tingkatan
  static const List<String> daftarTingkatan = [
    'Al-Husna', 'Juz-i',
    'Juz 30', 'Juz 29', 'Juz 28', 'Juz 27', 'Juz 26',
    'Juz 25', 'Juz 24', 'Juz 23', 'Juz 22', 'Juz 21',
    'Juz 20', 'Juz 19', 'Juz 18', 'Juz 17', 'Juz 16',
    'Juz 15', 'Juz 14', 'Juz 13', 'Juz 12', 'Juz 11',
    'Juz 10', 'Juz 9', 'Juz 8', 'Juz 7', 'Juz 6',
    'Juz 5', 'Juz 4', 'Juz 3', 'Juz 2', 'Juz 1',
  ];

  // Skema warna yang telah kita sepakati
  static Color getWarnaTingkatan(String? namaTingkatan) {
    switch (namaTingkatan) {
      // Dasar & Transisi
      case 'Al-Husna': return const Color(0xFF2ECC71); // Hijau Zamrud
      case 'Juz-i': return const Color(0xFF3498DB);    // Biru Langit

      // Hafalan Awal (Bumi & Perunggu)
      case 'Juz 30': return const Color(0xFFCD7F32); // Perunggu
      case 'Juz 29': return const Color(0xFFE77E23); // Coklat Terakota
      case 'Juz 28': return const Color(0xFFD35400); // Oranye Labu
      case 'Juz 27': return const Color(0xFFC0392B); // Merah Bata
      case 'Juz 26': return const Color(0xFF9B59B6); // Merah Anggur

      // Hafalan Pertengahan (Lautan & Perak)
      case 'Juz 25': return const Color(0xFF8E44AD); // Ungu Ametis
      case 'Juz 20': return const Color(0xFF2980B9); // Biru Laut Dalam
      case 'Juz 15': return const Color(0xFFBDC3C7); // Perak Cerah

      // Hafalan Lanjutan (Cahaya & Emas)
      case 'Juz 10': return const Color(0xFFF1C40F); // Kuning Lemon
      case 'Juz 1': return const Color(0xFFFFD700);  // Emas Murni

      // Gradasi halus untuk sisanya
      case 'Juz 24': case 'Juz 23': case 'Juz 22': case 'Juz 21': return Colors.purple.shade300;
      case 'Juz 19': case 'Juz 18': case 'Juz 17': case 'Juz 16': return Colors.blueGrey.shade300;
      case 'Juz 14': case 'Juz 13': case 'Juz 12': case 'Juz 11': return Colors.yellow.shade300;
      case 'Juz 9': case 'Juz 8': case 'Juz 7': case 'Juz 6': case 'Juz 5': case 'Juz 4': case 'Juz 3': case 'Juz 2': return Colors.amber.shade600;

      default: return Colors.grey.shade400; // Warna default
    }
  }
}