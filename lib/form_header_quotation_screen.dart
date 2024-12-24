import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'odoo_service.dart';

class FormHeaderQuotation extends StatefulWidget {
  final OdooService odooService;

  const FormHeaderQuotation({super.key, required this.odooService});

  @override
  _FormHeaderQuotationState createState() => _FormHeaderQuotationState();
}

class _FormHeaderQuotationState extends State<FormHeaderQuotation> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> salespersons = [];
  List<Map<String, dynamic>> paymentTerms = [];
  List<Map<String, dynamic>> warehouses = [];
  List<Map<String, dynamic>> globalAddresses = [];
  List<Map<String, dynamic>> filteredInvoiceAddresses = [];
  List<Map<String, dynamic>> filteredDeliveryAddresses = [];

  Map<String, dynamic>? selectedCustomer;
  Map<String, dynamic>? selectedSalesperson;
  Map<String, dynamic>? selectedPaymentTerm;
  Map<String, dynamic>? selectedWarehouse;
  Map<String, dynamic>? selectedInvoiceAddress;
  Map<String, dynamic>? selectedDeliveryAddress;

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
      final fetchedAddresses = await widget.odooService.fetchCustomers();

      final loggedInUser = await widget.odooService.fetchUser();

      setState(() {
        customers = fetchedCustomers;
        salespersons = fetchedSalespersons;
        paymentTerms = fetchedPaymentTerms;
        warehouses = fetchedWarehouses;
        globalAddresses = fetchedAddresses;

        // Auto-select salesperson based on logged-in user
        selectedSalesperson = salespersons.firstWhere(
          (salesperson) => salesperson['name'] == loggedInUser['name'],
          orElse: () => salespersons.isNotEmpty ? salespersons.first : <String, dynamic>{},
        );

        // Auto-select warehouse based on logged-in user's warehouse_id
        selectedWarehouse = warehouses.firstWhere(
          (warehouse) => warehouse['id'] == loggedInUser['warehouse_id'],
          orElse: () => warehouses.isNotEmpty ? warehouses.first : <String, dynamic>{},
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _loadChildAddresses(int customerId) async {
    try {
      final fetchedAddresses = await widget.odooService.fetchCustomerAddresses(customerId);

      setState(() {
        filteredInvoiceAddresses =
            fetchedAddresses.where((a) => a['type'] == 'invoice').toList();
        filteredDeliveryAddresses =
            fetchedAddresses.where((a) => a['type'] == 'delivery').toList();

        if (filteredInvoiceAddresses.isEmpty) {
          filteredInvoiceAddresses.add({
            'id': selectedCustomer?['id'],
            'name': selectedCustomer?['name'],
          });
        }

        if (filteredDeliveryAddresses.isEmpty) {
          filteredDeliveryAddresses.add({
            'id': selectedCustomer?['id'],
            'name': selectedCustomer?['name'],
          });
        }

        selectedInvoiceAddress = filteredInvoiceAddresses.first;
        selectedDeliveryAddress = filteredDeliveryAddresses.first;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading addresses: $e')),
      );
    }
  }

  Future<void> _saveHeader() async {
    if (selectedCustomer == null ||
        selectedSalesperson == null ||
        selectedPaymentTerm == null ||
        selectedWarehouse == null ||
        selectedInvoiceAddress == null ||
        selectedDeliveryAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    try {
      final headerData = {
        'partner_id': selectedCustomer!['id'],
        'partner_invoice_id': selectedInvoiceAddress!['id'],
        'partner_shipping_id': selectedDeliveryAddress!['id'],
        'user_member_id': selectedSalesperson!['id'],
        'payment_term_id': selectedPaymentTerm!['id'],
        'warehouse_id': selectedWarehouse!['id'],
        'npwp': selectedCustomer!['npwp'],
      };

      final quotationId =
          await widget.odooService.createQuotationHeader(headerData);

      Navigator.pushNamed(context, '/formDetail', arguments: {
        'quotationId': quotationId,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quotation header: $e')),
      );
    }
  }

  Widget _buildStyledDropdown({
    required String label,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic>? selectedItem,
    required ValueChanged<Map<String, dynamic>?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownSearch<Map<String, dynamic>>(
          items: items,
          selectedItem: selectedItem,
          itemAsString: (item) => item['name'] ?? '',
          onChanged: onChanged,
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: const TextFieldProps(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Form Header Quotation", 
          style: TextStyle(
            fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStyledDropdown(
                label: "Customer",
                items: customers,
                selectedItem: selectedCustomer,
                onChanged: (value) {
                  setState(() {
                    selectedCustomer = value;
                  });
                  if (value != null) {
                    _loadChildAddresses(value['id']);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                label: "Invoice Address",
                items: globalAddresses + filteredInvoiceAddresses,
                selectedItem: selectedInvoiceAddress,
                onChanged: (value) {
                  setState(() {
                    selectedInvoiceAddress = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                label: "Delivery Address",
                items: globalAddresses + filteredDeliveryAddresses,
                selectedItem: selectedDeliveryAddress,
                onChanged: (value) {
                  setState(() {
                    selectedDeliveryAddress = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                label: "Salesperson",
                items: salespersons,
                selectedItem: selectedSalesperson,
                onChanged: (value) {
                  setState(() {
                    selectedSalesperson = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                label: "Payment Term",
                items: paymentTerms,
                selectedItem: selectedPaymentTerm,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentTerm = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                label: "Warehouse",
                items: warehouses,
                selectedItem: selectedWarehouse,
                onChanged: (value) {
                  setState(() {
                    selectedWarehouse = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _saveHeader,
                  child: const Text(
                    "Save and Continue",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
