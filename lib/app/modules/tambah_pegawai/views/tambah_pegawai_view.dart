// lib/app/modules/tambah_pegawai/views/tambah_pegawai_view.dart
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import '../controllers/tambah_pegawai_controller.dart';

class TambahPegawaiView extends GetView<TambahPegawaiController> {
  const TambahPegawaiView({super.key});

  @override
  Widget build(BuildContext context) {
    // Panggil controller untuk inisialisasi (jika belum ter-inject)
    // Get.find<TambahPegawaiController>(); // Tidak perlu jika binding sudah benar

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pegawai Baru'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: controller.formKey, // Hubungkan dengan GlobalKey di controller
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextField(
                controller: controller.namaC,
                labelText: 'Nama Lengkap',
                hintText: 'Masukkan nama lengkap pegawai',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Obx(
                    () => Radio(
                      value: "Laki-Laki",
                      groupValue: controller.jenisKelamin.value,
                      activeColor: Colors.black,
                      fillColor: WidgetStateProperty.all(Colors.grey[700]),
                      onChanged: (value) {
                        // Handle the change here
                        controller.jenisKelamin.value = value.toString();
                        // print(value);
                      },
                    ),
                  ),
                  Text("Laki-Laki"),
                  SizedBox(width: 20),
                  Obx(
                    () => Radio(
                      value: "Perempuan",
                      groupValue: controller.jenisKelamin.value,
                      activeColor: Colors.black,
                      fillColor: WidgetStateProperty.all(Colors.grey[700]),
                      onChanged: (value) {
                        // Handle the change here
                        controller.jenisKelamin.value = value.toString();
                        // print(value);
                      },
                    ),
                  ),
                  Text("Perempuan"),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: controller.nipC,
                labelText: 'NIP / ID Pegawai',
                hintText: 'Masukkan NIP atau ID unik',
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NIP/ID tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // _buildTextField(
              //   controller: controller.jabatanC,
              //   labelText: 'Jabatan',
              //   hintText: 'Masukkan jabatan pegawai',
              //   icon: Icons.work_outline,
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Jabatan tidak boleh kosong';
              //     }
              //     return null;
              //   },
              // ),

              DropdownSearch<String>(
            key: UniqueKey(), // Tambahkan key untuk rebuild jika items berubah atau selectedItem direset
            decoratorProps: DropDownDecoratorProps(
              decoration: _commonInputDecorator(theme, 'Jabatan', prefixIcon: const Icon(Icons.portrait_outlined)),
            ),
            selectedItem: controller.jabatanC.text.isEmpty ? null : controller.jabatanC.text,
            items: (f, cs) => const [ // Daftar surat bisa diperluas atau diambil dari sumber dinamis
              "Kepala Sekolah", "Wakil Kepla sekolah", "Pegawai Administrasi (TU)", 
              "Guru Kelas", "Guru Mapel", "Koordinator Halaqoh", "Pengampu", "Bendahara",
              "Operator", "Guru BK", "Satpam",
            ],
            onChanged: (String? value) {
              if (value != null) {
                controller.jabatanC.text = value;
              }
            },
            popupProps: PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4), // Batasi tinggi popup
              searchFieldProps: TextFieldProps(
                decoration: _commonInputDecorator(theme, 'Cari Jabatan').copyWith(
                  hintText: 'Ketik nama jabatan...',
                  prefixIcon: const Icon(Icons.search)
                ),
              ),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                backgroundColor: theme.colorScheme.surfaceContainer,
              ),
            ),
          ),
             
              const SizedBox(height: 16),
              _buildTextField(
                controller: controller.emailC,
                labelText: 'Email',
                hintText: 'Masukkan alamat email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: controller.teleponC,
                labelText: 'Nomor Telepon',
                hintText: 'Masukkan nomor telepon aktif',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  if (!GetUtils.isPhoneNumber(value)) {
                    return 'Format nomor telepon tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: controller.alamatC,
                labelText: 'Alamat',
                hintText: 'Masukkan alamat lengkap pegawai',
                icon: Icons.location_on_outlined,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.tanggalBergabungC,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tanggal Bergabung (Opsional)',
                  hintText: 'Pilih tanggal bergabung (Opsional)',
                  prefix: IconButton(
                    onPressed: () {
                      showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      ).then((value) {
                        // format tanggal
                        if (value != null) {
                          controller.tanggalBergabung.value = value;
                          controller.tanggalBergabungC.text =
                              DateFormat('dd-MM-yyyy').format(value).toString();
                        }
                      });
                    },
                    icon: Icon(Icons.calendar_today),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  if(controller.jenisKelamin.value.isEmpty){
                    Get.snackbar("Error", "Jenis kelamin Kosong");
                  } else if(controller.jabatanC.text.isEmpty) {
                    Get.snackbar("Error", "Jabatan Kosong");
                  } else{
                  controller.simpanPegawai();
                  }
                },
                child: const Text('Simpan Data Pegawai'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

  // Helper widget untuk membuat TextFormField yang seragam
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: Theme.of(Get.context!).colorScheme.primary,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50], // Warna latar belakang field yang lembut
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
    );
  }


InputDecoration _commonInputDecorator(ThemeData theme, String labelText, {String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.colorScheme.outline)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.7))
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5), // Warna fill lebih subtle
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }