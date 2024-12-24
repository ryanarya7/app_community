import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'odoo_service.dart';
import 'check_wizard.dart';

class DetailCollectionScreen extends StatefulWidget {
  final OdooService odooService;

  const DetailCollectionScreen({Key? key, required this.odooService})
      : super(key: key);

  @override
  _DetailCollectionScreenState createState() => _DetailCollectionScreenState();
}

class _DetailCollectionScreenState extends State<DetailCollectionScreen> {
  late Future<Map<String, dynamic>> collectionDetail;
  int? collectionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    collectionId = ModalRoute.of(context)?.settings.arguments as int?;
    if (collectionId != null) {
      _loadCollectionDetail(collectionId!);
    }
  }

  void _loadCollectionDetail(int id) {
    collectionDetail = widget.odooService.fetchCollectionDetail(id);
  }

  Future<List<Map<String, dynamic>>> fetchInvoices(
      List<int> accountMoveIds) async {
    if (accountMoveIds.isEmpty) return [];
    try {
      return await widget.odooService.fetchInvoiceDetails(accountMoveIds);
    } catch (e) {
      throw Exception('Failed to fetch invoice details: $e');
    }
  }

  void _openCheckWizard(Map<String, dynamic> invoice) async {
    final bool? result = await showDialog(
      context: context,
      builder: (context) {
        return CheckWizardDialog(
          odooService: widget.odooService,
          invoiceId: invoice['id'],
          invoiceName: invoice['name'],
          initialAmount: invoice['amount_residual_signed'] ?? 0,
          partnerId: invoice['partner_id']?[0]?.toString() ?? '',
        );
      },
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment updated successfully!')),
      );
    }
  }

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp.',
    decimalDigits: 2,
  );

  Color _getStateColor(String state) {
    switch (state) {
      case 'draft':
        return Colors.grey;
      case 'transfer':
        return Colors.blue;
      case 'received':
        return Colors.green;
      case 'return':
        return Colors.orange;
      case 'cancel':
        return Colors.red;
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Detail', 
          style: TextStyle(
            fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.blue[300],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: collectionDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading detail: ${snapshot.error}'),
            );
          }

          final detail = snapshot.data!;
          final accountMoveIds =
              (detail['account_move_ids'] as List<dynamic>?)?.cast<int>() ?? [];
          final collectionState = detail['state'] ?? 'Unknown';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Header Section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Text Name (Kiri)
                            Text(
                              detail['name'] ?? 'Unknown Collection',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Spacer untuk jarak dinamis antara Name dan State
                            const SizedBox(width: 16),
                            // Container State
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getStateColor(collectionState),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                collectionState,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Spacer untuk mendorong Transfer Date ke kanan
                            Spacer(),
                            // Text Transfer Date (Kanan)
                            Text(
                              '${detail['transfer_date'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        Text('Origin: ${detail['invoice_origin'] ?? 'N/A'}'),
                        Text(
                            'Destination: ${detail['invoice_destination'] ?? 'N/A'}'),
                        Text(
                            'Salesman: ${(detail['salesman'] is List && detail['salesman'].length >= 2) ? detail['salesman'][1] : 'N/A'}'),
                        const SizedBox(height: 8),
                        const Text(
                          'Notes:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          (detail['notes'] is String
                              ? detail['notes']!
                                  .replaceAll(RegExp(r'<[^>]*>'), '')
                              : 'N/A'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Invoices:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchInvoices(accountMoveIds),
                  builder: (context, invoiceSnapshot) {
                    if (invoiceSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (invoiceSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error fetching invoices: ${invoiceSnapshot.error}',
                        ),
                      );
                    }

                    final invoices = invoiceSnapshot.data ?? [];
                    if (invoices.isEmpty) {
                      return const Text(
                          'No invoices linked to this collection.');
                    }

                    // Hitung total amount, residual, dan partial payment
                    final totalAmount = invoices.fold<double>(
                      0.0,
                      (sum, invoice) => sum + (invoice['amount_total'] ?? 0.0),
                    );
                    final totalResidual = invoices.fold<double>(
                      0.0,
                      (sum, invoice) =>
                          sum + (invoice['amount_residual_signed'] ?? 0.0),
                    );
                    final totalPartialPayment = invoices.fold<double>(
                      0.0,
                      (sum, invoice) =>
                          sum + (invoice['partial_total_payment'] ?? 0.0),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: invoices.length,
                          itemBuilder: (context, index) {
                            final invoice = invoices[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Informasi Utama Invoice
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header Invoice
                                          Row(
                                            children: [
                                              Text(
                                                invoice['name'] ??
                                                    'Unknown Invoice',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: invoice[
                                                              'payment_state'] ==
                                                          'paid'
                                                      ? Colors.green
                                                      : (invoice['payment_state'] ==
                                                              'partial'
                                                          ? Colors.orange
                                                          : Colors.red),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  invoice['payment_state'] ??
                                                      'Unknown',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Customer: ${invoice['partner_id']?[1] ?? 'Unknown'}'),
                                          Text(
                                              'Amount: ${currencyFormatter.format(invoice['amount_total'] ?? 0)}'),
                                          Text(
                                              'Amount Due: ${currencyFormatter.format(invoice['amount_residual_signed'] ?? 0)}'),
                                          Text(
                                              'Receipt Via: ${invoice['receipt_via'] ?? 'N/A'}'),
                                          Row(
                                            children: [
                                              const Text('Check:'),
                                              Checkbox(
                                                value: invoice[
                                                        'check_payment_invoice'] ==
                                                    true,
                                                onChanged: (_) {},
                                              ),
                                            ],
                                          ),
                                          Text(
                                              'Amount Payment: ${currencyFormatter.format(invoice['partial_total_payment'] ?? 0)}'),
                                        ],
                                      ),
                                    ),
                                    // Tombol Check di Tengah Kanan
                                    Align(
                                      alignment: Alignment.center,
                                      child: GestureDetector(
                                        onTap: () => _openCheckWizard(invoice),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Check',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        // Tampilkan Total Summary
                        const Divider(),
                        Text(
                          'Total: ${currencyFormatter.format(totalAmount)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total Residual: ${currencyFormatter.format(totalResidual)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Amount Payment: ${currencyFormatter.format(totalPartialPayment)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
