import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'odoo_service.dart';

class EditHeaderDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final OdooService odooService;

  const EditHeaderDialog({
    Key? key,
    required this.initialData,
    required this.odooService,
  }) : super(key: key);

  @override
  _EditHeaderDialogState createState() => _EditHeaderDialogState();
}

class _EditHeaderDialogState extends State<EditHeaderDialog> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> invoiceAddresses = [];
  List<Map<String, dynamic>> deliveryAddresses = [];
  List<Map<String, dynamic>> salespersons = [];
  List<Map<String, dynamic>> paymentTerms = [];
  List<Map<String, dynamic>> warehouses = [];

  Map<String, dynamic>? selectedCustomer;
  Map<String, dynamic>? selectedInvoiceAddress;
  Map<String, dynamic>? selectedDeliveryAddress;
  Map<String, dynamic>? selectedSalesperson;
  Map<String, dynamic>? selectedPaymentTerm;
  Map<String, dynamic>? selectedWarehouse;
  TextEditingController npwpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fetchedCustomers = await widget.odooService.fetchCustomers();
      final fetchedSalespersons = await widget.odooService.fetchSalespersons();
      final fetchedPaymentTerms = await widget.odooService.fetchPaymentTerms();
      final fetchedWarehouses = await widget.odooService.fetchWarehouses();

      setState(() {
        customers = fetchedCustomers.cast<Map<String, dynamic>>();
        salespersons = fetchedSalespersons.cast<Map<String, dynamic>>();
        paymentTerms = fetchedPaymentTerms.cast<Map<String, dynamic>>();
        warehouses = fetchedWarehouses.cast<Map<String, dynamic>>();

        selectedCustomer = customers.firstWhere(
          (c) => c['id'] == widget.initialData['partner_id']?[0],
          orElse: () => {},
        );

        selectedSalesperson = salespersons.firstWhere(
          (s) => s['id'] == widget.initialData['user_member_id']?[0],
          orElse: () => {},
        );

        selectedPaymentTerm = paymentTerms.firstWhere(
          (p) => p['id'] == widget.initialData['payment_term_id']?[0],
          orElse: () => {},
        );

        selectedWarehouse = warehouses.firstWhere(
          (w) => w['id'] == widget.initialData['warehouse_id']?[0],
          orElse: () => {},
        );

        npwpController.text = widget.initialData['npwp'] ?? '';
      });

      // Fetch specific addresses based on ID in quotation
      await _fetchInitialAddresses();
      // Load all addresses for initial customer to prepare dropdown options
      if (selectedCustomer != null) {
        await _loadAddresses(selectedCustomer!['id'], isInitialLoad: true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _fetchInitialAddresses() async {
    try {
      final customerId = widget.initialData['partner_id']?[0];
      if (customerId == null) {
        throw Exception('Customer ID is missing from initial data');
      }

      final fetchedAddresses =
          await widget.odooService.fetchCustomerAddresses(customerId);

      if (!mounted) return;

      setState(() {
        invoiceAddresses = [
          {'id': null, 'name': widget.initialData['partner_id']?[1] ?? ''},
          ...fetchedAddresses.where((a) => a['type'] == 'invoice').toList(),
        ];
        deliveryAddresses = [
          {'id': null, 'name': widget.initialData['partner_id']?[1] ?? ''},
          ...fetchedAddresses.where((a) => a['type'] == 'delivery').toList(),
        ];

        selectedInvoiceAddress = invoiceAddresses.firstWhere(
          (a) => a['id'] == widget.initialData['partner_invoice_id']?[0],
          orElse: () => invoiceAddresses.first,
        );
        selectedDeliveryAddress = deliveryAddresses.firstWhere(
          (a) => a['id'] == widget.initialData['partner_shipping_id']?[0],
          orElse: () => deliveryAddresses.first,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching initial addresses: $e')),
      );
    }
  }

  Future<void> _loadAddresses(int customerId,
      {bool isInitialLoad = false}) async {
    try {
      final fetchedAddresses =
          await widget.odooService.fetchCustomerAddresses(customerId);

      if (!mounted) return;

      setState(() {
        invoiceAddresses = [
          {'id': null, 'name': selectedCustomer?['name'] ?? ''},
          ...fetchedAddresses
              .where((a) => a['type'] == 'invoice' || a['type'] == null)
              .toList(),
        ];

        deliveryAddresses = [
          {'id': null, 'name': selectedCustomer?['name'] ?? ''},
          ...fetchedAddresses
              .where((a) => a['type'] == 'delivery' || a['type'] == null)
              .toList(),
        ];

        // Auto-fill hanya jika bukan load awal
        if (!isInitialLoad) {
          selectedInvoiceAddress = invoiceAddresses.firstWhere(
            (a) => a['type'] == 'invoice',
            orElse: () => invoiceAddresses.first,
          );

          selectedDeliveryAddress = deliveryAddresses.firstWhere(
            (a) => a['type'] == 'delivery',
            orElse: () => deliveryAddresses.first,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading addresses: $e')),
      );
    }
  }

  Future<void> _saveHeader() async {
    final headerData = {
      'partner_id': selectedCustomer?['id'],
      'partner_invoice_id':
          selectedInvoiceAddress?['id'] ?? (selectedCustomer?['id']),
      'partner_shipping_id':
          selectedDeliveryAddress?['id'] ?? (selectedCustomer?['id']),
      'user_member_id': selectedSalesperson?['id'],
      'payment_term_id': selectedPaymentTerm?['id'],
      'warehouse_id': selectedWarehouse?['id'],
      'npwp': npwpController.text,
    };

    // Periksa hanya field wajib lainnya
    if (headerData['partner_id'] == null ||
        headerData['user_member_id'] == null ||
        headerData['payment_term_id'] == null ||
        headerData['warehouse_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    try {
      await widget.odooService
          .updateQuotationHeader(widget.initialData['id'], headerData);
      Navigator.of(context).pop(headerData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating header: $e')),
      );
    }
  }

  Widget _buildDropdown({
    required String label,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic>? selectedItem,
    required ValueChanged<Map<String, dynamic>?> onChanged,
    bool isReadOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownSearch<Map<String, dynamic>>(
          items: items,
          selectedItem: selectedItem,
          itemAsString: (item) => item['name'] ?? '',
          dropdownBuilder: (context, selectedItem) {
            return Text(
              selectedItem?['name'] ?? '',
              style: const TextStyle(fontSize: 12), // Ukuran font dropdown
            );
          },
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: const TextFieldProps(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return ListTile(
                title: Text(
                  item['name'] ?? '',
                  style: const TextStyle(fontSize: 12), // Ukuran font pilihan
                ),
              );
            },
          ),
          onChanged: isReadOnly ? null : onChanged,
          enabled: !isReadOnly,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Quotation Header'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
              label: "Customer",
              items: customers,
              selectedItem: selectedCustomer,
              onChanged: (value) {
                setState(() {
                  selectedCustomer = value;
                  npwpController.text =
                      selectedCustomer?['npwp'] ?? ''; // Update NPWP jika ada
                  if (value != null) {
                    _loadAddresses(value[
                        'id']); // Auto-fill addresses (invoice dan delivery)
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: "Invoice Address",
              items: invoiceAddresses,
              selectedItem: selectedInvoiceAddress,
              onChanged: (value) =>
                  setState(() => selectedInvoiceAddress = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: "Delivery Address",
              items: deliveryAddresses,
              selectedItem: selectedDeliveryAddress,
              onChanged: (value) =>
                  setState(() => selectedDeliveryAddress = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: "Salesperson",
              items: salespersons,
              selectedItem: selectedSalesperson,
              onChanged: (_) {},
              isReadOnly: true,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: "Payment Term",
              items: paymentTerms,
              selectedItem: selectedPaymentTerm,
              onChanged: (value) => setState(() => selectedPaymentTerm = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: "Warehouse",
              items: warehouses,
              selectedItem: selectedWarehouse,
              onChanged: (value) => setState(() => selectedWarehouse = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: npwpController,
              decoration: InputDecoration(
                label: Text(
                  "NPWP",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveHeader, child: const Text('Save')),
      ],
    );
  }
}
