// lib/app/modules/login/views/login_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authC = Get.find<AuthController>();
    // Mengambil ukuran layar
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // [BACKGROUND] Abu-abu sangat muda (Off-White) agar mata tidak lelah
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // [DEKORASI 1] Lingkaran Gradient Halus di Pojok Kanan Atas
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade100.withOpacity(0.5),
                    Colors.indigo.shade50.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // [DEKORASI 2] Lingkaran Kecil di Kiri Bawah
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade50.withOpacity(0.6),
              ),
            ),
          ),

          // [KONTEN UTAMA]
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO & JUDUL ---
                  Hero(
                    tag: 'logo_sekolah',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Image.asset(
                        "assets/png/logo.png",
                        height: 60,
                        width: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "PKBM STQ Telagailmu",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800, // Font tebal profesional
                      color: Colors.indigo.shade900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Masuk sebagai Guru atau Staff",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- KARTU FORM (CLEAN SURFACE) ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      // Bayangan difusi yang luas (Elegan & Melayang)
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.08), // Bayangan indigo sangat tipis
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Email"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: controller.emailC,
                            validator: controller.validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            decoration: _cleanInputDecoration(
                              hint: "email@mail.com",
                              icon: Icons.alternate_email_rounded,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          _buildLabel("Kata Sandi"),
                          const SizedBox(height: 8),
                          Obx(() => TextFormField(
                            controller: controller.passC,
                            obscureText: controller.isPasswordHidden.value,
                            validator: controller.validatePassword,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            decoration: _cleanInputDecoration(
                              hint: "••••••••",
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.isPasswordHidden.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () => controller.isPasswordHidden.toggle(),
                              ),
                            ),
                          )),

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () => Get.toNamed(Routes.FORGOT_PASSWORD),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  "Lupa Password?",
                                  style: TextStyle(
                                    color: Colors.indigo.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // --- TOMBOL MODERN (FLAT & WIDE) ---
                          Obx(() => SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: authC.isLoading.value ? null : controller.login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade700,
                                foregroundColor: Colors.white,
                                elevation: 0, // Flat design (tanpa shadow timbul)
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                shadowColor: Colors.indigo.withOpacity(0.3),
                              ),
                              child: authC.isLoading.value
                                  ? const SizedBox(
                                      height: 20, 
                                      width: 20, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                    )
                                  : const Text(
                                      "LOGIN",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text(
                    "Versi ${controller.appVersion}",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // Style Input yang BERBEDA dari Wali (Tidak Cekung/Clay, tapi Datar/Flat & Bersih)
  InputDecoration _cleanInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB), // Sangat, sangat muda (hampir putih)
      prefixIcon: Icon(icon, color: Colors.indigo.shade200, size: 22),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      
      // Border Default: Garis tipis abu-abu (Professional look)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      
      // Border Fokus: Warna Indigo (Branding)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.indigo.shade300, width: 1.5),
      ),
      
      // Border Error
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade200, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';
// import '../controllers/login_controller.dart';

// // [PERBAIKAN] Ubah menjadi GetView<LoginController>
// class LoginView extends GetView<LoginController> {
//   const LoginView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // [PERBAIKAN] Hapus Get.put di sini, controller akan di-inject oleh GetView
//     // final LoginController controller = Get.put(LoginController());
//     final AuthController authController = Get.find<AuthController>();

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Layer 1: Background Gradient
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.indigo.shade200, Colors.green.shade200],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
          
//           // Layer 2: Konten Login
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Logo dan Judul
//                   SizedBox(
//                     height: 80,
//                     width: 80,
//                     child: Image.asset("assets/png/logo.png", fit: BoxFit.contain),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     "PKBM STQ Telagailmu",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Silakan masuk untuk melanjutkan",
//                     style: TextStyle(fontSize: 16, color: Colors.black54),
//                   ),
//                   const SizedBox(height: 32),

//                   // Card untuk Form
//                   Card(
//                     elevation: 8,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     child: Padding(
//                       padding: const EdgeInsets.all(24.0),
//                       child: Form(
//                         key: controller.formKey, // [PERBAIKAN] Akses formKey dari controller
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             TextFormField(
//                               controller: controller.emailC, // [PERBAIKAN] Akses emailC dari controller
//                               keyboardType: TextInputType.emailAddress,
//                               validator: controller.validateEmail, // [PERBAIKAN] Akses validator dari controller
//                               autovalidateMode: AutovalidateMode.onUserInteraction,
//                               decoration: InputDecoration(
//                                 labelText: "Email",
//                                 prefixIcon: const Icon(Icons.email_outlined),
//                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             Obx(() => TextFormField(
//                                   controller: controller.passC, // [PERBAIKAN] Akses passC dari controller
//                                   obscureText: controller.isPasswordHidden.value, // [PERBAIKAN] Akses isPasswordHidden dari controller
//                                   validator: controller.validatePassword, // [PERBAIKAN] Akses validator dari controller
//                                   autovalidateMode: AutovalidateMode.onUserInteraction,
//                                   decoration: InputDecoration(
//                                     labelText: "Password",
//                                     prefixIcon: const Icon(Icons.lock_outline),
//                                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                                     suffixIcon: IconButton(
//                                       icon: Icon(controller.isPasswordHidden.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
//                                       onPressed: () => controller.isPasswordHidden.toggle(), // [PERBAIKAN] Akses toggle dari controller
//                                     ),
//                                   ),
//                                 )),
//                             const SizedBox(height: 16),
//                             Align(
//                               alignment: Alignment.centerRight,
//                               child: TextButton(
//                                 onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
//                                 child: Text("Lupa Password?", style: TextStyle(color: Colors.indigo.shade700)),
//                               ),
//                             ),

//                             const SizedBox(height: 40),
//                             Text(
//                               controller.appVersion,
//                               style: TextStyle(
//                                 color: Colors.grey.shade700,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Tombol Login
//                   Obx(() => SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.indigo.shade700,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             elevation: 4,
//                           ),
//                           onPressed: authController.isLoading.value ? null : controller.login, // [PERBAIKAN] Akses login dari controller
//                           child: authController.isLoading.value
//                               ? const CircularProgressIndicator(color: Colors.white)
//                               : const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                         ),
//                       )),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }