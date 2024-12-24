import 'package:flutter/material.dart';
import 'odoo_service.dart';

class FormDetailQuotation extends StatefulWidget {
  final OdooService odooService;
  final Map<String, dynamic> headerData;

  const FormDetailQuotation({
    Key? key,
    required this.odooService,
    required this.headerData,
  }) : super(key: key);

  @override
  _FormDetailQuotationState createState() => _FormDetailQuotationState();
}

class _FormDetailQuotationState extends State<FormDetailQuotation> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = []; // Produk yang difilter
  List<Map<String, dynamic>> quotationLines = [];
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController(); // Controller untuk search bar

  @override
  void initState() {
    super.initState();
    _loadProducts();

    // Listener untuk Search Bar
    _searchController.addListener(_filterProducts);
  }

  Future<void> _loadProducts() async {
    try {
      final fetchedProducts = await widget.odooService.fetchProducts();
      setState(() {
        // Filter products to exclude items with qty_available <= 0
        products = fetchedProducts.where((p) => p['qty_available'] > 0).toList();
        filteredProducts = List.from(products); // Salin semua produk ke list yang difilter
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        // Ambil nilai name dan default_code dengan validasi
        final name = product['name']?.toLowerCase() ?? '';
        final code = product['default_code'];
        final lowerCaseCode = (code != null && code is String) ? code.toLowerCase() : '';

        // Pastikan nama atau kode cocok dengan query
        return name.contains(query) || lowerCaseCode.contains(query);
      }).toList();
    });
  }

  void _addProductLine(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = quotationLines.indexWhere((line) => line['product_id'] == product['id']);
      if (existingIndex >= 0) {
        final availableQty = product['qty_available'];
        if (quotationLines[existingIndex]['product_uom_qty'] < availableQty) {
          quotationLines[existingIndex]['product_uom_qty'] += 1;
        }
      } else {
        quotationLines.add({
          'product_id': product['id'],
          'product_template_id': product['id'],
          'name': '${product['default_code']} ${product['name']}',
          'product_uom_qty': 1,
          'product_uom': product['uom_id'][0],
          'price_unit': product['list_price'],
          'qty_available': product['qty_available'],
        });
      }
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final currentQty = quotationLines[index]['product_uom_qty'] ?? 0;
      final maxQty = quotationLines[index]['qty_available'] ?? double.infinity;
      final newQty = currentQty + delta;

      if (newQty > 0 && newQty <= maxQty) {
        quotationLines[index]['product_uom_qty'] = newQty;
      } else if (newQty <= 0) {
        _removeLine(index);
      }
    });
  }

  void _updatePriceUnit(int index, String newPrice) {
    setState(() {
      quotationLines[index]['price_unit'] = double.tryParse(newPrice) ?? quotationLines[index]['price_unit'];
    });
  }

  void _addNoteLine() {
    if (_noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be empty.')),
      );
      return;
    }
    setState(() {
      quotationLines.add({
        'name': _noteController.text,
        'display_type': 'line_note',
      });
      _noteController.clear();
    });
  }

  void _removeLine(int index) {
    setState(() {
      quotationLines.removeAt(index);
    });
  }

  Future<void> _saveQuotationLines() async {
    try {
      for (var line in quotationLines) {
        await widget.odooService.addQuotationLine(widget.headerData['quotationId'], line);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation lines saved successfully!')),
      );
      Navigator.pushNamed(
        context,
        '/quotationDetail',
        arguments: widget.headerData['quotationId'],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quotation lines: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Detail Quotation", 
          style: TextStyle(
            fontWeight: FontWeight.bold)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Judul Products
            const Text("Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search products...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // List Produk
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return Card(
                    child: ListTile(
                      title: Text("[${product['default_code']}] ${product['name']}"),
                      subtitle: Text("Price: ${product['list_price']} | Available: ${product['qty_available']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: () => _addProductLine(product),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Add Note
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(hintText: "Enter note here..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: _addNoteLine,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Judul Order Lines
            const Text("Order Lines", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // List Quotation Lines
            Expanded(
              child: ListView.builder(
                itemCount: quotationLines.length,
                itemBuilder: (context, index) {
                  final line = quotationLines[index];
                  return Card(
                    child: ListTile(
                      title: Text(line['name']),
                      subtitle: line['display_type'] == 'line_note'
                          ? const Text("Note")
                          : Row(
                              children: [
                                const Text("Price: "),
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    initialValue: line['price_unit'].toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => _updatePriceUnit(index, value),
                                  ),
                                ),
                              ],
                            ),
                      trailing: line['display_type'] == 'line_note'
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeLine(index),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle,
                                    color: (line['product_uom_qty'] ?? 0) > 0 ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: (line['product_uom_qty'] ?? 0) > 0
                                      ? () => _updateQuantity(index, -1)  // Tombol - mengurangi quantity
                                      : null,  // Jika quantity <= 0, tombol tidak aktif
                                ),
                                Text("${line['product_uom_qty']}"),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: (line['product_uom_qty'] ?? 0) < (line['qty_available'] ?? 0)
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onPressed: (line['product_uom_qty'] ?? 0) < (line['qty_available'] ?? 0)
                                      ? () => _updateQuantity(index, 1)  // Tambah Quantity
                                      : null,  // Jika sudah maksimal, tombol tidak aktif
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeLine(index),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),

            // Save Button
            Center(
              child: ElevatedButton(
                onPressed: _saveQuotationLines,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("Save Quotation Lines", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
