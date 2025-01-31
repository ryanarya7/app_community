import 'package:flutter/material.dart';
import 'dart:convert';
import 'odoo_service.dart';
import 'currency_helper.dart';
import 'edit_header_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

class QuotationDetailScreen extends StatefulWidget {
  final OdooService odooService;
  final int quotationId;

  const QuotationDetailScreen({
    Key? key,
    required this.odooService,
    required this.quotationId,
  }) : super(key: key);

  @override
  _QuotationDetailScreenState createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  late Future<Map<String, dynamic>> quotationDetails;
  late List<Map<String, dynamic>> tempOrderLines = [];
  List<int> deletedOrderLines = [];
  late List<Map<String, dynamic>> editOrderLines = [];
  late List<TextEditingController> _quantityControllers;
  late List<TextEditingController> _priceControllers;
  late Future<List<Map<String, dynamic>>> orderLines;
  late Future<String> deliveryOrderStatus;
  late Future<String> invoiceStatus;
  bool isEditLineMode = false;

  @override
  void initState() {
    super.initState();
    _quantityControllers = [];
    _priceControllers = [];
    _loadQuotationDetails();
    quotationDetails =
        widget.odooService.fetchQuotationById(widget.quotationId);
    quotationDetails.then((data) {
      final saleOrderName = data['name'];
      setState(() {
        deliveryOrderStatus =
            widget.odooService.fetchDeliveryOrderStatus(saleOrderName);
        invoiceStatus = widget.odooService.fetchInvoiceStatus(saleOrderName);
      });
    });
  }

  void _loadQuotationDetails() {
    quotationDetails =
        widget.odooService.fetchQuotationById(widget.quotationId);
    quotationDetails.then((data) {
      final saleOrderName = data['name'];
      setState(() {
        deliveryOrderStatus =
            widget.odooService.fetchDeliveryOrderStatus(saleOrderName);
        invoiceStatus = widget.odooService.fetchInvoiceStatus(saleOrderName);
      });
    });
  }

  Future<void> _loadOrderLines() async {
    try {
      final data = await quotationDetails; // Ambil detail quotation
      final orderLineIds = List<int>.from(data['order_line'] ?? []);
      final fetchedOrderLines =
          await widget.odooService.fetchOrderLines(orderLineIds);

      setState(() {
        // Data awal untuk tampilan normal
        orderLines = Future.value(fetchedOrderLines);

        // Salin ke tempOrderLines untuk mode edit
        tempOrderLines = List<Map<String, dynamic>>.from(fetchedOrderLines);

        // Inisialisasi pengontrol untuk mode edit
        _quantityControllers = tempOrderLines
            .map((line) =>
                TextEditingController(text: line['product_uom_qty'].toString()))
            .toList();
        _priceControllers = tempOrderLines
            .map((line) => TextEditingController(
                text: line['price_unit'].toStringAsFixed(2)))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading order lines: $e')),
      );
    }
  }

  Future<void> _confirmQuotation() async {
    try {
      await widget.odooService.confirmQuotation(widget.quotationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation Confirmed Successfully!')),
      );
      setState(() {
        // Reload quotation details after confirmation
        quotationDetails =
            widget.odooService.fetchQuotationById(widget.quotationId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming quotation: $e')),
      );
    }
  }

  Future<void> _cancelQuotation() async {
    try {
      await widget.odooService.cancelQuotation(widget.quotationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation Cancelled Successfully!')),
      );
      setState(() {
        quotationDetails =
            widget.odooService.fetchQuotationById(widget.quotationId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling quotation: $e')),
      );
    }
  }

  Future<void> _setToQuotation() async {
    try {
      print('Resetting quotation to draft with ID: ${widget.quotationId}');
      await widget.odooService.setToQuotation(widget.quotationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation Reset to Draft Successfully!')),
      );
      setState(() {
        quotationDetails =
            widget.odooService.fetchQuotationById(widget.quotationId);
      });
    } catch (e) {
      print('Error resetting quotation to draft: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting quotation: $e')),
      );
    }
  }

  void _showEditHeaderDialog(Map<String, dynamic> headerData) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditHeaderDialog(
        initialData: headerData, // Menggunakan initialData sebagai parameter
        odooService: widget.odooService,
      ),
    );

    if (result != null) {
      // Update quotationDetails setelah edit
      setState(() {
        quotationDetails =
            widget.odooService.fetchQuotationById(widget.quotationId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation header updated successfully!')),
      );
    }
  }

  String _mapDeliveryStatus(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'cancel':
        return 'Cancelled';
      case 'waiting':
        return 'Waiting';
      case 'confirmed':
        return 'Confirmed';
      case 'assigned':
        return 'Ready';
      case 'done':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  String _mapInvoiceStatus(String status) {
    switch (status) {
      case 'not_paid':
        return 'Not Paid';
      case 'in_payment':
        return 'In Payment';
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partially Paid';
      case 'reversed':
        return 'Reversed';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'cancel':
        return Colors.red;
      case 'waiting':
        return Colors.purple;
      case 'not_paid':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'in_payment':
        return Colors.blue;
      case 'assigned':
        return Colors.teal;
      case 'done':
        return Colors.grey;
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.purple;
      case 'sent':
        return Colors.grey;
      case 'sale':
        return Colors.green;
      default:
        return const Color.fromARGB(255, 79, 80, 74);
    }
  }

  void _navigateToSaleOrderList() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home', // Arahkan kembali ke halaman utama yang memiliki bottom navigation
      (route) => false,
      arguments: {
        'odooService': widget.odooService,
        'initialIndex': 1, // Pastikan tab "saleOrderList" di-select
      },
    );
  }

  Future<void> _saveChanges() async {
    try {
      await widget.odooService
          .updateOrderLines(widget.quotationId, tempOrderLines);
      for (final id in deletedOrderLines) {
        await widget.odooService.deleteOrderLine(id);
      }

      setState(() {
        isEditLineMode = false;
        deletedOrderLines.clear(); // Kosongkan daftar baris yang dihapus
        _loadQuotationDetails(); // Reload data setelah penyimpanan
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order lines updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  Future<String?> _fetchProductImage(int productId) async {
    try {
      final product = await widget.odooService.fetchProductById(productId);
      return product['image_1920'];
    } catch (e) {
      print('Error fetching product image: $e');
      return null;
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    setState(() {
      tempOrderLines.add({
        'id': null,
        'product_id': product['product_id'],
        'name': product['name'],
        'product_uom_qty': 1,
        'price_unit': product['price_unit'],
      });

      // Tambahkan controller baru untuk produk yang ditambahkan
      _quantityControllers.add(TextEditingController(text: '1'));
      _priceControllers.add(TextEditingController(
          text: product['price_unit'].toStringAsFixed(2)));
    });
  }

  void _updateLinePrice(int index, String newPrice) {
    final parsedPrice =
        double.tryParse(newPrice) ?? tempOrderLines[index]['price_unit'];
    setState(() {
      tempOrderLines[index]['price_unit'] = parsedPrice;
      _priceControllers[index].text = parsedPrice.toStringAsFixed(2);
    });
  }

  void _updateLineQuantity(int index, String newQty) {
    final parsedQty =
        int.tryParse(newQty) ?? tempOrderLines[index]['product_uom_qty'];
    setState(() {
      tempOrderLines[index]['product_uom_qty'] = parsedQty;
      _quantityControllers[index].text = parsedQty.toString();
    });
  }

  void _removeLine(int index) {
    setState(() {
      if (tempOrderLines[index]['id'] != null) {
        // Tambahkan ID ke daftar baris yang dihapus
        deletedOrderLines.add(tempOrderLines[index]['id']);
      }
      // Hapus baris dari daftar terkait
      tempOrderLines.removeAt(index);
      _quantityControllers.removeAt(index);
      _priceControllers.removeAt(index);
    });
  }

  void _toggleEditMode() {
    setState(() {
      isEditLineMode = !isEditLineMode;
      if (isEditLineMode) {
        // Masuk ke mode edit: Salin data ke editOrderLines
        editOrderLines = List<Map<String, dynamic>>.from(tempOrderLines);
      } else {
        // Keluar mode edit: Kembalikan data dari editOrderLines
        tempOrderLines = List<Map<String, dynamic>>.from(editOrderLines);
        _quantityControllers = tempOrderLines
            .map((line) =>
                TextEditingController(text: line['product_uom_qty'].toString()))
            .toList();
        _priceControllers = tempOrderLines
            .map((line) => TextEditingController(
                text: line['price_unit'].toStringAsFixed(2)))
            .toList();
      }
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final currentQty = tempOrderLines[index]['product_uom_qty'] ?? 0;
      final newQty = currentQty + delta;

      if (newQty > 0) {
        tempOrderLines[index]['product_uom_qty'] = newQty;
        _quantityControllers[index].text = newQty.toString();
      } else {
        _removeLine(index);
      }
    });
  }

  void _showAddProductDialog() async {
    try {
      final products = await widget.odooService.fetchProducts();

      // Filter hanya produk dengan qty_available > 0
      List<Map<String, dynamic>> availableProducts = products.where((product) {
        final qtyAvailable = product['qty_available'] ?? 0;
        return qtyAvailable > 0;
      }).toList();

      TextEditingController searchController = TextEditingController();
      List<Map<String, dynamic>> displayedProducts =
          List.from(availableProducts);

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              void _filterProducts(String query) {
                setState(() {
                  displayedProducts = availableProducts
                      .where((product) => product['name']
                          .toString()
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                      .toList();
                });
              }

              return AlertDialog(
                title: Column(
                  children: [
                    Text(
                      "Select Product",
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      onChanged: _filterProducts,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(CupertinoIcons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400.0,
                  child: ListView.builder(
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      final product = displayedProducts[index];

                      Widget productImage;
                      if (product['image_1920'] != null &&
                          product['image_1920'].isNotEmpty) {
                        try {
                          final decodedImage =
                              base64Decode(product['image_1920']);
                          productImage = ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              decodedImage,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, size: 50);
                              },
                            ),
                          );
                        } catch (e) {
                          productImage =
                              const Icon(Icons.broken_image, size: 50);
                        }
                      } else {
                        productImage =
                            const Icon(Icons.image_not_supported, size: 50);
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4),
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: productImage,
                        ),
                        title: Text(
                          product['display_name'],
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                        subtitle: Text(
                          'Price: ${CurrencyHelper().currencyFormatter.format(product['list_price'])}\n'
                          'Available: ${product['qty_available']}',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.add_circled,
                              color: Colors.green),
                          onPressed: () {
                            Navigator.pop(context, {
                              'id': null,
                              'product_id': product['id'],
                              'name': product['display_name'],
                              'product_uom_qty': 1,
                              'price_unit': product['list_price'],
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      );

      if (result != null) {
        _addProduct(result);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    }
  }

  void _cancelEditMode() {
    setState(() {
      isEditLineMode = false;
      // Kembalikan data dari editOrderLines
      tempOrderLines = List<Map<String, dynamic>>.from(editOrderLines);
      _quantityControllers = tempOrderLines
          .map((line) =>
              TextEditingController(text: line['product_uom_qty'].toString()))
          .toList();
      _priceControllers = tempOrderLines
          .map((line) => TextEditingController(
              text: line['price_unit'].toStringAsFixed(2)))
          .toList();
    });
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToSaleOrderList(); // Handle hardware back button
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Quotation Details",
              style: GoogleFonts.poppins(
                  textStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              textAlign: TextAlign.left),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.arrow_left),
            onPressed: _navigateToSaleOrderList, // Custom back button behavior
          ),
          actions: [
            FutureBuilder<Map<String, dynamic>>(
              future: quotationDetails,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final status = snapshot.data!['state'] ?? '';
                final List<Widget> actions = [];
                if (status == 'draft') {
                  actions.addAll([
                    IconButton(
                      icon: const Icon(CupertinoIcons.check_mark_circled,
                          color: Colors.black, size: 15),
                      onPressed: _confirmQuotation,
                      tooltip: 'Confirm',
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.pencil_circle,
                          color: Colors.black, size: 15),
                      onPressed: () async {
                        final data = await quotationDetails;
                        _showEditHeaderDialog(data);
                      },
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle,
                          color: Colors.black, size: 15),
                      onPressed: _cancelQuotation,
                      tooltip: 'Cancel',
                    ),
                  ]);
                }
                if (status == 'cancel') {
                  actions.add(
                    IconButton(
                      icon: const Icon(
                          CupertinoIcons.arrow_counterclockwise_circle,
                          color: Colors.black),
                      onPressed: _setToQuotation,
                      tooltip: 'Set to Quotation',
                    ),
                  );
                }

                return Row(children: actions);
              },
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: quotationDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No data found.'));
            }

            final data = snapshot.data!;
            final customerName = data['partner_id']?[1] ?? 'Unknown';
            final deliveryAddress =
                data['partner_shipping_id']?[1] ?? 'Unknown';
            final dateOrder = data['date_order'] ?? 'Unknown';
            // final vat = (data['vat'] is String && data['vat']!.isNotEmpty)
            //     ? data['vat']
            //     : '';
            final orderLineIds = List<int>.from(data['order_line'] ?? []);
            final untaxedAmount = data['amount_untaxed'] ?? 0.0;
            final totalCost = data['amount_total'] ?? 0.0;
            final state = data['state'] ?? 'Unknown';
            orderLines = widget.odooService.fetchOrderLines(orderLineIds);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name and Status
                      Expanded(
                        child: Text(
                          '${data['name']}',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(state),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.toUpperCase(),
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(), // Kolom label
                      1: FixedColumnWidth(12), // Kolom titik dua
                    },
                    children: [
                      TableRow(
                        children: [
                          Text(
                            'Customer',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            ' :',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            customerName,
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text(
                            'Delivery Address',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            ' :',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            deliveryAddress,
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text(
                            'Date',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            ' :',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            dateOrder,
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      if (state != 'draft' && state != 'cancel')
                        TableRow(
                          children: [
                            Text(
                              'Delivery Order',
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              ' :',
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(fontSize: 12),
                              ),
                            ),
                            FutureBuilder<String>(
                              future: deliveryOrderStatus,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                    'Loading...',
                                    style: GoogleFonts.roboto(
                                      textStyle: TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Text(
                                    'Error: ${snapshot.error}',
                                    style: GoogleFonts.roboto(
                                      textStyle: TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                final deliveryStatus =
                                    snapshot.data ?? 'Not Found';
                                return Wrap(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 0),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(deliveryStatus),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _mapDeliveryStatus(deliveryStatus),
                                        style: GoogleFonts.lato(
                                          textStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          ],
                        ),
                      if (state != 'draft' && state != 'cancel')
                        TableRow(
                          children: [
                            Text(
                              'Invoice',
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              ' :',
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(fontSize: 12),
                              ),
                            ),
                            FutureBuilder<String>(
                              future: invoiceStatus,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                    'Loading...',
                                    style: GoogleFonts.roboto(
                                      textStyle: TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Text(
                                    'Error',
                                    style: GoogleFonts.roboto(
                                      textStyle: TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                final invoiceState =
                                    snapshot.data ?? 'Not Found';
                                return Wrap(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 0),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(invoiceState),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _mapInvoiceStatus(invoiceState),
                                        style: GoogleFonts.lato(
                                          textStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ) // Invisible placeholder
                          ],
                        ),
                    ],
                  ),
                  const Divider(height: 16, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order Lines",
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      if (isEditLineMode)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.add_circled,
                                  color: Colors.blue, size: 15),
                              onPressed: _showAddProductDialog,
                              tooltip: 'Add Product',
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.square_arrow_down,
                                  color: Colors.green, size: 15),
                              onPressed: _saveChanges,
                              tooltip: 'Save Changes',
                            ),
                            IconButton(
                              icon: const Icon(
                                  CupertinoIcons.arrow_counterclockwise_circle,
                                  color: Colors.red,
                                  size: 15),
                              onPressed: _cancelEditMode,
                              tooltip: 'Cancel Edit',
                            ),
                          ],
                        ),
                      if (!isEditLineMode && state == 'draft')
                        IconButton(
                          icon: const Icon(CupertinoIcons.pencil_circle,
                              size: 15),
                          onPressed: () async {
                            await _loadOrderLines();
                            setState(() {
                              isEditLineMode = true;
                            });
                          },
                          tooltip: 'Edit Order Lines',
                        ),
                    ],
                  ),
                  Expanded(
                    child: isEditLineMode
                        ? ListView.builder(
                            itemCount: tempOrderLines.length,
                            itemBuilder: (context, index) {
                              final line = tempOrderLines[index];
                              final name = line['name'] ?? 'No Description';

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.lato(
                                                textStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            TextField(
                                              controller:
                                                  _priceControllers[index],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Price',
                                                // border: OutlineInputBorder(),
                                                // isDense: true,
                                              ),
                                              style: GoogleFonts.poppins(
                                                textStyle:
                                                    TextStyle(fontSize: 12),
                                              ),
                                              onChanged: (value) {
                                                final parsedPrice =
                                                    double.tryParse(value) ??
                                                        tempOrderLines[index]
                                                            ['price_unit'];
                                                setState(() {
                                                  tempOrderLines[index]
                                                          ['price_unit'] =
                                                      parsedPrice;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  CupertinoIcons.minus_circle,
                                                  color: Colors.red,
                                                  size: 15),
                                              onPressed: () =>
                                                  _updateQuantity(index, -1),
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    _quantityControllers[index],
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.lato(
                                                  textStyle:
                                                      TextStyle(fontSize: 12),
                                                ),
                                                // decoration:
                                                //     const InputDecoration(
                                                //   border: OutlineInputBorder(),
                                                //   isDense: true,
                                                // ),
                                                onChanged: (value) {
                                                  final parsedQty = int
                                                          .tryParse(value) ??
                                                      tempOrderLines[index]
                                                          ['product_uom_qty'];
                                                  setState(() {
                                                    tempOrderLines[index][
                                                            'product_uom_qty'] =
                                                        parsedQty;
                                                  });
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  CupertinoIcons.plus_circle,
                                                  color: Colors.green,
                                                  size: 15),
                                              onPressed: () =>
                                                  _updateQuantity(index, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            CupertinoIcons.trash_circle,
                                            color: Colors.red,
                                            size: 15),
                                        onPressed: () {
                                          setState(() {
                                            if (tempOrderLines[index]['id'] !=
                                                null) {
                                              deletedOrderLines.add(
                                                  tempOrderLines[index]['id']);
                                            }
                                            tempOrderLines.removeAt(index);
                                            _quantityControllers
                                                .removeAt(index);
                                            _priceControllers.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : FutureBuilder<List<Map<String, dynamic>>>(
                            future: orderLines,
                            builder: (context, lineSnapshot) {
                              if (lineSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (lineSnapshot.hasError) {
                                return Center(
                                    child:
                                        Text('Error: ${lineSnapshot.error}'));
                              }
                              if (!lineSnapshot.hasData ||
                                  lineSnapshot.data!.isEmpty) {
                                return const Center(
                                    child: Text('No order lines.'));
                              }

                              final lines = lineSnapshot.data!;
                              return ListView.builder(
                                itemCount: lines.length,
                                itemBuilder: (context, index) {
                                  final line = lines[index];
                                  final qty = line['product_uom_qty'] ?? 0;
                                  final price = line['price_unit'] ?? 0.0;
                                  final subtotal = qty * price;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: ListTile(
                                      leading: FutureBuilder<String?>(
                                        future: _fetchProductImage(
                                            line['product_id'][0]),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          }
                                          if (snapshot.hasError ||
                                              snapshot.data == null ||
                                              snapshot.data!.isEmpty) {
                                            return const Icon(
                                                Icons.image_not_supported,
                                                size: 50);
                                          }
                                          return ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.memory(
                                              base64Decode(snapshot.data!),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
                                      ),
                                      title: Text(
                                        line['name'] ?? 'No Description',
                                        style: GoogleFonts.lato(
                                          textStyle: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: Table(
                                          columnWidths: const {
                                            0: IntrinsicColumnWidth(),
                                            1: FixedColumnWidth(12),
                                          },
                                          children: [
                                            TableRow(
                                              children: [
                                                Text(
                                                  'Qty',
                                                  style: GoogleFonts.lato(
                                                    textStyle:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                Text(
                                                  ' : ',
                                                  style: GoogleFonts.lato(
                                                    textStyle:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                Text(
                                                  qty.toString(),
                                                  style: GoogleFonts.lato(
                                                    textStyle:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Text(
                                                  'Price',
                                                  style: GoogleFonts.lato(
                                                    textStyle:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                Text(
                                                  ' : ',
                                                  style: GoogleFonts.lato(
                                                    textStyle:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                Text(
                                                  CurrencyHelper()
                                                      .currencyFormatter
                                                      .format(price),
                                                  style: GoogleFonts.lato(
                                                    textStyle:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Text(
                                                  'Subtotal',
                                                  style: GoogleFonts.lato(
                                                    textStyle:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                Text(
                                                  ' : ',
                                                  style: GoogleFonts.lato(
                                                    textStyle:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                Text(
                                                  CurrencyHelper()
                                                      .currencyFormatter
                                                      .format(subtotal),
                                                  style: GoogleFonts.lato(
                                                    textStyle:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Existing fields...
                        const Divider(height: 16, thickness: 1),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Untaxed Amount:',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  CurrencyHelper()
                                      .currencyFormatter
                                      .format(untaxedAmount),
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  CurrencyHelper()
                                      .currencyFormatter
                                      .format(totalCost),
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
