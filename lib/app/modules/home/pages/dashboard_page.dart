// lib/app/modules/home/pages/dashboard_page.dart (FINAL DENGAN TATA LETAK YANG BENAR)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/dashboard_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/carousel_item_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';
import 'package:timeago/timeago.dart' as timeago;

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final configC = Get.find<ConfigController>();

    return Obx(() {
      final List<Map<String, dynamic>> quickAccessMenus = [
        {'image': 'daftar_tes.png', 'title': 'Guru Akademik', 'route': Routes.GURU_AKADEMIK},
        if (controller.canManageHalaqah)
          {'image': 'daftar_tes.png', 'title': 'Manajemen Halaqah', 'onTap': controller.goToHalaqahManagement},
        if (controller.isPengampuHalaqah)
          {'image': 'daftar_tes.png', 'title': 'Dashboard Halaqah', 'onTap': controller.goToHalaqahDashboard},
        if (controller.isPimpinan)
          {'image': 'papan_list.png', 'title': 'Rekap Absensi', 'onTap': controller.goToRekapAbsensiSekolah},
        {'image': 'toga_lcd.png', 'title': 'Pemberian Kelas', 'route': Routes.PEMBERIAN_KELAS_SISWA},
        {'image': 'papan_list.png', 'title': 'Master Mapel', 'route': Routes.MASTER_MAPEL},
        {'image': 'list_nilai.png', 'title': 'Penugasan Guru', 'route': Routes.PENUGASAN_GURU},
        {'image': 'layar.png', 'title': 'Jadwal Pelajaran', 'route': Routes.EDITOR_JADWAL},
        {'image': 'faq.png', 'title': 'Lainnya', 'onTap': () => _showAllMenus(context)},
      ];

      return Scaffold(
        body: CustomScrollView(
          slivers: [
            // --- BAGIAN 1: SliverAppBar (Tidak Berubah) ---
            SliverAppBar(
              expandedHeight: 220.0, floating: false, pinned: true,
              backgroundColor: Colors.indigo.shade800,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset("assets/webp/profile.webp", fit: BoxFit.contain),
                    Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                    Padding(
                      padding: const EdgeInsets.only(top: 60.0, bottom: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 42, backgroundColor: Colors.white.withOpacity(0.3),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundImage: configC.infoUser['profileImageUrl'] != null ? NetworkImage(configC.infoUser['profileImageUrl']) : null,
                              backgroundColor: Colors.indigo.shade400,
                              child: configC.infoUser['profileImageUrl'] == null ? Text((configC.infoUser['nama'] ?? "U")[0].toUpperCase(), style: const TextStyle(fontSize: 30, color: Colors.white)) : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(configC.infoUser['nama'] ?? 'Nama Pengguna', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black45)])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- [PERBAIKAN] BAGIAN 2: Menu Akses Cepat (Dikembalikan ke Atas) ---
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                child: Text("Menu Akses Cepat", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0, childAspectRatio: 0.9,
                ),
                delegate: SliverChildListDelegate(
                  quickAccessMenus.map((menu) => _buildMenuItem(
                    imagePath: menu['image'], title: menu['title'],
                    onTap: menu.containsKey('route') ? () => Get.toNamed(menu['route']) : menu['onTap'],
                  )).toList(),
                ),
              ),
            ),

            // --- [PERBAIKAN] BAGIAN 3: Papan Informasi / Carousel (Dikembalikan ke Tengah) ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // const Text("Papan Informasi Hari Ini", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Obx(() => controller.isPimpinan
                        ? IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.grey),
                            onPressed: controller.showPesanEditorDialog,
                            tooltip: "Edit Pesan Dasbor",
                          )
                        : const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                if (controller.isCarouselLoading.value) {
                  return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
                }
                if (controller.daftarCarousel.isEmpty) {
                  return const SizedBox(height: 160, child: Center(child: Text("Tidak ada informasi untuk ditampilkan.")));
                }
                return CarouselSlider.builder(
                  itemCount: controller.daftarCarousel.length,
                  itemBuilder: (context, index, realIndex) {
                    final item = controller.daftarCarousel[index];
                    return _buildCarouselCard(item);
                  },
                  options: CarouselOptions(
                    height: 160, autoPlay: controller.daftarCarousel.length > 1,
                    autoPlayInterval: const Duration(seconds: 10),
                    enlargeCenterPage: true, viewportFraction: 0.9,
                    aspectRatio: 16 / 9,
                  ),
                );
              }),
            ),// Beri ruang di bagian paling bawah
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

             _SectionHeader(
              title: "Informasi Sekolah",
              onSeeAll: () => Get.toNamed(Routes.INFO_SEKOLAH), // Arahkan ke halaman daftar lengkap
            ),

            // --- [WIDGET BARU #2] Daftar 5 Informasi Terbaru ---
            _InformasiList(),

            // Beri ruang di bagian paling bawah
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      );
    });
  }

   Widget _SectionHeader({required String title, required VoidCallback onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(onPressed: onSeeAll, child: const Text("Lihat Semua")),
          ],
        ),
      ),
    );
  }

  Widget _InformasiList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.streamInfoDashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Belum ada informasi.'))));
        }
        final daftarInfo = snapshot.data!.docs;
        
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = daftarInfo[index];
                final data = doc.data();
                final timestamp = data['timestamp'] as Timestamp?;
                final tanggal = timestamp?.toDate() ?? DateTime.now();
                final imageUrl = data['imageUrl'] as String? ?? '';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Get.toNamed(Routes.INFO_SEKOLAH_DETAIL, arguments: doc.id),
                    child: Row(
                      children: [
                        // BAGIAN GAMBAR
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(color: Colors.grey.shade200),
                            errorWidget: (c, u, e) => Container(color: Colors.grey.shade200, child: const Icon(Icons.newspaper, color: Colors.grey)),
                          ),
                        ),
                        // BAGIAN TEKS
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(data['judul'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(data['isi'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_filled, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    // --- [PERBAIKAN] Menggunakan timeago ---
                                    Text(timeago.format(tanggal, locale: 'id'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: daftarInfo.length,
            ),
          ),
        );
      },
    );
  }

  // --- SEMUA HELPER WIDGET (TIDAK ADA PERUBAHAN) ---
  Widget _buildCarouselCard(CarouselItemModel item) {
    return Card(
      elevation: 4, shadowColor: item.warna.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [item.warna.withOpacity(0.8), item.warna], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(item.ikon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.judul.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(item.namaKelas, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              const Spacer(),
              Text(item.isi, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (item.subJudul != null && item.subJudul!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(item.subJudul!, style: const TextStyle(fontSize: 12, color: Colors.white70))),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuItem({required String imagePath, required String title, VoidCallback? onTap}) {
    bool isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      // --- PERBAIKAN DIMULAI DI SINI ---
      // 1. Bungkus Column dengan SingleChildScrollView.
      // Ini akan mencegah error "RenderFlex overflowed" jika teks terlalu panjang.
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // Mencegah scroll di dalam tombol
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)],
              ),
              child: Image.asset(
                'assets/png/$imagePath',
                width: 32,
                height: 32,
                color: isEnabled ? null : Colors.grey.shade400,
                // 2. Tambahan: errorBuilder untuk menangani jika ikon tidak ditemukan
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 32, color: Colors.grey);
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.2,
                color: isEnabled ? Colors.black87 : Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      // --- AKHIR DARI PERBAIKAN ---
    );
  }
  
  void _showAllMenus(BuildContext context) {
    // Definisikan menu-menu tambahan di sini
    final List<Map<String, dynamic>> additionalMenus = [
      {'image': 'daftar_list.png', 'title': 'Siswa', 'route': Routes.DAFTAR_SISWA},
      {'image': 'daftar_list.png', 'title': 'Pegawai', 'route': Routes.PEGAWAI},
      {'image': 'daftar_list.png', 'title': 'Master jam', 'route': Routes.MASTER_JAM},
      {'image': 'play.png', 'title': 'jurnal ajar', 'route': Routes.JURNAL_HARIAN_GURU},
      {'image': 'kamera_layar.png', 'title': 'rekap absensi', 'route': Routes.REKAP_ABSENSI},
      {'image': 'pengumuman.png', 'title': 'Info Sekolah', 'route': null /* Ganti dengan Routes.INFO_SEKOLAH nanti */},
      {'image': 'uang.png', 'title': 'Bayar SPP', 'route': null},
      {'image': 'ktp.png', 'title': 'Tahsin/Tahfidz', 'route': null},
      //  if (controller.canManageEkskul)
      {'image': 'update_waktu.png', 'title': 'Pendaftaran Ekskul', 'onTap': controller.goToEkskulPendaftaran},
      {'image': 'update_waktu.png', 'title': 'Pendaftaran Ekskul', 'route': Routes.EKSKUL_PENDAFTARAN_MANAGEMENT},
      {'image': 'kamera_layar.png', 'title': 'Master Ekskul', 'route': Routes.MASTER_EKSKUL_MANAGEMENT},
      //  if (controller.canManageKbm)
      {'image': 'pengumuman.png', 'title': 'Atur Guru Pengganti', 'route': Routes.ATUR_PENGGANTIAN_HOST},
      {'image': 'ktp.png', 'title': 'Laporan Pengganti', 'route': Routes.PUSAT_INFORMASI_PENGGANTIAN},
      {'image': 'jurnal_ajar.png', 'title': 'Jurnal Pribadi', 'route': Routes.LAPORAN_JURNAL_PRIBADI},
      {'image': 'kamera_layar.png', 'title': 'Jurnal kelas', 'route': Routes.LAPORAN_JURNAL_KELAS},
      {'image': 'akademik_2.png', 'title': 'Kalender akademik', 'route': Routes.MANAJEMEN_KALENDER_AKADEMIK},
      {'image': 'akademik_2.png', 'title': 'info sekolah', 'route': Routes.INFO_SEKOLAH},
      {'image': 'akademik_2.png', 'title': 'info sekolah form', 'route': Routes.INFO_SEKOLAH_FORM},
      {'image': 'abc_papan.png', 'title': 'perangkat ajar', 'route': Routes.PERANGKAT_AJAR},
      // Tambahkan menu lainnya di sini sesuai kebutuhan
    ];

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.4, // Sesuaikan tinggi
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle drag
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const Text("Semua Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Grid untuk menu tambahan
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: additionalMenus.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final menu = additionalMenus[index];
                  return _buildMenuItem(
                    imagePath: menu['image'],
                    title: menu['title'],
                    onTap: menu['route'] != null ? () => Get.toNamed(menu['route']) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}