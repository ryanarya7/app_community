import 'package:intl/intl.dart';
import 'odoo_service.dart';

class CurrencyHelper {
  static final CurrencyHelper _instance = CurrencyHelper._internal();
  late NumberFormat currencyFormatter;

  factory CurrencyHelper() => _instance;

  CurrencyHelper._internal();

  Future<void> init(OdooService odooService) async {
    try {
      final currencyInfo = await odooService.fetchCurrencyInfo();
      final symbol = currencyInfo['symbol'] ?? '\$'; // Default ke $

      currencyFormatter = NumberFormat.currency(
        symbol: '$symbol ',  // Menambahkan spasi setelah simbol
        decimalDigits: 2,
      );
    } catch (e) {
      currencyFormatter = NumberFormat.currency(
        symbol: '\$ ',  // Default jika gagal
        decimalDigits: 2,
      );
    }
  }
}
