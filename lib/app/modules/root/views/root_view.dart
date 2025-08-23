// lib/app/modules/root/views/root_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/home/views/home_view.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/login/views/login_view.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/modules/new_password/views/new_password_view.dart';

class RootView extends GetView<ConfigController> {
  const RootView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.status.value) {
        case AppStatus.loading:
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        case AppStatus.unauthenticated:
          return const LoginView();
        case AppStatus.needsNewPassword:
          return const NewPasswordView();
        case AppStatus.authenticated:
          return const HomeView();
      }
    });
  }
}