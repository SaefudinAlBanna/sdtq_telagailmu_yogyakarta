// lib/app/modules/home/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../controllers/home_controller.dart';
import '../pages/dashboard_page.dart';
import '../pages/palace_holder.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  List<Widget> _buildScreens() {
    return [
      // const PlaceholderView(pageTitle: "Dashboard"),
      const DashboardView(),
      const PlaceholderView(pageTitle: "Jurnal"),
      const PlaceholderView(pageTitle: "Profil"),
    ];
  }

  // --- LOGIKA UNTUK MEMBANGUN ITEM NAV BAR ---
  // Sesuaikan jumlah item dengan jumlah screens di atas
  List<PersistentBottomNavBarItem> _buildNavBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: ("Dashboard"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.book),
        title: ("Jurnal"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: ("Profil"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // --- KODE PERSISTENT TAB VIEW YANG SUDAH DIPERBAIKI ---
    // Semua parameter yang menyebabkan error telah dihapus.
    // Ini adalah versi yang lebih dasar namun kompatibel.
    return PersistentTabView(
      context,
      controller: controller.tabController,
      screens: _buildScreens(),
      items: _buildNavBarsItems(),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      navBarStyle: NavBarStyle.style1, // Anda bisa ganti style lain
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(10.0),
        colorBehindNavBar: Colors.white,
      ),
    );
  }
}