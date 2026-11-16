class Laporan {
  static const List<String> daftarKategori = [
    'Penerangan',
    'Jalan',
    'Drainase',
    'Sampah',
    'Lalu Lintas',
  ];

  static const List<String> daftarStatus = ['Baru', 'Diproses', 'Selesai'];

  static const Map<int, String> labelUrgensi = {
    1: 'Normal',
    2: 'Mendesak',
    3: 'Darurat',
  };

  final int? id;
  final String judul;
  final String kategori;
  final String lokasi;
  final int urgensi;
  final String tanggal; // Format YYYY-MM-DD
  final String status;

  const Laporan({
    this.id,
    required this.judul,
    required this.kategori,
    required this.lokasi,
    required this.urgensi,
    required this.tanggal,
    this.status = 'Baru',
  });

  bool get selesai => status == 'Selesai';
  bool get darurat => urgensi == 3;
  String get namaUrgensi => labelUrgensi[urgensi] ?? 'Normal';

  /// Status berikutnya pada alur Baru -> Diproses -> Selesai.
  /// Bernilai null jika laporan sudah Selesai.
  String? get statusBerikutnya {
    final posisi = daftarStatus.indexOf(status);
    if (posisi < 0 || posisi >= daftarStatus.length - 1) return null;
    return daftarStatus[posisi + 1];
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'judul': judul,
    'kategori': kategori,
    'lokasi': lokasi,
    'urgensi': urgensi,
    'tanggal': tanggal,
    'status': status,
  };

  factory Laporan.fromMap(Map<String, Object?> map) => Laporan(
    id: (map['id'] as num?)?.toInt(),
    judul: map['judul'] as String,
    kategori: map['kategori'] as String,
    lokasi: map['lokasi'] as String,
    urgensi: (map['urgensi'] as num?)?.toInt() ?? 1,
    tanggal: map['tanggal'] as String,
    status: map['status'] as String? ?? 'Baru',
  );

  Laporan copyWith({
    String? judul,
    String? kategori,
    String? lokasi,
    int? urgensi,
    String? tanggal,
    String? status,
  }) => Laporan(
    id: id,
    judul: judul ?? this.judul,
    kategori: kategori ?? this.kategori,
    lokasi: lokasi ?? this.lokasi,
    urgensi: urgensi ?? this.urgensi,
    tanggal: tanggal ?? this.tanggal,
    status: status ?? this.status,
  );

  /// Mengubah DateTime menjadi teks YYYY-MM-DD tanpa package intl.
  static String formatTanggal(DateTime tanggal) {
    final tahun = tanggal.year.toString().padLeft(4, '0');
    final bulan = tanggal.month.toString().padLeft(2, '0');
    final hari = tanggal.day.toString().padLeft(2, '0');
    return '$tahun-$bulan-$hari';
  }
}

/// Hasil query agregasi COUNT untuk dashboard.
class StatistikLaporan {
  final int total;
  final int aktif;
  final int selesai;

  const StatistikLaporan({this.total = 0, this.aktif = 0, this.selesai = 0});

  factory StatistikLaporan.fromMap(Map<String, Object?> map) =>
      StatistikLaporan(
        total: _angka(map['total']),
        aktif: _angka(map['aktif']),
        selesai: _angka(map['selesai']),
      );

  static int _angka(Object? nilai) => (nilai as num?)?.toInt() ?? 0;
}
