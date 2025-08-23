import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sdtq_telagailmu_yogyakarta/app/models/acara_kalender_model.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/manajemen_kalender_akademik_controller.dart';

class ManajemenKalenderAkademikView extends GetView<ManajemenKalenderAkademikController> {
  const ManajemenKalenderAkademikView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kalender Akademik")),
      floatingActionButton: controller.isPimpinan ? FloatingActionButton.extended(
        onPressed: () => controller.showFormDialog(), label: const Text("Tambah Agenda"), icon: const Icon(Icons.add),
      ) : null,
      body: Column(
        children: [
          _buildTableCalendar(),
          _buildAgendaHeader(),
          Expanded(child: _buildMonthlyEventList()),
        ],
      ),
    );
  }

  Widget _buildTableCalendar() {
    return Obx(() => TableCalendar<AcaraKalender>(
      locale: 'id_ID', firstDay: DateTime.utc(2022, 1, 1), lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: controller.focusedDay.value,
      selectedDayPredicate: (day) => isSameDay(controller.selectedDay.value, day),
      calendarFormat: controller.calendarFormat.value,
      eventLoader: controller.getEventsForDay,
      onDaySelected: controller.onDaySelected,
      onFormatChanged: (format) => controller.calendarFormat.value = format,
      onPageChanged: controller.onPageChanged,
      calendarBuilders: CalendarBuilders(
        // --- [PERBAIKAN] Custom builder untuk tanggal dengan acara ---
        defaultBuilder: (context, day, focusedDay) {
          final events = controller.getEventsForDay(day);
          if (events.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.all(4.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: events.first.warna.withOpacity(0.3), shape: BoxShape.circle),
              child: Text(day.day.toString(), style: const TextStyle(color: Colors.black)),
            );
          } return null;
        },
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(color: Colors.orange.shade200, shape: BoxShape.circle),
        selectedDecoration: BoxDecoration(color: Get.theme.primaryColor, shape: BoxShape.circle),
        markerDecoration: const BoxDecoration(color: Colors.transparent), // Sembunyikan marker default
      ),
      headerStyle: const HeaderStyle(formatButtonShowsNext: false),
    ));
  }

  Widget _buildAgendaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Obx(() => Text(
        "Agenda Bulan ${DateFormat('MMMM yyyy', 'id_ID').format(controller.focusedDay.value)}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      )),
    );
  }

  Widget _buildMonthlyEventList() {
    return Obx(() {
      if (controller.monthlyEvents.isEmpty) { return const Center(child: Text("Tidak ada agenda pada bulan ini.", style: TextStyle(color: Colors.grey))); }
      return ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: controller.monthlyEvents.length,
        itemBuilder: (context, index) {
          final acara = controller.monthlyEvents[index];
          final tglMulai = DateFormat('d', 'id_ID').format(acara.mulai);
          final tglSelesai = DateFormat('d MMM yyyy', 'id_ID').format(acara.selesai);
          final tanggal = acara.mulai.day == acara.selesai.day ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(acara.mulai) : "$tglMulai - $tglSelesai";
              
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: Container(width: 8, decoration: BoxDecoration(color: acara.warna, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)))),
              title: Text(acara.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tanggal),
                  if (acara.deskripsi.isNotEmpty) 
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text(acara.deskripsi, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                ],
              ),
              trailing: controller.isPimpinan ? Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600), onPressed: () => controller.showFormDialog(acara: acara)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => controller.hapusAcara(acara.id)),
              ]) : null,
              isThreeLine: acara.deskripsi.isNotEmpty,
            ),
          );
        },
      );
    });
  }
}


// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:sdtq_telagailmu_yogyakarta/app/models/acara_kalender_model.dart';
// import 'package:table_calendar/table_calendar.dart';
// import '../controllers/manajemen_kalender_akademik_controller.dart';

// class ManajemenKalenderAkademikView extends GetView<ManajemenKalenderAkademikController> {
//   const ManajemenKalenderAkademikView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Kalender Akademik")),
//       floatingActionButton: controller.isPimpinan
//           ? FloatingActionButton.extended(
//               onPressed: () => controller.showFormDialog(),
//               label: const Text("Tambah Agenda"),
//               icon: const Icon(Icons.add),
//             )
//           : null,
//        body: Column(
//         children: [
//           _buildTableCalendar(),
//           _buildAgendaHeader(),
//           Expanded(child: _buildMonthlyEventList()), // <-- Ganti ke Agenda Bulanan
//         ],
//       ),
//     );
//   }

//   Widget _buildAgendaHeader() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       width: double.infinity,
//       color: Colors.grey.shade200,
//       child: Obx(() => Text(
//         "Agenda Bulan ${DateFormat('MMMM yyyy', 'id_ID').format(controller.focusedDay.value)}",
//         style: const TextStyle(fontWeight: FontWeight.bold),
//       )),
//     );
//   }

//   Widget _buildMonthlyEventList() {
//     return Obx(() {
//       if (controller.monthlyEvents.isEmpty) {
//         return const Center(child: Text("Tidak ada agenda pada bulan ini.", style: TextStyle(color: Colors.grey)));
//       }
//       return ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: controller.monthlyEvents.length,
//         itemBuilder: (context, index) {
//           final acara = controller.monthlyEvents[index];
//           // --- [PERBAIKAN REVISI #2] Tampilan tanggal yang informatif ---
//           String tanggal;
//           if (acara.mulai.day == acara.selesai.day) {
//             tanggal = DateFormat('d MMM', 'id_ID').format(acara.mulai);
//           } else {
//             tanggal = "${acara.mulai.day} - ${DateFormat('d MMM', 'id_ID').format(acara.selesai)}";
//           }
              
//           return Card(
//             margin: const EdgeInsets.only(bottom: 8),
//             child: ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: acara.warna.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(4),
//                   border: Border.all(color: acara.warna),
//                 ),
//                 child: Text(tanggal, style: TextStyle(color: acara.warna, fontWeight: FontWeight.bold, fontSize: 12)),
//               ),
//               title: Text(acara.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
//               trailing: controller.isPimpinan
//                   // --- [PERBAIKAN BUG #2] Tombol edit ---
//                   ? Row(mainAxisSize: MainAxisSize.min, children: [
//                       IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey), onPressed: () => controller.showFormDialog(acara: acara)),
//                       IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => controller.hapusAcara(acara.id)),
//                     ])
//                   : null,
//             ),
//           );
//         },
//       );
//     });
//   }


//   Widget _buildTableCalendar() {
//     return Obx(() => TableCalendar<AcaraKalender>(
//       locale: 'id_ID',
//       firstDay: DateTime.utc(2022, 1, 1),
//       lastDay: DateTime.utc(2030, 12, 31),
//       focusedDay: controller.focusedDay.value,
//       selectedDayPredicate: (day) => isSameDay(controller.selectedDay.value, day),
//       calendarFormat: controller.calendarFormat.value,
//       eventLoader: controller.getEventsForDay,
//       onDaySelected: controller.onDaySelected,
//       onFormatChanged: (format) => controller.calendarFormat.value = format,
//       onPageChanged: controller.onPageChanged, // <-- Hubungkan ke logika baru
//       calendarBuilders: CalendarBuilders(
//         markerBuilder: (context, date, events) {
//           if (events.isNotEmpty) {
//             // --- [PERBAIKAN REVISI #1] Warna marker sesuai acara ---
//             return Positioned(
//               right: 1, bottom: 1,
//               child: Container(
//                 padding: const EdgeInsets.all(1),
//                 decoration: BoxDecoration(shape: BoxShape.circle, color: events.first.warna.withOpacity(0.8)),
//                 width: 7, height: 7,
//               ),
//             );
//           } return null;
//         },
//       ),
//       calendarStyle: CalendarStyle(
//         todayDecoration: BoxDecoration(color: Colors.orange.shade200, shape: BoxShape.circle),
//         selectedDecoration: BoxDecoration(color: Get.theme.primaryColor, shape: BoxShape.circle),
//       ),
//       headerStyle: HeaderStyle(
//         formatButtonDecoration: BoxDecoration(
//           color: Get.theme.primaryColor.withOpacity(0.2),
//           borderRadius: BorderRadius.circular(20.0),
//         ),
//         formatButtonTextStyle: const TextStyle(color: Colors.black),
//         formatButtonShowsNext: false,
//       ),
//     ));
//   }
// }