import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pages/home.dart';
import '../pages/marketplace.dart';
import '../pages/profile.dart';

class HomeController extends GetxController {
  RxInt indexWidget = 0.obs;
  RxBool isLoading = false.obs;

  TextEditingController kelasSiswaC = TextEditingController();

  void changeIndex(int index) {
    indexWidget.value = index;
  }

  final List<Widget> myWidgets = [
    HomePage(),
    MarketplacePage(),
    ProfilePage(),
  ];
}
