import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Deklarasi Formatter Mata Uang
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', // Format Indonesia
      symbol: 'Rp ',  // Simbol Rupiah
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: product['image_1920'] != null &&
                      product['image_1920'] is String
                  ? Image.memory(
                      base64Decode(product['image_1920']),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              product['default_code'] != null &&
                            product['default_code'] != false
                        ? '${product['default_code']} ${product['name']}'
                        : product['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormatter.format(product['list_price'] ?? 0),
              style: const TextStyle(fontSize: 20, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              'Available Products: ${product['qty_available']}',
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
