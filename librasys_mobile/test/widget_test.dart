import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:librasys_mobile/main.dart';

void main() {
  testWidgets('App shows login screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const LibraSysApp());
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk untuk melanjutkan ke LibraSys'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
