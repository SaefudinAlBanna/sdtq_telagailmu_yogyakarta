import 'package:get/get.dart';

import '../modules/absensi_wali_kelas/bindings/absensi_wali_kelas_binding.dart';
import '../modules/absensi_wali_kelas/views/absensi_wali_kelas_view.dart';
import '../modules/atp_form/bindings/atp_form_binding.dart';
import '../modules/atp_form/views/atp_form_view.dart';
import '../modules/atur_guru_pengganti/bindings/atur_guru_pengganti_binding.dart';
import '../modules/atur_guru_pengganti/views/atur_guru_pengganti_view.dart';
import '../modules/atur_penggantian_host/bindings/atur_penggantian_host_binding.dart';
import '../modules/atur_penggantian_host/views/atur_penggantian_host_view.dart';
import '../modules/atur_penggantian_rentang/bindings/atur_penggantian_rentang_binding.dart';
import '../modules/atur_penggantian_rentang/views/atur_penggantian_rentang_view.dart';
import '../modules/buat_sarpras/bindings/buat_sarpras_binding.dart';
import '../modules/buat_sarpras/views/buat_sarpras_view.dart';
import '../modules/create_edit_ekskul/bindings/create_edit_ekskul_binding.dart';
import '../modules/create_edit_ekskul/views/create_edit_ekskul_view.dart';
import '../modules/create_edit_halaqah_group/bindings/create_edit_halaqah_group_binding.dart';
import '../modules/create_edit_halaqah_group/views/create_edit_halaqah_group_view.dart';
import '../modules/daftar_nilai/bindings/daftar_nilai_binding.dart';
import '../modules/daftar_nilai/views/daftar_nilai_view.dart';
import '../modules/daftar_siswa/bindings/daftar_siswa_binding.dart';
import '../modules/daftar_siswa/views/daftar_siswa_view.dart';
import '../modules/daftar_siswa_perkelas/bindings/daftar_siswa_perkelas_binding.dart';
import '../modules/daftar_siswa_perkelas/views/daftar_siswa_perkelas_view.dart';
import '../modules/daftar_siswa_permapel/bindings/daftar_siswa_permapel_binding.dart';
import '../modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart';
import '../modules/daftar_siswa_pindah_halaqoh/bindings/daftar_siswa_pindah_halaqoh_binding.dart';
import '../modules/daftar_siswa_pindah_halaqoh/views/daftar_siswa_pindah_halaqoh_view.dart';
import '../modules/data_sarpras/bindings/data_sarpras_binding.dart';
import '../modules/data_sarpras/views/data_sarpras_view.dart';
import '../modules/detail_siswa/bindings/detail_siswa_binding.dart';
import '../modules/detail_siswa/views/detail_siswa_view.dart';
import '../modules/editor_jadwal/bindings/editor_jadwal_binding.dart';
import '../modules/editor_jadwal/views/editor_jadwal_view.dart';
import '../modules/ekskul_pendaftaran_management/bindings/ekskul_pendaftaran_management_binding.dart';
import '../modules/ekskul_pendaftaran_management/views/ekskul_pendaftaran_management_view.dart';
import '../modules/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/forgot_password/views/forgot_password_view.dart';
import '../modules/guru_akademik/bindings/guru_akademik_binding.dart';
import '../modules/guru_akademik/views/guru_akademik_view.dart';
import '../modules/halaqah_dashboard_pengampu/bindings/halaqah_dashboard_pengampu_binding.dart';
import '../modules/halaqah_dashboard_pengampu/views/halaqah_dashboard_pengampu_view.dart';
import '../modules/halaqah_grading/bindings/halaqah_grading_binding.dart';
import '../modules/halaqah_grading/views/halaqah_grading_view.dart';
import '../modules/halaqah_management/bindings/halaqah_management_binding.dart';
import '../modules/halaqah_management/views/halaqah_management_view.dart';
import '../modules/halaqah_riwayat_pengampu/bindings/halaqah_riwayat_pengampu_binding.dart';
import '../modules/halaqah_riwayat_pengampu/views/halaqah_riwayat_pengampu_view.dart';
import '../modules/halaqah_set_pengganti/bindings/halaqah_set_pengganti_binding.dart';
import '../modules/halaqah_set_pengganti/views/halaqah_set_pengganti_view.dart';
import '../modules/halaqah_setoran_siswa/bindings/halaqah_setoran_siswa_binding.dart';
import '../modules/halaqah_setoran_siswa/views/halaqah_setoran_siswa_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/import_pegawai/bindings/import_pegawai_binding.dart';
import '../modules/import_pegawai/views/import_pegawai_view.dart';
import '../modules/import_siswa/bindings/import_siswa_binding.dart';
import '../modules/import_siswa/views/import_siswa_view.dart';
import '../modules/info_sekolah/bindings/info_sekolah_binding.dart';
import '../modules/info_sekolah/views/info_sekolah_view.dart';
import '../modules/info_sekolah_detail/bindings/info_sekolah_detail_binding.dart';
import '../modules/info_sekolah_detail/views/info_sekolah_detail_view.dart';
import '../modules/info_sekolah_form/bindings/info_sekolah_form_binding.dart';
import '../modules/info_sekolah_form/views/info_sekolah_form_view.dart';
import '../modules/input_nilai_massal_akademik/bindings/input_nilai_massal_akademik_binding.dart';
import '../modules/input_nilai_massal_akademik/views/input_nilai_massal_akademik_view.dart';
import '../modules/input_nilai_siswa/bindings/input_nilai_siswa_binding.dart';
import '../modules/input_nilai_siswa/views/input_nilai_siswa_view.dart';
import '../modules/jadwal_pelajaran/bindings/jadwal_pelajaran_binding.dart';
import '../modules/jadwal_pelajaran/views/jadwal_pelajaran_view.dart';
import '../modules/jurnal_harian_guru/bindings/jurnal_harian_guru_binding.dart';
import '../modules/jurnal_harian_guru/views/jurnal_harian_guru_view.dart';
import '../modules/kelompok_halaqoh/bindings/kelompok_halaqoh_binding.dart';
import '../modules/kelompok_halaqoh/views/kelompok_halaqoh_view.dart';
import '../modules/laporan_jurnal_kelas/bindings/laporan_jurnal_kelas_binding.dart';
import '../modules/laporan_jurnal_kelas/views/laporan_jurnal_kelas_view.dart';
import '../modules/laporan_jurnal_pribadi/bindings/laporan_jurnal_pribadi_binding.dart';
import '../modules/laporan_jurnal_pribadi/views/laporan_jurnal_pribadi_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/manajemen_kalender_akademik/bindings/manajemen_kalender_akademik_binding.dart';
import '../modules/manajemen_kalender_akademik/views/manajemen_kalender_akademik_view.dart';
import '../modules/manajemen_peran/bindings/manajemen_peran_binding.dart';
import '../modules/manajemen_peran/views/manajemen_peran_view.dart';
import '../modules/master_ekskul_management/bindings/master_ekskul_management_binding.dart';
import '../modules/master_ekskul_management/views/master_ekskul_management_view.dart';
import '../modules/master_jam/bindings/master_jam_binding.dart';
import '../modules/master_jam/views/master_jam_view.dart';
import '../modules/master_mapel/bindings/master_mapel_binding.dart';
import '../modules/master_mapel/views/master_mapel_view.dart';
import '../modules/modul_ajar_form/bindings/modul_ajar_form_binding.dart';
import '../modules/modul_ajar_form/views/modul_ajar_form_view.dart';
import '../modules/new_password/bindings/new_password_binding.dart';
import '../modules/new_password/views/new_password_view.dart';
import '../modules/pegawai/bindings/pegawai_binding.dart';
import '../modules/pegawai/views/pegawai_view.dart';
import '../modules/pembayaran_spp/bindings/pembayaran_spp_binding.dart';
import '../modules/pembayaran_spp/views/pembayaran_spp_view.dart';
import '../modules/pemberian_kelas_siswa/bindings/pemberian_kelas_siswa_binding.dart';
import '../modules/pemberian_kelas_siswa/views/pemberian_kelas_siswa_view.dart';
import '../modules/penugasan_guru/bindings/penugasan_guru_binding.dart';
import '../modules/penugasan_guru/views/penugasan_guru_view.dart';
import '../modules/perangkat_ajar/bindings/perangkat_ajar_binding.dart';
import '../modules/perangkat_ajar/views/perangkat_ajar_view.dart';
import '../modules/prota_prosem/bindings/prota_prosem_binding.dart';
import '../modules/prota_prosem/views/prota_prosem_view.dart';
import '../modules/pusat_informasi_penggantian/bindings/pusat_informasi_penggantian_binding.dart';
import '../modules/pusat_informasi_penggantian/views/pusat_informasi_penggantian_view.dart';
import '../modules/rapor_siswa/bindings/rapor_siswa_binding.dart';
import '../modules/rapor_siswa/views/rapor_siswa_view.dart';
import '../modules/rekap_absensi/bindings/rekap_absensi_binding.dart';
import '../modules/rekap_absensi/views/rekap_absensi_view.dart';
import '../modules/rekap_jurnal_admin/bindings/rekap_jurnal_admin_binding.dart';
import '../modules/rekap_jurnal_admin/views/rekap_jurnal_admin_view.dart';
import '../modules/rekap_jurnal_guru/bindings/rekap_jurnal_guru_binding.dart';
import '../modules/rekap_jurnal_guru/views/rekap_jurnal_guru_view.dart';
import '../modules/root/bindings/root_binding.dart';
import '../modules/root/views/root_view.dart';
import '../modules/tampilkan_info_sekolah/bindings/tampilkan_info_sekolah_binding.dart';
import '../modules/tampilkan_info_sekolah/views/tampilkan_info_sekolah_view.dart';
import '../modules/upsert_pegawai/bindings/upsert_pegawai_binding.dart';
import '../modules/upsert_pegawai/views/upsert_pegawai_view.dart';
import '../modules/upsert_siswa/bindings/upsert_siswa_binding.dart';
import '../modules/upsert_siswa/views/upsert_siswa_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.ROOT;

  static final routes = [
    // GetPage(
    //   name: _Paths.HOME,
    //   page: () => const HomeView(),
    //   binding: HomeBinding(),
    // ),
    GetPage(
      name: _Paths.PEMBERIAN_KELAS_SISWA,
      page: () => PemberianKelasSiswaView(),
      binding: PemberianKelasSiswaBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: _Paths.NEW_PASSWORD,
      page: () => const NewPasswordView(),
      binding: NewPasswordBinding(),
    ),
    GetPage(
      name: _Paths.PEMBAYARAN_SPP,
      page: () => PembayaranSppView(),
      binding: PembayaranSppBinding(),
    ),
    GetPage(
      name: _Paths.JADWAL_PELAJARAN,
      page: () => const JadwalPelajaranView(),
      binding: JadwalPelajaranBinding(),
    ),
    GetPage(
      name: _Paths.BUAT_SARPRAS,
      page: () => const BuatSarprasView(),
      binding: BuatSarprasBinding(),
    ),
    GetPage(
      name: _Paths.DATA_SARPRAS,
      page: () => const DataSarprasView(),
      binding: DataSarprasBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA_PERKELAS,
      page: () => DaftarSiswaPerkelasView(),
      binding: DaftarSiswaPerkelasBinding(),
    ),
    GetPage(
      name: _Paths.TAMPILKAN_INFO_SEKOLAH,
      page: () => const TampilkanInfoSekolahView(),
      binding: TampilkanInfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA_PERMAPEL,
      page: () => DaftarSiswaPermapelView(),
      binding: DaftarSiswaPermapelBinding(),
    ),
    GetPage(
      name: _Paths.KELOMPOK_HALAQOH,
      page: () => KelompokHalaqohView(),
      binding: KelompokHalaqohBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_NILAI,
      page: () => DaftarNilaiView(),
      binding: DaftarNilaiBinding(),
    ),
    GetPage(
      name: _Paths.DETAIL_SISWA,
      page: () => const DetailSiswaView(),
      binding: DetailSiswaBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA_PINDAH_HALAQOH,
      page: () => const DaftarSiswaPindahHalaqohView(),
      binding: DaftarSiswaPindahHalaqohBinding(),
    ),
    GetPage(
      name: _Paths.INFO_SEKOLAH_DETAIL,
      page: () => const InfoSekolahDetailView(),
      binding: InfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_NILAI_SISWA,
      page: () => InputNilaiSiswaView(),
      binding: InputNilaiSiswaBinding(),
    ),
    GetPage(
      name: _Paths.RAPOR_SISWA,
      page: () => const RaporSiswaView(),
      binding: RaporSiswaBinding(),
    ),
    GetPage(
      name: _Paths.REKAP_JURNAL_GURU,
      page: () => const RekapJurnalGuruView(),
      binding: RekapJurnalGuruBinding(),
    ),
    GetPage(
      name: _Paths.REKAP_JURNAL_ADMIN,
      page: () => const RekapJurnalAdminView(),
      binding: RekapJurnalAdminBinding(),
    ),
    GetPage(
      name: _Paths.IMPORT_PEGAWAI,
      page: () => const ImportPegawaiView(),
      binding: ImportPegawaiBinding(),
    ),
    GetPage(
      name: _Paths.ROOT,
      page: () => const RootView(),
      binding: RootBinding(),
    ),
    GetPage(
      name: _Paths.PEGAWAI,
      page: () => const PegawaiView(),
      binding: PegawaiBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_PERAN,
      page: () => const ManajemenPeranView(),
      binding: ManajemenPeranBinding(),
    ),
    GetPage(
      name: _Paths.UPSERT_PEGAWAI,
      page: () => const UpsertPegawaiView(),
      binding: UpsertPegawaiBinding(),
    ),
    GetPage(
      name: _Paths.IMPORT_SISWA,
      page: () => const ImportSiswaView(),
      binding: ImportSiswaBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA,
      page: () => const DaftarSiswaView(),
      binding: DaftarSiswaBinding(),
    ),
    GetPage(
      name: _Paths.UPSERT_SISWA,
      page: () => const UpsertSiswaView(),
      binding: UpsertSiswaBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_MAPEL,
      page: () => const MasterMapelView(),
      binding: MasterMapelBinding(),
    ),
    GetPage(
      name: _Paths.PENUGASAN_GURU,
      page: () => const PenugasanGuruView(),
      binding: PenugasanGuruBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_JAM,
      page: () => const MasterJamView(),
      binding: MasterJamBinding(),
    ),
    GetPage(
      name: _Paths.EDITOR_JADWAL,
      page: () => const EditorJadwalView(),
      binding: EditorJadwalBinding(),
    ),
    GetPage(
      name: _Paths.GURU_AKADEMIK,
      page: () => const GuruAkademikView(),
      binding: GuruAkademikBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_NILAI_MASSAL_AKADEMIK,
      page: () => const InputNilaiMassalAkademikView(),
      binding: InputNilaiMassalAkademikBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_MANAGEMENT,
      page: () => const HalaqahManagementView(),
      binding: HalaqahManagementBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_EDIT_HALAQAH_GROUP,
      page: () => const CreateEditHalaqahGroupView(),
      binding: CreateEditHalaqahGroupBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_DASHBOARD_PENGAMPU,
      page: () => const HalaqahDashboardPengampuView(),
      binding: HalaqahDashboardPengampuBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_GRADING,
      page: () => const HalaqahGradingView(),
      binding: HalaqahGradingBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_RIWAYAT_PENGAMPU,
      page: () => const HalaqahRiwayatPengampuView(),
      binding: HalaqahRiwayatPengampuBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_SETORAN_SISWA,
      page: () => const HalaqahSetoranSiswaView(),
      binding: HalaqahSetoranSiswaBinding(),
    ),
    GetPage(
      name: _Paths.HALAQAH_SET_PENGGANTI,
      page: () => const HalaqahSetPenggantiView(),
      binding: HalaqahSetPenggantiBinding(),
    ),
    GetPage(
      name: _Paths.JURNAL_HARIAN_GURU,
      page: () => const JurnalHarianGuruView(),
      binding: JurnalHarianGuruBinding(),
    ),
    GetPage(
      name: _Paths.ABSENSI_WALI_KELAS,
      page: () => const AbsensiWaliKelasView(),
      binding: AbsensiWaliKelasBinding(),
    ),
    GetPage(
      name: _Paths.REKAP_ABSENSI,
      page: () => const RekapAbsensiView(),
      binding: RekapAbsensiBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_EKSKUL_MANAGEMENT,
      page: () => const MasterEkskulManagementView(),
      binding: MasterEkskulManagementBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_EDIT_EKSKUL,
      page: () => const CreateEditEkskulView(),
      binding: CreateEditEkskulBinding(),
    ),
    GetPage(
      name: _Paths.EKSKUL_PENDAFTARAN_MANAGEMENT,
      page: () => const EkskulPendaftaranManagementView(),
      binding: EkskulPendaftaranManagementBinding(),
    ),
    GetPage(
      name: _Paths.ATUR_GURU_PENGGANTI,
      page: () => const AturGuruPenggantiView(),
      binding: AturGuruPenggantiBinding(),
    ),
    GetPage(
      name: _Paths.ATUR_PENGGANTIAN_HOST,
      page: () => const AturPenggantianHostView(),
      binding: AturPenggantianHostBinding(),
    ),
    GetPage(
      name: _Paths.ATUR_PENGGANTIAN_RENTANG,
      page: () => const AturPenggantianRentangView(),
      binding: AturPenggantianRentangBinding(),
    ),
    GetPage(
      name: _Paths.PUSAT_INFORMASI_PENGGANTIAN,
      page: () => const PusatInformasiPenggantianView(),
      binding: PusatInformasiPenggantianBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_JURNAL_PRIBADI,
      page: () => const LaporanJurnalPribadiView(),
      binding: LaporanJurnalPribadiBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_JURNAL_KELAS,
      page: () => const LaporanJurnalKelasView(),
      binding: LaporanJurnalKelasBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_KALENDER_AKADEMIK,
      page: () => const ManajemenKalenderAkademikView(),
      binding: ManajemenKalenderAkademikBinding(),
    ),
    GetPage(
      name: _Paths.INFO_SEKOLAH,
      page: () => const InfoSekolahView(),
      binding: InfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.INFO_SEKOLAH_FORM,
      page: () => const InfoSekolahFormView(),
      binding: InfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.ATP_FORM,
      page: () => const AtpFormView(),
      binding: AtpFormBinding(),
    ),
    GetPage(
      name: _Paths.PERANGKAT_AJAR,
      page: () => const PerangkatAjarView(),
      binding: PerangkatAjarBinding(),
    ),
    GetPage(
      name: _Paths.PROTA_PROSEM,
      page: () => const ProtaProsemView(),
      binding: ProtaProsemBinding(),
    ),
    GetPage(
      name: _Paths.MODUL_AJAR_FORM,
      page: () => const ModulAjarFormView(),
      binding: ModulAjarFormBinding(),
    ),
  ];
}
