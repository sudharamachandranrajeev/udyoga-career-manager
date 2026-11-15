import 'package:flutter_test/flutter_test.dart';
import 'package:udyoga/domain/feeds.dart';

void main() {
  test('the closing date in an advert page', () {
    expect(closingIn('Date posted 03 November 2026\nClosing date 17 November 2026\nSalary'), '2026-11-17');
    expect(closingIn('This job closes on Wednesday 26 Nov 2026 at midnight'), '2026-11-26');
    expect(closingIn('Closing date: 19/11/2026'), '2026-11-19');
    expect(closingIn('Closes 5 Sept 2026'), '2026-09-05');
    expect(closingIn('No date here'), isNull);
    expect(closingIn('Closing date: 40 Smarch 2026'), isNull);
  });

  test('the yearly salary range in an advert page', () {
    expect(salaryIn('Band 4\n£28,392 to £31,157 a year\nPer annum pro rata'), (28392, 31157));
    expect(salaryIn('Salary £32,073 - £34,581'), (32073, 34581));
    expect(salaryIn('£24,937 a year'), (24937, 24937));
    expect(salaryIn('£12.60 an hour'), (null, null));
  });
}
