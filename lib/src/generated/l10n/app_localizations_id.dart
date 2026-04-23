// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => 'Jalankan';

  @override
  String get stop => 'Hentikan';

  @override
  String get config => 'Konfig';

  @override
  String get webAdmin => 'Admin Web';

  @override
  String get logs => 'Log';

  @override
  String get viewLogs => 'Lihat log';

  @override
  String get statusRunning => 'Berjalan';

  @override
  String get statusStopped => 'Dihentikan';

  @override
  String get settings => 'Pengaturan';

  @override
  String get address => 'Alamat';

  @override
  String get port => 'Port';

  @override
  String get save => 'Simpan';

  @override
  String get showWindow => 'Tampilkan jendela';

  @override
  String get exit => 'Keluar';

  @override
  String get binaryPath => 'Jalur biner';

  @override
  String get browse => 'Telusuri';

  @override
  String get pathError => 'Jalur tidak valid';

  @override
  String get arguments => 'Argumen';

  @override
  String get argumentsHint => 'mis. config.json';

  @override
  String get notStarted => 'Layanan belum dimulai';

  @override
  String get startHint => 'Silakan mulai layanan dari panel terlebih dahulu.';

  @override
  String get goToDashboard => 'Ke panel';

  @override
  String get back => 'Kembali';

  @override
  String get forward => 'Maju';

  @override
  String get refresh => 'Segarkan';

  @override
  String get coreBinaryMissing =>
      'Biner inti tidak ditemukan. Tempatkan biner platform di app/bin/ atau atur jalur di Pengaturan.';

  @override
  String get coreStartFailed => 'Gagal memulai layanan inti.';

  @override
  String get coreStopFailed => 'Gagal menghentikan layanan inti.';

  @override
  String get coreInvalidBinary => 'File biner inti tidak valid.';

  @override
  String coreUnknownError(Object code) {
    return 'Kesalahan inti tidak dikenal: $code';
  }

  @override
  String get coreValid => 'Biner inti valid.';

  @override
  String get publicMode => 'Mode publik';

  @override
  String get publicModeHintDesc =>
      'Bila diaktifkan, layanan mengizinkan akses eksternal dan kolom alamat akan dinonaktifkan';

  @override
  String get themeSelection => 'Tema';

  @override
  String get check => 'Periksa';

  @override
  String get launchService => 'MULAI LAYANAN';

  @override
  String get stopService => 'HENTIKAN LAYANAN';

  @override
  String get endpoint => 'TITIK AKHIR';

  @override
  String get statusActive => 'AKTIF';

  @override
  String get statusSyncing => 'MENYINKRONKAN';

  @override
  String get statusIdle => 'MENGANGGU';

  @override
  String get publicModeEnabled => 'Mode publik diaktifkan';

  @override
  String get localMode => 'Mode lokal';

  @override
  String get unableToGetDeviceIp => 'Tidak dapat mendapatkan IP perangkat';

  @override
  String get deviceReportingTitle => 'Umpan balik kompatibilitas perangkat';

  @override
  String get deviceReportingSubtitle =>
      'Hanya digunakan untuk memverifikasi kompatibilitas versi OS dan versi aplikasi. Tidak melibatkan pesan obrolan, detail akun, atau konten pribadi';

  @override
  String get deviceReportingConsentTitle =>
      'Bantu meningkatkan kompatibilitas perangkat';

  @override
  String get deviceReportingConsentDescription =>
      'Bila diaktifkan, hanya ID instalasi anonim, versi OS, dan versi aplikasi yang dikirim untuk memahami kompatibilitas. Bahasa dan kawasan dapat dikumpulkan secara terpisah oleh Firebase Analytics. Tidak ada pesan obrolan, konten yang diketik, detail akun, file, atau pengaturan kustom yang diunggah';

  @override
  String get deviceReportingBannerDescription =>
      'Hanya ID instalasi anonim, versi OS, dan versi aplikasi yang disinkronkan untuk meningkatkan kompatibilitas. Bahasa dan kawasan dapat dikumpulkan secara terpisah oleh Firebase Analytics. Tidak ada pesan obrolan, detail akun, file, atau konten pribadi yang dikirim';

  @override
  String get deviceReportingWhatWillBeSent =>
      'Hanya detail perangkat ini yang disertakan';

  @override
  String get deviceReportingDeviceLabel => 'Model Perangkat';

  @override
  String get deviceReportingPlatformLabel => 'Kategori Perangkat';

  @override
  String get deviceReportingSystemLabel => 'Versi OS';

  @override
  String get deviceReportingTimingNote =>
      'Sinkronisasi berjalan sekali saat diaktifkan, dan lagi hanya setelah pembaruan sistem terdeteksi';

  @override
  String get deviceReportingDeny => 'Belum sekarang';

  @override
  String get deviceReportingAllow => 'Aktifkan';

  @override
  String get deviceReportingUploadSucceeded =>
      'Umpan balik kompatibilitas perangkat aktif';

  @override
  String get deviceReportingUploadFailed =>
      'Umpan balik kompatibilitas perangkat aktif, tetapi sinkronisasi info perangkat saat ini tidak selesai';

  @override
  String get deviceReportingDisabled =>
      'Umpan balik kompatibilitas perangkat nonaktif';

  @override
  String get localModeHint =>
      '1. Buka Konfigurasi layanan\n2. Aktifkan Mode publik\n3. Mulai ulang layanan\n4. Pindai kode QR untuk mengakses PicoClaw';

  @override
  String get publicModeHint =>
      '1. Mulai layanan\n2. Pindai kode QR untuk mengakses PicoClaw';

  @override
  String get noLogsToExport => 'Tidak ada log untuk diekspor';

  @override
  String get logsSavedToMediaLibrary =>
      'Log disimpan ke Unduhan (perpustakaan media Android)';

  @override
  String logsSavedToDownloads(Object path) {
    return 'Log disimpan ke Unduhan: $path';
  }

  @override
  String get shareLogsText => 'Log Picoclaw';

  @override
  String get workspaceDirectory => 'Ruang kerja';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'Log disimpan ke Unduhan (perpustakaan media Android): $name';
  }

  @override
  String shareFailed(Object error) {
    return 'Gagal membuka dialog berbagi: $error';
  }

  @override
  String get exportLogs => 'Ekspor log';

  @override
  String logEventsCount(int count) {
    return '$count PERISTIWA';
  }

  @override
  String get unsavedChanges => 'Perubahan belum disimpan';

  @override
  String get unsavedChangesHint =>
      'Anda memiliki perubahan yang belum disimpan. Apakah Anda ingin membuangnya?';

  @override
  String get cancel => 'Batal';

  @override
  String get discard => 'Buang';

  @override
  String get saved => 'Disimpan';

  @override
  String get language => 'Bahasa';

  @override
  String get selectLanguage => 'Pilih bahasa';

  @override
  String get about => 'Tentang';

  @override
  String get aboutDescription =>
      'PicoClaw adalah aplikasi Flutter lintas platform untuk mengelola layanan PicoClaw.';

  @override
  String get aboutAppVersionLabel => 'Versi PicoClaw';

  @override
  String get aboutCoreVersionLabel => 'Versi PicoClaw Core';

  @override
  String get aboutVersionUnavailable => 'Tidak tersedia';

  @override
  String get picoclawOfficial => 'Situs Resmi PicoClaw';

  @override
  String get sipeedOfficial => 'Situs Resmi Sipeed';

  @override
  String get openLinkFailed => 'Gagal membuka tautan resmi.';

  @override
  String get close => 'Tutup';
}
