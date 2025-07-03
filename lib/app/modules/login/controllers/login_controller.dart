import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isLogin = true.obs; // Untuk show/hide password
  TextEditingController emailC = TextEditingController();
  TextEditingController passC = TextEditingController();

  // Inisialisasi Firebase
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Hapus fungsi loginUser() dan loginuser() karena logikanya sudah digabungkan ke dalam fungsi login() utama agar lebih sederhana dan tidak duplikat.

  Future<void> login() async {
    // 1. Validasi Input
    if (emailC.text.isEmpty || passC.text.isEmpty) {
      Get.snackbar(
        "Peringatan",
        "Email & Password Wajib diisi",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      // 2. Autentikasi Pengguna dengan Firebase Auth
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: emailC.text.trim(), // Gunakan .trim() untuk menghapus spasi
        password: passC.text,
      );

      // Cek apakah user berhasil login
      if (userCredential.user != null) {

        // 3. Cek Verifikasi Email
        if (!userCredential.user!.emailVerified) {
          isLoading.value = false;
          Get.defaultDialog(
            title: 'Belum Verifikasi Email',
            middleText: 'Silakan periksa inbox dan verifikasi email Anda terlebih dahulu.',
            actions: [
              OutlinedButton(
                onPressed: () => Get.back(),
                child: Text('NANTI'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await userCredential.user!.sendEmailVerification();
                    Get.back(); // Tutup dialog
                    Get.snackbar(
                      'Berhasil',
                      'Email verifikasi baru telah berhasil dikirim.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } catch (e) {
                    Get.snackbar('Terjadi Kesalahan', 'Gagal mengirim email verifikasi ulang. Coba lagi nanti.');
                  }
                },
                child: Text('KIRIM ULANG'),
              ),
            ],
          );
          // Hentikan proses karena email belum terverifikasi
          return;
        }

        // 4. Otorisasi: Cek apakah pengguna adalah seorang pegawai
        // Path disesuaikan dengan struktur Anda: /Sekolah/{id_sekolah}/pegawai/{uid}
        DocumentSnapshot pegawaiDoc = await firestore
            .collection("Sekolah")
            .doc("P9984539") // Ganti ini jika ID sekolah Anda dinamis
            .collection("pegawai")
            .doc(userCredential.user!.uid) // Pengecekan berdasarkan UID
            .get();

        if (pegawaiDoc.exists) {
          // 5. BERHASIL: Pengguna adalah pegawai, izinkan masuk.
          isLoading.value = false;
          Get.offAllNamed(Routes.HOME); // Arahkan ke dashboard guru

        } else {
          // 6. GAGAL: Pengguna bukan pegawai. Tampilkan error dan logout.
          isLoading.value = false;
          await auth.signOut(); // Logout paksa sesi yang salah
          Get.snackbar(
            "Login Gagal",
            "Akun Anda tidak terdaftar sebagai pegawai.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade600,
            colorText: Colors.white,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String errorMessage;
      // Memberikan pesan error yang lebih mudah dimengerti
      if (e.code == 'invalid-credential') {
        errorMessage = "Email atau Password yang Anda masukkan salah.";
      } else if (e.code == 'user-not-found') {
        errorMessage = "Akun dengan email ini tidak ditemukan.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Password yang Anda masukkan salah.";
      } else {
        errorMessage = "Terjadi kesalahan. Silakan coba lagi.";
      }
      Get.snackbar(
        "Login Gagal",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Menangkap error lain (misal: tidak ada koneksi internet)
      isLoading.value = false;
      Get.snackbar(
        "Terjadi Kesalahan",
        "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../../routes/app_pages.dart';

// class LoginController extends GetxController {
//   RxBool isLoading = false.obs;
//   RxBool isLogin = true.obs;
//   TextEditingController emailC = TextEditingController();
//   TextEditingController passC = TextEditingController();

//   FirebaseAuth auth = FirebaseAuth.instance;

//   Future<void> login() async {
//     if (emailC.text.isNotEmpty && passC.text.isNotEmpty) {
//       isLoading.value = true;
//       try {
//         UserCredential userCredential = await auth.signInWithEmailAndPassword(
//           email: emailC.text,
//           password: passC.text,
//         );

//         if (userCredential.user != null) {
//           if (userCredential.user != null) {
//             if (userCredential.user!.emailVerified == true) {
//               isLoading.value = false;
//               if (passC.text == "telagailmu") {
//                 Get.offAllNamed(Routes.NEW_PASSWORD);
//               } else {
//                 Get.offAllNamed(Routes.HOME);
//               }
//             } else {
              
//               Get.defaultDialog(
//                 title: 'Belum verifikasi',
//                 middleText: 'Silahkan verifikasi terlebih dahulu',
//                 actions: [
//                   OutlinedButton(
//                     onPressed: () {
//                       isLoading.value = false;
//                       Get.back();
//                     },
//                     child: Text('CANCEL'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () async {
//                       try {
//                         await userCredential.user!.sendEmailVerification();
//                         Get.back();
//                         Get.snackbar('Berhasil',
//                             'email verifikasi sudah berhasil terkirim');
//                             isLoading.value = false;
//                       } catch (e) {
//                             isLoading.value = false;
//                         Get.snackbar(
//                             'Terjadi Kesalahan', 'Silahkan dicoba lagi nanti');
//                       }
//                     },
//                     child: Text('Kirim Ulang Verifikasi'),
//                   ),
//                 ],
//               );
//             }
//           }
//         } else {
//           Get.snackbar('Peringatan', 'email belum terfverifikasi');
//         }

//         // print(userCredential);
//         isLoading.value = false;
//       } on FirebaseAuthException catch (e) {
//         isLoading.value = false;
//         if (e.code == 'invalid-credential') {
//           Get.snackbar("Peringatan", 'Periksa kembali, apakah email, password sudah benar?? dan apakah akun email sudah terdaftar',
//               snackPosition: SnackPosition.BOTTOM,
//               snackStyle: SnackStyle.FLOATING,
//               // borderColor: Colors.grey
//               backgroundColor: Colors.grey);
//         } else {
//           Get.snackbar(
//               snackPosition: SnackPosition.BOTTOM, 'Terjadi Kesalahan', e.code);
//         }
//       } catch (e) {
//         isLoading.value = false;
//         Get.snackbar("Terjadi kesalahan", "Tidak dapat login",
//             snackPosition: SnackPosition.BOTTOM,
//             snackStyle: SnackStyle.FLOATING,
//             // borderColor: Colors.grey
//             backgroundColor: Colors.grey);
//       }
//     } else {
//       Get.snackbar("Peringatan", "Email & Password Wajib diisi",
//           snackPosition: SnackPosition.BOTTOM,
//           snackStyle: SnackStyle.FLOATING,
//           // borderColor: Colors.grey
//           backgroundColor: Colors.grey);
//     }
//   }

//   Future<String> loginUser() async {
//     String res = " Some error ocured";
//     if (emailC.text.isNotEmpty && passC.text.isNotEmpty) {
//       try {
//         UserCredential userCredential = await auth.signInWithEmailAndPassword(
//             email: emailC.text, password: passC.text);

//         if (userCredential.user != null) {
//           if (userCredential.user != null) {
//             if (userCredential.user!.emailVerified == true) {
//               if (passC.text == "telagailmu" || passC.text == "Telagailmu") {
//                 Get.offAllNamed(Routes.NEW_PASSWORD);
//               } else {
//                 res = "Succes";
//                 Get.offAllNamed(Routes.HOME);
//               }
//             } else {
//               Get.defaultDialog(
//                 title: 'Belum verifikasi',
//                 middleText: 'Silahkan verifikasi terlebih dahulu',
//                 actions: [
//                   OutlinedButton(
//                     onPressed: () => Get.back(),
//                     child: Text('CANCEL'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () async {
//                       try {
//                         await userCredential.user!.sendEmailVerification();
//                         Get.back();
//                         Get.snackbar('Berhasil',
//                             'email verifikasi sudah berhasil terkirim');
//                       } catch (e) {
//                         Get.snackbar(
//                             'Terjadi Kesalahan', 'Silahkan dicoba lagi nanti');
//                       }
//                     },
//                     child: Text('Kirim Ulang Verifikasi'),
//                   ),
//                 ],
//               );
//             }
//           }
//         } else {
//           res = 'email belum terfverifikasi';
//         }
//       } catch (e) {
//         return e.toString();
//       }
//     }
//     return res;
//   }

//   void loginuser() async {
//     String res = await LoginController().loginUser();

//     if (res == "Succes") {
//       Get.offAllNamed(Routes.HOME);
//     } else {
//       Get.snackbar(
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.grey,
//           'Peringatan',
//           res);
//     }
//   }
// }
