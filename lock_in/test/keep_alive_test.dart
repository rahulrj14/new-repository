import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/ui/keepalive/keep_alive_screen.dart';

void main() {
  test('phone makers', () {
    expect(phoneMaker('Xiaomi'), PhoneMaker.xiaomi);
    expect(phoneMaker('POCO'), PhoneMaker.xiaomi);
    expect(phoneMaker('samsung'), PhoneMaker.samsung);
    expect(phoneMaker('OnePlus'), PhoneMaker.oppo);
    expect(phoneMaker('Google'), PhoneMaker.other);
    expect(phoneMaker(null), PhoneMaker.other);
  });

  test('walkthrough only where it matters', () {
    expect(needsKeepAlive({'manufacturer': 'Xiaomi', 'batteryOptimized': false}), isTrue);
    expect(needsKeepAlive({'manufacturer': 'Google', 'batteryOptimized': true}), isTrue);
    expect(needsKeepAlive({'manufacturer': 'Google', 'batteryOptimized': false}), isFalse);
  });
}
