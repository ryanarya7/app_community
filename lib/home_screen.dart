import 'dart:convert';
import 'currency_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'odoo_service.dart';
import 'product_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

class HomeScreen extends StatefulWidget {
  final OdooService odooService;

  const HomeScreen({Key? key, required this.odooService}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId; // ID kategori yang dipilih
  bool _isGridView = true;
  bool _isCategoryLoading = false; // Status loading kategori
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProducts();
    _initializeCategories();
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

  Future<void> _initializeCategories() async {
    setState(() {
      _isCategoryLoading = true;
    });

    try {
      final categories = await widget.odooService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    } finally {
      setState(() {
        _isCategoryLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      // Ambil produk berdasarkan kategori
      List<Map<String, dynamic>> baseProducts = _selectedCategoryId == null
          ? List.from(_products) // Semua produk
          : _products.where((product) {
              final category = product['category_id'];

              // Tangani format `category_id`
              if (category is List && category.isNotEmpty) {
                return category.first.toString() == _selectedCategoryId;
              }
              if (category is String || category is int) {
                return category.toString() == _selectedCategoryId;
              }
              return false; // Produk tanpa kategori tidak termasuk
            }).toList();

      // Filter berdasarkan pencarian
      if (query.isEmpty) {
        _filteredProducts = baseProducts;
      } else {
        _filteredProducts = baseProducts.where((product) {
          final name = product['name'];
          final code = product['default_code'];

          // Pastikan hanya string yang diproses
          final nameStr = name is String ? name.toLowerCase() : '';
          final codeStr = code is String ? code.toLowerCase() : '';

          return nameStr.contains(query.toLowerCase()) ||
              codeStr.contains(query.toLowerCase());
        }).toList();
      }
    });

    // Log debugging
    debugPrint('Search query: $query');
    debugPrint('Filtered products count: ${_filteredProducts.length}');
  }

  void _filterProductsByCategory(String? categoryId) async {
    setState(() {
      // Jika kategori yang dipilih sama dengan yang sudah aktif, batalkan pilihan
      if (_selectedCategoryId == categoryId) {
        _selectedCategoryId = null;
        // Memanggil ulang semua produk
        _initializeProducts();
        return;
      }

      _selectedCategoryId = categoryId; // Set kategori yang dipilih
    });

    // Jika kategori dilepas, tidak fetch produk berdasarkan kategori
    if (categoryId == null) return;

    try {
      // Fetch produk berdasarkan kategori yang dipilih
      final products =
          await widget.odooService.fetchProductsByCategory(categoryId);
      setState(() {
        _filteredProducts = products;
      });
    } catch (e) {
      print('Error fetching products by category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products by category: $e')),
      );
    }
  }

  Widget _buildCategoryList() {
    if (_isCategoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 60, // Tinggi baris kategori
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected =
              _selectedCategoryId == category['id'].toString(); // Status aktif

          return GestureDetector(
            onTap: () {
              _filterProductsByCategory(category['id'].toString());
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isSelected ? Colors.grey[500] : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.grey : Colors.grey,
                  width: 1.5,
                ),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Center(
                child: Text(
                  category['name'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.grey[900] : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductListTile(Map<String, dynamic> product, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Produk
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product['image_1920'] is String &&
                        product['image_1920'] != ''
                    ? Image.memory(
                        base64Decode(product['image_1920']),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 50);
                        },
                      )
                    : const Icon(Icons.image_not_supported, size: 50),
              ),
              const SizedBox(width: 10),
              // Informasi Produk
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Produk
                    Text(
                      product['name'] ?? 'Unknown Product',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Harga
                    Text(
                      CurrencyHelper()
                          .currencyFormatter
                          .format(product['list_price'] ?? 0),
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Ketersediaan
                    Text(
                      'Available: ${product['qty_available'] ?? 0}',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          mainAxisSize: MainAxisSize.min, // Membatasi tinggi sesuai konten
          children: [
            // Gambar Produk
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
            // Informasi Produk
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Pastikan tinggi sesuai isi
                children: [
                  // Nama Produk
                  Text(
                    product['default_code'] != null &&
                            product['default_code'] != false
                        ? '${product['default_code']} ${product['name']}'
                        : product['name'],
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Harga Produk
                  Text(
                    CurrencyHelper()
                        .currencyFormatter
                        .format(product['list_price'] ?? 0),
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Ketersediaan Produk
                  Text(
                    'Available: ${product['qty_available'] ?? 0}',
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    maxLines: 1,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: TextField(
            controller: _searchController,
            onChanged: _filterProducts,
            decoration: InputDecoration(
              prefixIcon: const Icon(CupertinoIcons.search, color: Colors.grey),
              hintText: 'Search Products',
              hintStyle: GoogleFonts.poppins(
                textStyle: TextStyle(color: Colors.grey),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.poppins(
              textStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView
                  ? CupertinoIcons.rectangle_grid_1x2
                  : CupertinoIcons.rectangle_grid_2x2,
              color: Colors.grey,
            ),
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
          // Categories Horizontal List
          _buildCategoryList(),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      'No products found',
                      style: GoogleFonts.robotoCondensed(
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                : _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent:
                              200, // Lebar maksimal setiap tile/card
                          mainAxisSpacing: 10, // Jarak antar baris
                          crossAxisSpacing: 10, // Jarak antar kolom
                          childAspectRatio:
                              0.7, // Rasio aspek tile (lebar:tinggi)
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductTile(
                              _filteredProducts[index], index);
                        },
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
