// lib/app/services/pdf_export_service.dart (VERSI 2.1 - KODE BENAR)

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/jurnal_laporan_item_model.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/controllers/config_controller.dart';

class PdfExportService {
  Future<void> generateAndPreviewPdf({
    required String judulLaporan,
    required String rentangTanggal,
    required List<JurnalLaporanItem> laporanData,
    required bool isLaporanPimpinan,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final italicFont = await PdfGoogleFonts.poppinsItalic();
    
    final namaSekolah = Get.find<ConfigController>().infoUser['namaSekolah'] ?? 'PKBM SDTQ Telagailmu';

    final Map<String, List<JurnalLaporanItem>> groupedData = {};
    for (var item in laporanData) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.tanggal);
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      groupedData[dateKey]!.add(item);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(context, namaSekolah, judulLaporan, rentangTanggal, boldFont, font),
        build: (context) {
          List<pw.Widget> widgets = [];
          for (var entry in groupedData.entries) {
            widgets.add(_buildDailyReportBlock(entry.value, isLaporanPimpinan, font, boldFont, italicFont));
            widgets.add(pw.SizedBox(height: 12));
          }
          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  pw.Widget _buildHeader(pw.Context context, String namaSekolah, String judulLaporan, String rentangTanggal, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Column(
        children: [
          pw.Text(namaSekolah, style: pw.TextStyle(font: boldFont, fontSize: 16)),
          pw.Text(judulLaporan, style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.Text("Periode: $rentangTanggal", style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Divider(thickness: 1, color: PdfColors.grey),
        ]
      )
    );
  }

  pw.Widget _buildDailyReportBlock(List<JurnalLaporanItem> items, bool isPimpinan, pw.Font font, pw.Font boldFont, pw.Font italicFont) {
    final date = items.first.tanggal;
    final rekapAbsensi = items.first.rekapAbsensi;

    final headers = ['Jam', if (isPimpinan) 'Guru', 'Mapel', 'Kelas', 'Materi & Catatan'];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: const pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.only(topLeft: pw.Radius.circular(4), topRight: pw.Radius.circular(4))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date), style: pw.TextStyle(font: boldFont, fontSize: 11)),
              if (isPimpinan && rekapAbsensi != null)
                pw.Text("Kehadiran: $rekapAbsensi", style: pw.TextStyle(font: font, fontSize: 9)),
            ],
          ),
        ),
        
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey500),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            if (isPimpinan) 1: const pw.FlexColumnWidth(2.5),
            if (isPimpinan) 2: const pw.FlexColumnWidth(2.5) else 1: const pw.FlexColumnWidth(2.5),
            if (isPimpinan) 3: const pw.FlexColumnWidth(1) else 2: const pw.FlexColumnWidth(1),
            if (isPimpinan) 4: const pw.FlexColumnWidth(5) else 3: const pw.FlexColumnWidth(5),
          },
          children: [
            // Table Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: headers.map((header) => pw.Padding(
                padding: const pw.EdgeInsets.all(3),
                child: pw.Text(header, style: pw.TextStyle(font: boldFont, fontSize: 9)),
              )).toList(),
            ),
            // Table Rows
            ...items.map((item) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(item.jamKe, style: pw.TextStyle(font: font, fontSize: 8))),
                if (isPimpinan) pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(item.namaGuru, style: pw.TextStyle(font: font, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(item.namaMapel, style: pw.TextStyle(font: font, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(item.idKelas.split('-').first, style: pw.TextStyle(font: font, fontSize: 8))),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.materi, style: pw.TextStyle(font: font, fontSize: 8)),
                      if (item.catatan != null && item.catatan!.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            "Catatan: ${item.catatan}",
                            style: pw.TextStyle(font: italicFont, fontSize: 7, color: PdfColors.grey600),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )),
          ],
        ),
      ]
    );
  }
}