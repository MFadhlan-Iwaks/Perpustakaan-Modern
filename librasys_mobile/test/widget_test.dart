import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:librasys_mobile/main.dart';

void main() {
  testWidgets('App shows login screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const LibraSysApp());
    await tester.pumpAndSettle();

    expect(find.text('LibraSys'), findsOneWidget);
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
