import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/tambah_pegawai_controller.dart';

class TambahPegawaiView extends GetView<TambahPegawaiController> {
  const TambahPegawaiView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TambahPegawaiView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'TambahPegawaiView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
