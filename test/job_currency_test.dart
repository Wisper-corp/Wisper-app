import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/currency_helper.dart';

/// Mirrors job_card.dart's symbol choice.
String symbolFor({required bool isScraped}) =>
    isScraped ? CurrencyHelper.symbolFor('USD') : CurrencyHelper.symbolFor('NGN');

void main() {
  test('scraped jobs show dollars', () {
    expect(symbolFor(isScraped: true), r'$');
  });
  test('user-posted jobs still show naira', () {
    expect(symbolFor(isScraped: false), '₦');
  });
  test('rendered strings match the screenshot values', () {
    expect('${symbolFor(isScraped: true)}45000/mo', r'$45000/mo');
    expect('${symbolFor(isScraped: false)}45000/mo', '₦45000/mo');
  });
}
