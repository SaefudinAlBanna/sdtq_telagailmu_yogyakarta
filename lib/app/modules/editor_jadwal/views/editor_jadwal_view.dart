// lib/app/modules/editor_jadwal/views/editor_jadwal_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_jadwal_controller.dart';

class EditorJadwalView extends GetView<EditorJadwalController> {
  const EditorJadwalView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Jadwal Pelajaran'),
        actions: [
          Obx(() => controller.isSaving.value
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(icon: const Icon(Icons.save), onPressed: controller.simpanJadwal)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedKelasId.value,
              hint: const Text('Pilih Kelas'),
              items: controller.daftarKelas.map((k) => DropdownMenuItem<String>(value: k['id'], child: Text(k['nama']))).toList(),
              onChanged: controller.onKelasChanged,
            )),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.selectedKelasId.value == null) return const Expanded(child: Center(child: Text('Pilih kelas untuk memulai.')));
              if (controller.isLoadingJadwal.value) return const Expanded(child: Center(child: CircularProgressIndicator()));
              return Expanded(child: _buildScheduleEditor());
            }),
          ],
        ),
      ),
      floatingActionButton: Obx(() => controller.selectedKelasId.value != null && !controller.isLoadingJadwal.value
          ? FloatingActionButton(onPressed: controller.tambahPelajaran, child: const Icon(Icons.add))
          : const SizedBox.shrink()),
    );
  }

  Widget _buildScheduleEditor() {
    return Column(children: [
      DropdownButtonFormField<String>(
        value: controller.selectedHari.value,
        items: controller.daftarHari.map((h) => DropdownMenuItem<String>(value: h, child: Text(h))).toList(),
        onChanged: (v) => controller.selectedHari.value = v!,
      ),
      const SizedBox(height: 16),
      Expanded(child: Obx(() {
        final listPelajaran = controller.jadwalPelajaran[controller.selectedHari.value]!;
        if (listPelajaran.isEmpty) return const Center(child: Text('Jadwal kosong. Klik + untuk menambah.'));
        listPelajaran.sort((a,b) => (a['jam'] as String? ?? 'Z').compareTo((b['jam'] as String? ?? 'Z')));
        
        return ListView.builder(
          itemCount: listPelajaran.length,
          itemBuilder: (context, index) => _buildPelajaranCard(listPelajaran[index], index),
        );
      })),
    ]);
  }

  Widget _buildPelajaranCard(Map<String, dynamic> pelajaran, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Slot ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.hapusPelajaran(index)),
          ]),
          DropdownButtonFormField<String>(
            value: pelajaran['jam'],
            items: controller.daftarJam.map((j) => DropdownMenuItem<String>(value: j['waktu'], child: Text(j['label']))).toList(),
            onChanged: (v) => controller.updatePelajaran(index, 'jam', v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: pelajaran['idMapel'],
            items: controller.daftarMapelTersedia.map((m) => DropdownMenuItem<String>(value: m['idMapel'], child: Text(m['nama']))).toList(),
            onChanged: (v) => controller.updatePelajaran(index, 'idMapel', v),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final idMapelTerpilih = pelajaran['idMapel'];
            final guruUntukMapelIni = controller.daftarGuruTersedia.where((g) => g['idMapel'] == idMapelTerpilih).toList();
            return DropdownButtonFormField<String>(
              value: pelajaran['idGuru'],
              items: guruUntukMapelIni.map((g) => DropdownMenuItem<String>(value: g['uid'], 
              child: Text(g['alias']))).toList(),
              onChanged: (v) => controller.updatePelajaran(index, 'idGuru', v),
            );
          }),
        ]),
      ),
    );
  }
}