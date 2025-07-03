// views/info_sekolah_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../controllers/info_sekolah_detail_controller.dart';

class InfoSekolahDetailView extends GetView<InfoSekolahDetailController> {
  const InfoSekolahDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final data = controller.infoData.value;
    final String judul = data['judulinformasi'] ?? 'Tanpa Judul';
    final String isi = data['informasisekolah'] ?? '';
    final String penulis = data['namapenginput'] ?? 'Admin';
    final String jabatan = data['jabatanpenginput'] ?? '';
    final String? imageUrl = data['imageUrl'];
    final DateTime tanggal = DateTime.parse(data['tanggalinput']);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(judul, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center,),
              centerTitle: true,
              background: imageUrl != null && imageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(imageUrl, fit: BoxFit.cover),
                        // Gradien gelap agar judul lebih terbaca
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(color: Theme.of(context).primaryColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Penulis ---
                  Row(
                    children: [
                      const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(penulis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(jabatan, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      Text(timeago.format(tanggal, locale: 'id'), style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // --- Isi Konten ---
                  Text(
                    isi,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}