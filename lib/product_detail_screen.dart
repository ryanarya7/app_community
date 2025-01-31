import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'currency_helper.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          product['name'],
          style: GoogleFonts.poppins(
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar di bagian atas
            Container(
              height: 250, // Tinggi tetap untuk gambar
              width: double.infinity, // Lebar penuh
              decoration: BoxDecoration(),
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

            // Detail Produk
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nama Produk
                  Text(
                    product['default_code'] != null &&
                            product['default_code'] != false
                        ? '${product['default_code']} ${product['name']}'
                        : product['name'],
                    style: GoogleFonts.lato(
                      textStyle:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Harga Produk
                  Text(
                    CurrencyHelper()
                        .currencyFormatter
                        .format(product['list_price'] ?? 0),
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ketersediaan Produk
                  Text(
                    'Available Products: ${product['qty_available']}',
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deskripsi Produk (jika ada)
                  if (product['description'] != null)
                    Text(
                      product['description'],
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
