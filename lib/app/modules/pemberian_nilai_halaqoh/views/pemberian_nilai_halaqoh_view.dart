import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../controllers/pemberian_nilai_halaqoh_controller.dart';

// Menggunakan GetView yang merupakan StatelessWidget + akses langsung ke controller
class PemberianNilaiHalaqohView extends GetView<PemberianNilaiHalaqohController> {
  PemberianNilaiHalaqohView({super.key}) {
    // Inisialisasi locale sekali saat view dibuat
    initializeDateFormatting('id_ID', null);
  }

  // --- Daftar konstan untuk dropdown agar tidak dibuat ulang setiap kali build
  static const List<String> _daftarSurat = [
    "An-Naba'", "An-Nazi'at", "Abasa", "At-Takwir", "Al-Infitar", "Al-Mutaffifin",
    "Al-Insyiqaq", "Al-Buruj", "At-Tariq", "Al-A'la", "Al-Ghasyiyah", "Al-Fajr",
    "Al-Balad", "Asy-Syams", "Al-Lail", "Ad-Duha", "Asy-Syarh",
    "At-Tin", "Al-'Alaq", "Al-Qadr", "Al-Bayyinah", "Az-Zalzalah", "Al-'Adiyat",
    "Al-Qari'ah", "At-Takasur", "Al-'Asr", "Al-Humazah", "Al-Fil", "Quraisy",
    "Al-Ma'un", "Al-Kausar", "Al-Kafirun", "An-Nasr", "Al-Masad",
    "Al-Ikhlas", "Al-Falaq", "An-Nas", "Lainnya..."
  ];
  static const List<String> _daftarNilai = ["HL'", "BL", "L"];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(context, theme),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildHeaderSection(theme),
              const SizedBox(height: 12),
              Divider(thickness: 1, color: theme.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 16),
              _buildStudentAndTeacherInfo(context, theme, controller.dataArgs),
              const SizedBox(height: 20),
              _buildDateSection(theme),
              const SizedBox(height: 20),
              _buildSabaq(context, theme),
              const SizedBox(height: 20),
              _buildSabqi(context, theme),
              const SizedBox(height: 20),
              _buildManzil(context, theme),
              const SizedBox(height: 20),
              _buildTugasTambahan(context, theme),
              const SizedBox(height: 20),
              _buildKeteranganSection(context, theme),
              const SizedBox(height: 30),
              _buildSimpanButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      title: const Text('Input Nilai Halaqoh'),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 2,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "BUKU KONTROL PEMBELAJARAN ALQUR'AN METODE AL-HUSNA",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          "SDTQ TELAGA ILMU",
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudentAndTeacherInfo(BuildContext context, ThemeData theme, Map<String, dynamic> studentData) {
    if (studentData.isEmpty) {
      return const Center(child: Text("Memuat data siswa..."));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth > 600;
        final studentInfoCard = _buildInfoCard(
          theme: theme,
          title: "Informasi Siswa",
          icon: Icons.person_pin_circle_outlined,
          children: [
            _buildInfoRow(theme, 'Nama Siswa', studentData['namasiswa'] ?? '-'),
            _buildInfoRow(theme, 'No Induk', studentData['nisn'] ?? '-'),
            _buildInfoRow(theme, 'Kelas', studentData['kelas'] ?? '-'),
          ],
        );

        final teacherInfoCard = _buildInfoCard(
          theme: theme,
          title: "Informasi Halaqoh",
          icon: Icons.school_outlined,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Capaian:', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: FutureBuilder<String?>(
                    future: controller.ambilDataAlHusna(),
                    builder: (context, snapumi) {
                      if (snapumi.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2.0));
                      }
                      if (snapumi.hasError || !snapumi.hasData || snapumi.data == null || snapumi.data!.isEmpty) {
                        return Text(snapumi.data ?? "Belum diinput", style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: snapumi.hasError ? theme.colorScheme.error : null));
                      }
                      return Text(snapumi.data!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600));
                    },
                  ),
                ),
              ],
            ),
            _buildInfoRow(theme, 'Pengampu', studentData['namapengampu'] ?? '-'),
          ],
        );

        if (isWideScreen) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: studentInfoCard),
            const SizedBox(width: 16),
            Expanded(child: teacherInfoCard),
          ]);
        } else {
          return Column(children: [
            studentInfoCard,
            const SizedBox(height: 16),
            teacherInfoCard,
          ]);
        }
      },
    );
  }

  Widget _buildInfoCard({required ThemeData theme, required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const Divider(height: 20, thickness: 0.5),
            ...children.map((child) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: child)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 4, child: Text('$label:', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      const SizedBox(width: 8),
      Expanded(flex: 6, child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
    ]);
  }

  Widget _buildDateSection(ThemeData theme) {
    return Row(children: [
      Icon(Icons.calendar_today_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 8),
      Text('Tanggal Input: ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now())}', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        Container(margin: const EdgeInsets.only(top: 5), height: 2.5, width: 70, decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(2))),
      ]),
    );
  }

  InputDecoration _commonInputDecorator(ThemeData theme, String labelText, {String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: theme.colorScheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.7))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  PopupProps<String> _popupProps(BuildContext context, ThemeData theme, String searchLabel) {
    return PopupProps.menu(
      showSearchBox: true,
      fit: FlexFit.loose,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
      searchFieldProps: TextFieldProps(decoration: _commonInputDecorator(theme, searchLabel).copyWith(hintText: 'Ketik untuk mencari...', prefixIcon: const Icon(Icons.search))),
      menuProps: MenuProps(borderRadius: BorderRadius.circular(12), elevation: 4, backgroundColor: theme.colorScheme.surfaceContainer),
    );
  }

  Widget _buildSabaq(BuildContext context, ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Sabaq / Terbaru', theme),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Obx(() => DropdownSearch<String>(
              decoratorProps: DropDownDecoratorProps(decoration: _commonInputDecorator(theme, 'Surat Hafalan / Kosongkan Jika Al-Husna', prefixIcon: const Icon(Icons.book_outlined))),
              selectedItem: controller.selectedSuratSabaq.value.isEmpty ? null : controller.selectedSuratSabaq.value,
              items: (f, cs) async => _daftarSurat,
              onChanged: (value) => controller.selectedSuratSabaq.value = value ?? '',
              popupProps: _popupProps(context, theme, 'Cari Surat'),
            )),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextField(controller: controller.sabaqC, decoration: _commonInputDecorator(theme, 'Ayat yang Dihafal / Halaman Jika Al-Husna', hintText: 'Contoh: 1-5 atau 1, 3, 5', prefixIcon: const Icon(Icons.format_list_numbered_rtl_outlined))),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Obx(() => DropdownSearch<String>(
              decoratorProps: DropDownDecoratorProps(decoration: _commonInputDecorator(theme, 'Nilai', prefixIcon: const Icon(Icons.star_border_outlined))),
              selectedItem: controller.selectedNilaiSabaq.value.isEmpty ? null : controller.selectedNilaiSabaq.value,
              items: (f, cs) async => _daftarNilai,
              onChanged: (value) => controller.selectedNilaiSabaq.value = value ?? '',
              popupProps: _popupProps(context, theme, 'Cari Nilai'),
            )),
      ),
    ]);
  }

  Widget _buildSabqi(BuildContext context, ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Sabqi / Baru', theme),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Obx(() => DropdownSearch<String>(
              decoratorProps: DropDownDecoratorProps(decoration: _commonInputDecorator(theme, 'Surat Hafalan / Kosongkan Jika Al-Husna', prefixIcon: const Icon(Icons.book_outlined))),
              selectedItem: controller.selectedSuratSabqi.value.isEmpty ? null : controller.selectedSuratSabqi.value,
              items: (f, cs) async => _daftarSurat,
              onChanged: (value) => controller.selectedSuratSabqi.value = value ?? '',
              popupProps: _popupProps(context, theme, 'Cari Surat'),
            )),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextField(controller: controller.sabqiC, decoration: _commonInputDecorator(theme, 'Ayat yang Dihafal / Halaman Jika Al-Husna', hintText: 'Contoh: 1-5 atau 1, 3, 5', prefixIcon: const Icon(Icons.format_list_numbered_rtl_outlined))),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Obx(() => DropdownSearch<String>(
              decoratorProps: DropDownDecoratorProps(decoration: _commonInputDecorator(theme, 'Nilai', prefixIcon: const Icon(Icons.star_border_outlined))),
              selectedItem: controller.selectedNilaiSabqi.value.isEmpty ? null : controller.selectedNilaiSabqi.value,
              items: (f, cs) async => _daftarNilai,
              onChanged: (value) => controller.selectedNilaiSabqi.value = value ?? '',
              popupProps: _popupProps(context, theme, 'Cari Nilai'),
            )),
      ),
    ]);
  }

  Widget _buildManzil(BuildContext context, ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Manzil / Lama', theme),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Obx(() => DropdownSearch<String>(
              decoratorProps: DropDownDecoratorProps(decoration: _commonInputDecorator(theme, 'Surat Hafalan / Kosongkan Jika Al-Husna', prefixIcon: const Icon(Icons.book_outlined))),
              selectedItem: controller.selectedSuratManzil.value.isEmpty ? null : controller.selectedSuratManzil.value,
              items: (f, cs) async => _daftarSurat,
              onChanged: (value) => controller.selectedSuratManzil.value = value ?? '',
              popupProps: _popupProps(context, theme, 'Cari Surat'),
            )),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextField(controller: controller.manzilC, decoration: _commonInputDecorator(theme, 'Ayat yang Dihafal / Halaman Jika Al-Husna', hintText: 'Contoh: 1-5 atau 1, 3, 5', prefixIcon: const Icon(Icons.format_list_numbered_rtl_outlined))),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Obx(() => DropdownSearch<String>(
              decoratorProps: DropDownDecoratorProps(decoration: _commonInputDecorator(theme, 'Nilai', prefixIcon: const Icon(Icons.star_border_outlined))),
              selectedItem: controller.selectedNilaiManzil.value.isEmpty ? null : controller.selectedNilaiManzil.value,
              items: (f, cs) async => _daftarNilai,
              onChanged: (value) => controller.selectedNilaiManzil.value = value ?? '',
              popupProps: _popupProps(context, theme, 'Cari Nilai'),
            )),
      ),
    ]);
  }

  Widget _buildTugasTambahan(BuildContext context, ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('TUGAS TAMBAHAN', theme),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextField(controller: controller.tugasTambahanC, decoration: _commonInputDecorator(theme, 'Halaman / Ayat Al-Qur\'an', hintText: 'Contoh: Jilid 3 Hal. 10 / QS. Al-Baqarah: 25', prefixIcon: const Icon(Icons.menu_book_outlined))),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Obx(() => DropdownSearch<String>(
              decoratorProps: DropDownDecoratorProps(decoration: _commonInputDecorator(theme, 'Nilai', prefixIcon: const Icon(Icons.star_border_outlined))),
              selectedItem: controller.selectedNilaiTugas.value.isEmpty ? null : controller.selectedNilaiTugas.value,
              items: (f, cs) async => _daftarNilai,
              onChanged: (value) => controller.selectedNilaiTugas.value = value ?? '',
              popupProps: _popupProps(context, theme, 'Cari Nilai'),
            )),
      ),
    ]);
  }

  Widget _buildKeteranganSection(BuildContext context, ThemeData theme) {
    final List<Map<String, String>> keteranganOptions = [
      {"title": "Sangat Baik & Lanjut", "value": "Alhamdulillah, Ananda hari ini menunjukkan pemahaman yang sangat baik dan lancar. InsyaAllah, besok bisa melanjutkan ke materi berikutnya. Barokallohu fiik."},
      {"title": "Baik & Lancar", "value": "Alhamdulillah, Ananda hari ini sudah baik dan lancar. Tetap semangat belajar ya, Nak. Barokallohu fiik."},
      {"title": "Perlu Pengulangan", "value": "Alhamdulillah, Ananda hari ini sudah ada peningkatan. Mohon untuk dipelajari kembali di rumah, materi hari ini akan kita ulangi pada pertemuan berikutnya. Semangat!"},
      {"title": "Butuh Perhatian Khusus", "value": "Ananda hari ini membutuhkan perhatian lebih pada materi [...]. Mohon bantuan Ayah/Bunda untuk mendampingi belajar di rumah."}
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('CATATAN PENGAMPU', theme),
      Obx(() => Column(
            children: keteranganOptions.map((option) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: RadioListTile<String>(
                  title: Text(option['title']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(option['value']!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 3, overflow: TextOverflow.ellipsis),
                  value: option['value']!,
                  groupValue: controller.keteranganHalaqoh.value,
                  onChanged: controller.onChangeKeterangan,
                  activeColor: theme.colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  tileColor: controller.keteranganHalaqoh.value == option['value'] ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                  dense: true,
                ),
              );
            }).toList(),
          )),
    ]);
  }

  Widget _buildSimpanButton(BuildContext context) {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: controller.isLoading.value
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.save_alt_outlined),
            label: Text(controller.isLoading.value ? 'Menyimpan...' : 'Simpan Nilai'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: controller.isLoading.value ? null : controller.simpanNilai,
          ),
        ));
  }
}