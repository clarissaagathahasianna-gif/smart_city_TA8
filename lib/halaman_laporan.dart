import 'dart:async';

import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'models/laporan.dart';

class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  static const List<String> _pilihanFilter = ['Semua', ...Laporan.daftarStatus];

  final _cari = TextEditingController();
  Timer? _jedaCari;
  List<Laporan> _laporan = [];
  StatistikLaporan _statistik = const StatistikLaporan();
  String _filter = 'Semua';
  bool _memuat = true;
  String? _error;
  int _nomorPermintaan = 0; // Mengabaikan hasil query lama saat mengetik.

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _jedaCari?.cancel();
    _cari.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  /// Membaca ulang daftar laporan dan angka statistik dari SQLite.
  Future<void> _muat() async {
    final nomor = ++_nomorPermintaan;
    setState(() {
      _memuat = true;
      _error = null;
    });
    try {
      final db = DatabaseHelper.instance;
      final daftar = await db.ambilLaporan(
        kataKunci: _cari.text,
        status: _filter,
      );
      final statistik = await db.ambilStatistik();
      if (!mounted || nomor != _nomorPermintaan) return;
      setState(() {
        _laporan = daftar;
        _statistik = statistik;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted || nomor != _nomorPermintaan) return;
      setState(() {
        _error = 'Gagal memuat laporan: $e';
        _memuat = false;
      });
    }
  }

  void _saatMencari(String _) {
    _jedaCari?.cancel();
    _jedaCari = Timer(const Duration(milliseconds: 300), _muat);
  }

  Future<void> _ubahStatus(Laporan laporan) async {
    final berikut = laporan.statusBerikutnya;
    final id = laporan.id;
    if (berikut == null || id == null) return;
    try {
      await DatabaseHelper.instance.ubahStatus(id, berikut);
      if (!mounted) return;
      _pesan('Status "${laporan.judul}" menjadi $berikut.');
      await _muat();
    } catch (e) {
      if (mounted) _pesan('Gagal mengubah status: $e');
    }
  }

  Future<void> _edit(Laporan lama) async {
    final baru = await showDialog<Laporan>(
      context: context,
      builder: (_) => DialogEditLaporan(laporan: lama),
    );
    if (baru == null || !mounted) return;
    try {
      final jumlah = await DatabaseHelper.instance.ubah(baru);
      if (jumlah != 1) throw StateError('Laporan tidak ditemukan');
      if (!mounted) return;
      _pesan('Laporan berhasil diperbarui.');
      await _muat();
    } catch (e) {
      if (mounted) _pesan('Gagal memperbarui: $e');
    }
  }

  Future<void> _hapus(Laporan laporan) async {
    final id = laporan.id;
    if (id == null) return;
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: Text(
          'Laporan "${laporan.judul}" akan dihapus permanen dari database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;
    try {
      final jumlah = await DatabaseHelper.instance.hapus(id);
      if (jumlah != 1) throw StateError('Laporan tidak ditemukan');
      if (!mounted) return;
      _pesan('Laporan berhasil dihapus.');
      await _muat();
    } catch (e) {
      if (mounted) _pesan('Gagal menghapus: $e');
    }
  }

  // ---------------- Widget pembantu ----------------

  Color _warnaStatus(String status) {
    switch (status) {
      case 'Diproses':
        return Colors.orange.shade700;
      case 'Selesai':
        return Colors.green.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  Color _warnaUrgensi(int urgensi) {
    switch (urgensi) {
      case 3:
        return Colors.red.shade700;
      case 2:
        return Colors.amber.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _badge(String teks, Color warna) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: warna,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      teks,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _kartuStatistik(String judul, int angka, IconData ikon, Color warna) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Icon(ikon, color: warna),
              const SizedBox(height: 4),
              Text(
                '$angka',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: warna,
                ),
              ),
              Text(
                judul,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartuLaporan(Laporan laporan) {
    final aksen = laporan.selesai
        ? Colors.green.shade600
        : laporan.darurat
        ? Colors.red.shade600
        : Theme.of(context).colorScheme.primary;
    final berikut = laporan.statusBerikutnya;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      color: laporan.selesai ? Colors.grey.shade200 : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: aksen, width: 6)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    laporan.judul,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: laporan.selesai ? Colors.grey.shade600 : null,
                      decoration: laporan.selesai
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _badge(laporan.status, _warnaStatus(laporan.status)),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _badge(laporan.kategori, Colors.teal.shade700),
                _badge(laporan.namaUrgensi, _warnaUrgensi(laporan.urgensi)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place, size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text(laporan.lokasi)),
                const Icon(Icons.event, size: 16),
                const SizedBox(width: 4),
                Text(laporan.tanggal),
                const SizedBox(width: 8),
              ],
            ),
            Row(
              children: [
                if (berikut != null)
                  FilledButton.tonalIcon(
                    onPressed: () => _ubahStatus(laporan),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(berikut),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _edit(laporan),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Hapus',
                  onPressed: () => _hapus(laporan),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _isiDaftar() {
    if (_memuat && _laporan.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_laporan.isEmpty) {
      return const Center(child: Text('Tidak ada laporan yang sesuai.'));
    }
    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _laporan.length,
        itemBuilder: (context, index) => _kartuLaporan(_laporan[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Laporan Kota'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _memuat ? null : _muat,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                _kartuStatistik(
                  'Total Laporan',
                  _statistik.total,
                  Icons.assignment,
                  Colors.indigo,
                ),
                _kartuStatistik(
                  'Laporan Aktif',
                  _statistik.aktif,
                  Icons.pending_actions,
                  Colors.orange.shade800,
                ),
                _kartuStatistik(
                  'Laporan Selesai',
                  _statistik.selesai,
                  Icons.task_alt,
                  Colors.green.shade700,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _cari,
              onChanged: _saatMencari,
              decoration: InputDecoration(
                hintText: 'Cari judul atau lokasi...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: 'Bersihkan',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _cari.clear();
                    _muat();
                  },
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final status in _pilihanFilter)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: _filter == status,
                      onSelected: (_) {
                        setState(() => _filter = status);
                        _muat();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_memuat && _laporan.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _isiDaftar()),
        ],
      ),
    );
  }
}

/// Dialog edit berisi form yang sudah terisi data lama.
/// Controller dibuang di dispose() setelah dialog benar-benar tertutup.
class DialogEditLaporan extends StatefulWidget {
  const DialogEditLaporan({super.key, required this.laporan});

  final Laporan laporan;

  @override
  State<DialogEditLaporan> createState() => _DialogEditLaporanState();
}

class _DialogEditLaporanState extends State<DialogEditLaporan> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judul = TextEditingController(
    text: widget.laporan.judul,
  );
  late final TextEditingController _lokasi = TextEditingController(
    text: widget.laporan.lokasi,
  );
  late final TextEditingController _tanggal = TextEditingController(
    text: widget.laporan.tanggal,
  );
  late String _kategori = widget.laporan.kategori;
  late int _urgensi = widget.laporan.urgensi;

  @override
  void dispose() {
    _judul.dispose();
    _lokasi.dispose();
    _tanggal.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();
    final awal = DateTime.tryParse(_tanggal.text) ?? sekarang;
    final dipilih = await showDatePicker(
      context: context,
      initialDate: awal.isAfter(sekarang) ? sekarang : awal,
      firstDate: DateTime(sekarang.year - 5),
      lastDate: sekarang,
    );
    if (dipilih != null) {
      _tanggal.text = Laporan.formatTanggal(dipilih);
    }
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      widget.laporan.copyWith(
        judul: _judul.text.trim(),
        kategori: _kategori,
        lokasi: _lokasi.text.trim(),
        urgensi: _urgensi,
        tanggal: _tanggal.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Laporan'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _judul,
                  decoration: const InputDecoration(labelText: 'Judul Masalah'),
                  validator: (nilai) {
                    final teks = nilai?.trim() ?? '';
                    if (teks.isEmpty) return 'Judul masalah wajib diisi.';
                    if (teks.length < 5) return 'Judul minimal 5 karakter.';
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: _kategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Fasilitas',
                  ),
                  items: [
                    for (final kategori in Laporan.daftarKategori)
                      DropdownMenuItem(value: kategori, child: Text(kategori)),
                  ],
                  onChanged: (nilai) {
                    if (nilai != null) _kategori = nilai;
                  },
                ),
                TextFormField(
                  controller: _lokasi,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi / Kecamatan',
                  ),
                  validator: (nilai) => (nilai?.trim() ?? '').isEmpty
                      ? 'Lokasi wajib diisi.'
                      : null,
                ),
                DropdownButtonFormField<int>(
                  initialValue: _urgensi,
                  decoration: const InputDecoration(
                    labelText: 'Tingkat Urgensi',
                  ),
                  items: [
                    for (final entri in Laporan.labelUrgensi.entries)
                      DropdownMenuItem(
                        value: entri.key,
                        child: Text(entri.value),
                      ),
                  ],
                  onChanged: (nilai) {
                    if (nilai != null) _urgensi = nilai;
                  },
                ),
                TextFormField(
                  controller: _tanggal,
                  readOnly: true,
                  onTap: _pilihTanggal,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Kejadian',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  validator: (nilai) => (nilai ?? '').isEmpty
                      ? 'Tanggal kejadian wajib dipilih.'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _simpan, child: const Text('Simpan')),
      ],
    );
  }
}
