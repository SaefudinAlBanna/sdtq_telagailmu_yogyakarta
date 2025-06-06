import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import '../controllers/tambah_siswa_controller.dart';

class TambahSiswaView extends GetView<TambahSiswaController> {
  const TambahSiswaView({super.key});
  @override
  Widget build(BuildContext context) {
    // Panggil controller untuk inisialisasi (jika belum ter-inject)
    // Get.find<TambahPegawaiController>(); // Tidak perlu jika binding sudah benar

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Siswa Baru'),
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
                hintText: 'Masukkan nama lengkap siswa',
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
                controller: controller.nisnC,
                labelText: 'NISN',
                hintText: 'Masukkan NISN Siswa',
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NISN tidak boleh kosong';
                  }
                  return null;
                },
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
                hintText: 'Masukkan alamat lengkap siswa',
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
                controller: controller.tanggallahirC,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  hintText: 'Masukan tanggal Lahir',
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
                          // controller.tanggalBergabung.value = value;
                          controller.tanggallahirC.text =
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
                  } else if(controller.tanggallahirC.text.isEmpty) {
                    Get.snackbar("Error", "Jabatan Kosong");
                  } else{
                  controller.tambahSiswa();
                  }
                },
                child: const Text('Simpan Data Siswa'),
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
