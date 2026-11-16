import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models/laporan.dart';

/// Satu-satunya pintu akses ke database smart_city.db (pola singleton).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String namaDatabase = 'smart_city.db';
  static const int versiDatabase = 2;
  static const String tabel = 'laporan';

  Future<Database>? _koneksi;

  Future<Database> get database async {
    try {
      return await (_koneksi ??= _bukaDatabase());
    } catch (_) {
      _koneksi = null; // Izinkan percobaan ulang jika gagal dibuka.
      rethrow;
    }
  }

  Future<Database> _bukaDatabase() async {
    // Web: nama tetap (disimpan di IndexedDB). Android: folder database app.
    final lokasi = kIsWeb
        ? namaDatabase
        : p.join(await getDatabasesPath(), namaDatabase);
    return openDatabase(
      lokasi,
      version: versiDatabase,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Dipanggil sekali saat database belum ada (instalasi baru).
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE laporan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT NOT NULL,
        kategori TEXT NOT NULL,
        lokasi TEXT NOT NULL,
        urgensi INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Baru'
      )
    ''');
  }

  /// Migrasi v1 -> v2: versi 1 belum memiliki kolom urgensi dan status.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE laporan ADD COLUMN urgensi INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        "ALTER TABLE laporan ADD COLUMN status TEXT NOT NULL DEFAULT 'Baru'",
      );
    }
  }

  // ---------------- CREATE ----------------
  Future<int> tambah(Laporan laporan) async {
    final db = await database;
    return db.insert(tabel, laporan.toMap());
  }

  // ---------------- READ ----------------
  /// Mengambil laporan dengan pencarian (judul/lokasi) dan filter status.
  /// Nilai dari pengguna hanya dikirim lewat whereArgs, tidak disambung ke SQL.
  Future<List<Laporan>> ambilLaporan({
    String kataKunci = '',
    String status = 'Semua',
  }) async {
    final db = await database;
    final kondisi = <String>[];
    final argumen = <Object?>[];

    final kata = kataKunci.trim();
    if (kata.isNotEmpty) {
      kondisi.add('(judul LIKE ? OR lokasi LIKE ?)');
      argumen.addAll(['%$kata%', '%$kata%']);
    }
    if (status != 'Semua') {
      kondisi.add('status = ?');
      argumen.add(status);
    }

    final hasil = await db.query(
      tabel,
      where: kondisi.isEmpty ? null : kondisi.join(' AND '),
      whereArgs: argumen.isEmpty ? null : argumen,
      // Belum selesai di atas, lalu urgensi tertinggi, lalu tanggal terlama.
      orderBy:
          "CASE status WHEN 'Selesai' THEN 1 ELSE 0 END, "
          'urgensi DESC, tanggal ASC',
    );
    return hasil.map(Laporan.fromMap).toList();
  }

  /// Query agregasi COUNT untuk tiga kartu dashboard.
  Future<StatistikLaporan> ambilStatistik() async {
    final db = await database;
    final hasil = await db.rawQuery(
      'SELECT COUNT(*) AS total, '
      'COUNT(CASE WHEN status IN (?, ?) THEN 1 END) AS aktif, '
      'COUNT(CASE WHEN status = ? THEN 1 END) AS selesai '
      'FROM laporan',
      ['Baru', 'Diproses', 'Selesai'],
    );
    return StatistikLaporan.fromMap(hasil.first);
  }

  // ---------------- UPDATE ----------------
  Future<int> ubah(Laporan laporan) async {
    final db = await database;
    return db.update(
      tabel,
      laporan.toMap(),
      where: 'id = ?',
      whereArgs: [laporan.id],
    );
  }

  Future<int> ubahStatus(int id, String status) async {
    final db = await database;
    return db.update(
      tabel,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- DELETE ----------------
  Future<int> hapus(int id) async {
    final db = await database;
    return db.delete(tabel, where: 'id = ?', whereArgs: [id]);
  }
}
