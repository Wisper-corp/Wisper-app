import 'dart:io';

class CurrencyHelper {
  /// Returns '₦' for Nigerian device locale, '$' for everyone else.
  static String get deviceSymbol {
    final locale = Platform.localeName.toLowerCase();
    if (locale.contains('_ng') || locale.contains('ng_')) return '₦';
    return '\$';
  }

  /// Returns symbol based on stored currency code from the post,
  /// falling back to device locale if null.
  static String symbolFor(String? currency) {
    if (currency == 'NGN') return '₦';
    if (currency == 'USD') return '\$';
    return deviceSymbol;
  }

  /// Formats a price with the correct currency symbol.
  /// Uses the post's own currency if provided, else device locale.
  static String format(double price, {String? currency}) {
    final sym = symbolFor(currency);
    final formatted =
        price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);
    return 'from $sym$formatted';
  }

  /// Symbol for input fields — based on device locale.
  static String get inputPrefix => deviceSymbol;

  static bool get isNaira => deviceSymbol == '₦';
}
