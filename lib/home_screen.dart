import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'odoo_service.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final OdooService odooService;

  const HomeScreen({Key? key, required this.odooService}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProducts();
  }

  Future<void> _initializeProducts() async {
    try {
      final products = await widget.odooService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _filteredProducts = products;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final name = product['name'];
          final code = product['default_code'];
          final nameStr = name is String ? name.toLowerCase() : '';
          final codeStr = code is String ? code.toLowerCase() : '';

          return nameStr.contains(query.toLowerCase()) ||
              codeStr.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget _buildProductTile(Map<String, dynamic> product, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProductDetailScreen(product: product),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: product['image_1920'] is String &&
                        product['image_1920'] != ''
                    ? Image.memory(
                        base64Decode(product['image_1920']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 50);
                        },
                      )
                    : const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['default_code'] != null &&
                            product['default_code'] != false
                        ? '${product['default_code']} ${product['name']}'
                        : product['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Rp.${product['list_price']}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Available: ${product['qty_available']}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 500)).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: const Duration(milliseconds: 500),
          ),
    );
  }

  Widget _buildProductListTile(Map<String, dynamic> product, int index) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProductDetailScreen(product: product),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      leading: product['image_1920'] is String && product['image_1920'] != ''
          ? Image.memory(
              base64Decode(product['image_1920']),
              fit: BoxFit.cover,
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 50);
              },
            )
          : const Icon(Icons.image_not_supported, size: 50),
      title: Text(
        '${product['name']}',
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${product['default_code']}',
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          Text(
            'Rp.${product['list_price']}',
            style: const TextStyle(color: Colors.green, fontSize: 14),
          ),
          Text(
            'Available: ${product['qty_available']}',
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
      isThreeLine: true,
    ).animate().fadeIn(duration: const Duration(milliseconds: 500)).slideY(
          begin: -0.1,
          end: 0.0,
          duration: const Duration(milliseconds: 500),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products',
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue[300],
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search products...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(child: Text('No products found'))
                : _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductTile(
                              _filteredProducts[index], index);
                        },
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductListTile(
                              _filteredProducts[index], index);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
