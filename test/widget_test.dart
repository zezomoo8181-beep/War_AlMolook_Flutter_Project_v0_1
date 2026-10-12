import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:war_al_molook/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('تظهر واجهة حرب الملوك بعد تحميل الحفظ المحلي', (tester) async {
    await tester.pumpWidget(const WarAlMolookApp());
    await tester.pumpAndSettle();
    expect(find.text('حرب الملوك'), findsOneWidget);
    expect(find.text('القرية'), findsOneWidget);
  });
}
