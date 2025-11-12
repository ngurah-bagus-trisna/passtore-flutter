// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pass_manager/app/app_root.dart';
import 'package:pass_manager/data/pin_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  testWidgets('renders unlock screen on launch', (WidgetTester tester) async {
    final pinRepository = PinRepository(storage: const FlutterSecureStorage());
    await pinRepository.savePin('1234');
    await tester.pumpWidget(const AppRoot());
    await tester.pump();

    expect(find.text('Enter your PIN'), findsOneWidget);
  });
}
