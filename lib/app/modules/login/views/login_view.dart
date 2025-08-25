import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      // Menggunakan Stack untuk menumpuk background dan form
      body: Stack(
        children: [
          // Layer 1: Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade200, Colors.green.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Layer 2: Konten Login
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo dan Judul
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Image.asset("assets/png/logo.png", fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "PKBM Telagailmu",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Silakan masuk untuk melanjutkan",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  // Card untuk Form
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: controller.emailC,
                              keyboardType: TextInputType.emailAddress,
                              validator: controller.validateEmail,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Email",
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Obx(() => TextFormField(
                                  controller: controller.passC,
                                  obscureText: controller.isPasswordHidden.value,
                                  validator: controller.validatePassword,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    suffixIcon: IconButton(
                                      icon: Icon(controller.isPasswordHidden.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      onPressed: () => controller.isPasswordHidden.toggle(),
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
                                child: Text("Lupa Password?", style: TextStyle(color: Colors.indigo.shade700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Login
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          onPressed: authController.isLoading.value ? null : controller.login,
                          child: authController.isLoading.value
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/controllers/auth_controller.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/routes/app_pages.dart';
// import '../controllers/login_controller.dart';

// // --- [PERBAIKAN #1] Ubah dari GetView menjadi StatelessWidget ---
// // Ini memberi kita kontrol lebih atas lifecycle controller.
// class LoginView extends StatelessWidget {
//   const LoginView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // --- [PERBAIKAN #2] Inisialisasi controller di sini ---
//     // Get.put() akan membuat instance LoginController baru yang segar setiap kali
//     // LoginView dibangun oleh RootView, dan akan otomatis di-dispose saat LoginView hilang.
//     final LoginController controller = Get.put(LoginController());
//     final AuthController authController = Get.find<AuthController>();

//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             physics: const BouncingScrollPhysics(),
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 minHeight: constraints.maxHeight,
//               ),
//               child: IntrinsicHeight(
//                 child: Form(
//                   key: controller.formKey,
//                   child: Column(
//                     children: [
//                       // Header (tidak ada perubahan)
//                       Container(
//                         height: constraints.maxHeight * 0.35,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Colors.green.shade700, Colors.indigo.shade400],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                         ),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(
//                               height: 80,
//                               width: 80,
//                               child: Image.asset("assets/png/logo.png", fit: BoxFit.contain),
//                             ),
//                             const SizedBox(height: 16),
//                             const Text(
//                               "PKBM Telagailmu",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 26,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const Text(
//                               "Aplikasi Manajemen Sekolah",
//                               style: TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
                      
//                       // Form (tidak ada perubahan fungsional)
//                       Expanded(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 "Selamat Datang",
//                                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
//                               ),
//                               const SizedBox(height: 8),
//                               const Text(
//                                 "Silakan masuk untuk melanjutkan",
//                                 style: TextStyle(fontSize: 16, color: Colors.grey),
//                               ),
//                               const SizedBox(height: 32),
//                               TextFormField(
//                                 controller: controller.emailC,
//                                 keyboardType: TextInputType.emailAddress,
//                                 validator: controller.validateEmail,
//                                 autovalidateMode: AutovalidateMode.onUserInteraction,
//                                 decoration: InputDecoration(
//                                   labelText: "Email",
//                                   prefixIcon: const Icon(Icons.email_outlined),
//                                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               Obx(() => TextFormField(
//                                     controller: controller.passC,
//                                     obscureText: controller.isPasswordHidden.value,
//                                     validator: controller.validatePassword,
//                                     autovalidateMode: AutovalidateMode.onUserInteraction,
//                                     decoration: InputDecoration(
//                                       labelText: "Password",
//                                       prefixIcon: const Icon(Icons.lock_outline),
//                                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                                       suffixIcon: IconButton(
//                                         icon: Icon(
//                                           controller.isPasswordHidden.value
//                                               ? Icons.visibility_off_outlined
//                                               : Icons.visibility_outlined,
//                                         ),
//                                         onPressed: () {
//                                           controller.isPasswordHidden.value = !controller.isPasswordHidden.value;
//                                         },
//                                       ),
//                                     ),
//                                   )),
//                               const SizedBox(height: 16),
//                               Align(
//                                 alignment: Alignment.centerRight,
//                                 child: TextButton(
//                                   onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
//                                   child: const Text("Lupa Password?"),
//                                 ),
//                               ),
//                               const SizedBox(height: 24),
//                               Obx(() => SizedBox(
//                                     width: double.infinity,
//                                     height: 50,
//                                     child: ElevatedButton(
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.indigo.shade400,
//                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                       ),
//                                       onPressed: authController.isLoading.value ? null : controller.login,
//                                       child: authController.isLoading.value
//                                           ? const CircularProgressIndicator(color: Colors.white)
//                                           : const Text(
//                                               "LOGIN",
//                                               style: TextStyle(fontSize: 16, color: Colors.white),
//                                             ),
//                                     ),
//                                   )),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }