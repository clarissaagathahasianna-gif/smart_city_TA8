import 'package:flutter_test/flutter_test.dart';

import 'package:smart_city/main.dart';

void main() {
  testWidgets('Validasi form muncul saat field kosong', (tester) async {
    await tester.pumpWidget(const SmartCityApp());

    await tester.tap(find.text('Kirim Laporan'));
    await tester.pump();

    expect(find.text('Judul masalah wajib diisi.'), findsOneWidget);
    expect(find.text('Lokasi wajib diisi.'), findsOneWidget);
  });
}
