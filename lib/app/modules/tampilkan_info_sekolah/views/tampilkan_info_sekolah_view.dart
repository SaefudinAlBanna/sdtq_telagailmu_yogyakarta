import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/tampilkan_info_sekolah_controller.dart';

class TampilkanInfoSekolahView extends GetView<TampilkanInfoSekolahController> {
  const TampilkanInfoSekolahView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TampilkanInfoSekolahView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'TampilkanInfoSekolahView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
