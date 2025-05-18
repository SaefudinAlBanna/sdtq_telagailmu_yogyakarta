import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/tambah_kelompok_mengaji_controller.dart';

class TambahKelompokMengajiView
    extends GetView<TambahKelompokMengajiController> {
  const TambahKelompokMengajiView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TambahKelompokMengajiView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'TambahKelompokMengajiView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
