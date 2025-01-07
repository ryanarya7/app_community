import 'package:flutter/material.dart';
import 'odoo_service.dart';
import 'package:intl/intl.dart';
import 'edit_header_dialog.dart';

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

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID', // Format Indonesia
    symbol: 'Rp ', // Simbol Rupiah
    decimalDigits: 2,
  );

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
      '/home', // Explicitly target the Sales Order List screen
      (route) => false,
      arguments: 1, // Ensure no lingering arguments are passed
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
      // Fetch daftar produk
      final products = await widget.odooService.fetchProducts();

      // Filter hanya produk dengan qty_available > 0
      final availableProducts = products.where((product) {
        final qtyAvailable = product['qty_available'] ?? 0;
        return qtyAvailable > 0;
      }).toList();

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Select Product"),
            content: SizedBox(
              width: double.maxFinite,
              height: 400.0,
              child: ListView.builder(
                itemCount: availableProducts.length,
                itemBuilder: (context, index) {
                  final product = availableProducts[index];
                  return ListTile(
                    title: Text(product['name']),
                    subtitle: Text(
                      'Price: ${currencyFormatter.format(product['list_price'])}\n'
                      'Available: ${product['qty_available']}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () {
                        Navigator.pop(context, {
                          'id': null,
                          'product_id': product['id'],
                          'name': product['name'],
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
          title: const Text("Quotation Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          centerTitle: true,
          backgroundColor: Colors.blue[300],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: _confirmQuotation,
                      tooltip: 'Confirm',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () async {
                        final data = await quotationDetails;
                        _showEditHeaderDialog(data);
                      },
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _cancelQuotation,
                      tooltip: 'Cancel',
                    ),
                  ]);
                }
                if (status == 'cancel') {
                  actions.add(
                    IconButton(
                      icon: const Icon(Icons.undo, color: Colors.white),
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
            final npwp = data['npwp'] ?? 'N/A';
            final orderLineIds = List<int>.from(data['order_line'] ?? []);
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Customer: $customerName'),
                  Text('NPWP: $npwp'),
                  Text('Date: ${data['date_order'] ?? 'Unknown'}'),
                  const Divider(height: 24, thickness: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Order Lines",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      if (isEditLineMode)
                        Row(
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.add_box, color: Colors.blue),
                              onPressed: _showAddProductDialog,
                              tooltip: 'Add Product',
                            ),
                            IconButton(
                              icon: const Icon(Icons.save, color: Colors.green),
                              onPressed: _saveChanges,
                              tooltip: 'Save Changes',
                            ),
                            IconButton(
                              icon: const Icon(Icons.undo_rounded,
                                  color: Colors.red),
                              onPressed: _cancelEditMode,
                              tooltip: 'Cancel Edit',
                            ),
                          ],
                        ),
                      if (!isEditLineMode && state == 'draft')
                        IconButton(
                          icon: const Icon(Icons.edit),
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
                  const SizedBox(height: 8),
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
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            TextField(
                                              controller:
                                                  _priceControllers[index],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Price',
                                                border: OutlineInputBorder(),
                                                isDense: true,
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
                                                  Icons.remove_circle,
                                                  color: Colors.red),
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
                                                decoration:
                                                    const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  isDense: true,
                                                ),
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
                                              icon: const Icon(Icons.add_circle,
                                                  color: Colors.green),
                                              onPressed: () =>
                                                  _updateQuantity(index, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
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
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: ListTile(
                                      title: Text(
                                          line['name'] ?? 'No Description'),
                                      subtitle: Text(
                                        'Qty: ${line['product_uom_qty']}\n'
                                        'Price: ${currencyFormatter.format(line['price_unit'])}\n'
                                        'Subtotal: ${currencyFormatter.format(line['product_uom_qty'] * line['price_unit'])}',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  const Divider(height: 24, thickness: 2),
                  const Text(
                    'Document Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: deliveryOrderStatus,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Delivery Order: Loading...');
                      }
                      if (snapshot.hasError) {
                        return const Text(
                            'Delivery Order: Error fetching status');
                      }
                      final deliveryStatus = snapshot.data ?? 'Not Found';
                      return Row(
                        children: [
                          const Text('Delivery Order:'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(deliveryStatus),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _mapDeliveryStatus(deliveryStatus),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  FutureBuilder<String>(
                    future: invoiceStatus,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Invoice: Loading...');
                      }
                      if (snapshot.hasError) {
                        return const Text('Invoice: Error fetching status');
                      }
                      final invoiceState = snapshot.data ?? 'Not Found';
                      return Row(
                        children: [
                          const Text('Invoice:'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(invoiceState),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _mapInvoiceStatus(invoiceState),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 24, thickness: 2),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currencyFormatter.format(totalCost),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
