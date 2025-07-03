// lib/app/modules/home/pages/marketplace_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:intl/intl.dart';

class MarketplacePage extends StatelessWidget {
  MarketplacePage({super.key});

  final List<Widget> _carouselItems = [
    "assets/webp/1.webp", "assets/webp/2.webp", "assets/webp/3.webp", "assets/webp/4.webp", "assets/webp/5.webp",
  ].map((imgPath) => _CarouselImageSlider(imagePath: imgPath, onTap: () {})).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketplace"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          CarouselSlider(
            items: _carouselItems,
            options: CarouselOptions(
              height: 180, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.9
            ),
          ),
          const _CategoryRow(),
          const _SectionHeader(),
          Expanded( // Kunci performa untuk GridView
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: 50,
              itemBuilder: (context, index) => _ProductCard(index: index),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MarketCategory(title: 'Makanan', icon: Icons.fastfood, onTap: () {}),
          _MarketCategory(title: 'Properti', icon: Icons.warehouse_outlined, onTap: () {}),
          _MarketCategory(title: 'Elektronik', icon: Icons.tv, onTap: () {}),
          _MarketCategory(title: 'Lainnya', icon: Icons.category, onTap: () {}),
        ],
      ),
    );
  }
}

class _MarketCategory extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MarketCategory({required this.title, required this.icon, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.green.withOpacity(0.1),
            child: Icon(icon, color: Colors.green.shade700, size: 28),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Produk Terlaris", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          TextButton(onPressed: () {}, child: const Text("Lihat Semua")),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final int index;
  const _ProductCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: "https://picsum.photos/id/${index + 256}/300/300",
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(color: Colors.grey.shade200),
                errorWidget: (c, u, e) => const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Produk ke ${index + 1}", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis,),
                  const SizedBox(height: 4),
                  Text("Rp ${NumberFormat.decimalPattern('id').format(Random().nextInt(100000))}", style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselImageSlider extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;
  const _CarouselImageSlider({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(5.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          child: Image.asset(imagePath, fit: BoxFit.cover, width: 1000.0),
        ),
      ),
    );
  }
}