// lib/app/modules/master_ekskul_management/views/master_ekskul_management_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/ekskul_model.dart';

import '../controllers/master_ekskul_management_controller.dart';

class MasterEkskulManagementView extends GetView<MasterEkskulManagementController> {
  const MasterEkskulManagementView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Ekstrakurikuler'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamEkskul(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada ekskul untuk semester ini."));
          }
          final ekskulList = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ekskulList.length,
            itemBuilder: (context, index) {
              final ekskul = EkskulModel.fromFirestore(ekskulList[index]);
              
              // --- [FIX] Akses properti langsung dari model ---
              final List<dynamic> listPembina = ekskul.listPembina;
              final namaPembina = listPembina.map((p) => p['nama']).join(', ');
            
              return Card(
                child: ListTile(
                  title: Text(ekskul.namaEkskul),
                  subtitle: Text("Pembina: ${namaPembina.isNotEmpty ? namaPembina : 'N/A'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => controller.deleteEkskul(ekskul),
                        tooltip: "Hapus Ekskul",
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => controller.goToEditEkskul(ekskul),
                ),
              );
            },
          );
        },
      ),
      // --- [DIUBAH] Fungsikan FloatingActionButton ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToCreateEkskul,
        icon: const Icon(Icons.add),
        label: const Text("Tambah Ekskul"),
      ),
    );
  }
}