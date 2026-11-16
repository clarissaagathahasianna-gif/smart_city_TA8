import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database_helper.dart';
import 'halaman_laporan.dart';
import 'models/laporan.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hanya Chrome yang memakai SQLite WASM; Android memakai factory bawaan.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const SmartCityApp());
}

class SmartCityApp extends StatelessWidget {
  const SmartCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lapor Fasilitas Kota',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const HalamanInput(),
    );
  }
}

class HalamanInput extends StatefulWidget {
  const HalamanInput({super.key});

  @override
  State<HalamanInput> createState() => _HalamanInputState();
}

class _HalamanInputState extends State<HalamanInput> {
  final _formKey = GlobalKey<FormState>();
  final _judul = TextEditingController();
  final _lokasi = TextEditingController();
  final _tanggal = TextEditingController();
  String? _kategori;
  int? _urgensi;
  bool _menyimpan = false;
  int _versiForm = 0; // Dinaikkan agar dropdown kembali kosong setelah kirim.

  @override
  void dispose() {
    _judul.dispose();
    _lokasi.dispose();
    _tanggal.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();
    final dipilih = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_tanggal.text) ?? sekarang,
      firstDate: DateTime(sekarang.year - 5),
      lastDate: sekarang,
    );
    if (dipilih != null) {
      _tanggal.text = Laporan.formatTanggal(dipilih);
    }
  }

  Future<void> _kirim() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    try {
      await DatabaseHelper.instance.tambah(
        Laporan(
          judul: _judul.text.trim(),
          kategori: _kategori!,
          lokasi: _lokasi.text.trim(),
          urgensi: _urgensi!,
          tanggal: _tanggal.text,
        ),
      );
      if (!mounted) return;
      _judul.clear();
      _lokasi.clear();
      _tanggal.clear();
      setState(() {
        _kategori = null;
        _urgensi = null;
        _versiForm++;
      });
      _pesan('Laporan berhasil dikirim.');
    } catch (e) {
      if (mounted) _pesan('Gagal mengirim laporan: $e');
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Fasilitas Publik')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judul,
              decoration: const InputDecoration(
                labelText: 'Judul Masalah',
                border: OutlineInputBorder(),
              ),
              validator: (nilai) {
                final teks = nilai?.trim() ?? '';
                if (teks.isEmpty) return 'Judul masalah wajib diisi.';
                if (teks.length < 5) return 'Judul minimal 5 karakter.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('kategori-$_versiForm'),
              initialValue: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori Fasilitas',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final kategori in Laporan.daftarKategori)
                  DropdownMenuItem(value: kategori, child: Text(kategori)),
              ],
              onChanged: (nilai) {
                _kategori = nilai;
              },
              validator: (nilai) =>
                  nilai == null ? 'Kategori fasilitas wajib dipilih.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lokasi,
              decoration: const InputDecoration(
                labelText: 'Lokasi / Kecamatan',
                border: OutlineInputBorder(),
              ),
              validator: (nilai) =>
                  (nilai?.trim() ?? '').isEmpty ? 'Lokasi wajib diisi.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey('urgensi-$_versiForm'),
              initialValue: _urgensi,
              decoration: const InputDecoration(
                labelText: 'Tingkat Urgensi',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final entri in Laporan.labelUrgensi.entries)
                  DropdownMenuItem(value: entri.key, child: Text(entri.value)),
              ],
              onChanged: (nilai) {
                _urgensi = nilai;
              },
              validator: (nilai) =>
                  nilai == null ? 'Tingkat urgensi wajib dipilih.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tanggal,
              readOnly: true, // Tanggal hanya bisa dipilih, tidak diketik.
              onTap: _pilihTanggal,
              decoration: const InputDecoration(
                labelText: 'Tanggal Kejadian',
                hintText: 'Ketuk untuk memilih tanggal',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_month),
              ),
              validator: (nilai) => (nilai ?? '').isEmpty
                  ? 'Tanggal kejadian wajib dipilih.'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _menyimpan ? null : _kirim,
              icon: _menyimpan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_menyimpan ? 'Mengirim...' : 'Kirim Laporan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const HalamanLaporan(),
                  ),
                );
              },
              icon: const Icon(Icons.location_city),
              label: const Text('Pantau Laporan Kota'),
            ),
          ],
        ),
      ),
    );
  }
}
