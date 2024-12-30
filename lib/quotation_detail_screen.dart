import 'package:flutter/material.dart';
import 'odoo_service.dart';
import 'form_header_quotation_screen.dart';
import 'package:intl/intl.dart';

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
  late Future<List<Map<String, dynamic>>> orderLines;
  late Future<String> deliveryOrderStatus;
  late Future<String> invoiceStatus;

  @override
  void initState() {
    super.initState();
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
      arguments: 2, // Ensure no lingering arguments are passed
    );
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
              style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateToSaleOrderList, // Custom back button behavior
          ),
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
                  if (data['state'] == 'draft') ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tombol Confirm Quotation
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirmQuotation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Confirm Quotation',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16), // Spasi antara tombol
                        // Tombol Edit Quotation
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FormHeaderQuotation(
                                    odooService: widget.odooService,
                                  ),
                                  settings: RouteSettings(arguments: data),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 15,
                            ),
                            label: const Text(
                              'Edit Quotation',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (data['state'] == 'sale' || data['state'] == 'sent') ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cancelQuotation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancel Quotation',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (data['state'] == 'cancel') ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _setToQuotation, // Memanggil aksi set to quotation
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Set to Quotation',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 24, thickness: 2),
                  const Text('Order Lines',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: orderLines,
                      builder: (context, lineSnapshot) {
                        if (lineSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (lineSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${lineSnapshot.error}'));
                        }
                        if (!lineSnapshot.hasData ||
                            lineSnapshot.data!.isEmpty) {
                          return const Center(child: Text('No order lines.'));
                        }

                        final lines = lineSnapshot.data!;
                        return ListView.builder(
                          itemCount: lines.length,
                          itemBuilder: (context, index) {
                            final line = lines[index];
                            final isNote = line['display_type'] == 'line_note';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text(line['name'] ?? 'No Description'),
                                subtitle: isNote
                                    ? const Text(
                                        "Note") // Jika baris ini adalah note
                                    : Text(
                                        'Qty: ${line['product_uom_qty'] ?? 0} ${line['product_uom']?[1] ?? ''}\n'
                                        'Unit Price: ${currencyFormatter.format(line['price_unit'] ?? 0.0)}\n'
                                        'Subtotal: ${currencyFormatter.format(line['price_subtotal'] ?? 0.0)}',
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
