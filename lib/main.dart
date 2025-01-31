import 'package:flutter/material.dart';
import 'form_detail_quotation_screen.dart';
import 'login_screen.dart';
import 'navigation_screen.dart';
import 'odoo_service.dart';
import 'quotation_detail_screen.dart';
import 'sale_order_list_screen.dart';
// import 'currency_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odoo Flutter Integration',
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());

          case '/home':
            final args = settings.arguments as Map<String, dynamic>;
            final OdooService odooService = args['odooService'];
            final int initialIndex =
                args['initialIndex'] ?? 0; // Ambil index dari args

            return MaterialPageRoute(
              builder: (context) => NavigationScreen(
                odooService: odooService,
                initialIndex:
                    initialIndex, // Kirim nilai index ke NavigationScreen
              ),
            );

          case '/formDetail':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => FormDetailQuotation(
                odooService: args['odooService'],
                headerData: args['headerData'],
              ),
            );

          case '/saleOrderList':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) =>
                  SaleOrderListScreen(odooService: args['odooService']),
            );

          case '/quotationDetail':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => QuotationDetailScreen(
                odooService: args['odooService'],
                quotationId: args['quotationId'],
              ),
            );

          default:
            return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
      },
    );
  }
}
