import 'package:flutter/material.dart';
import 'odoo_service.dart';

class CheckWizardDialog extends StatefulWidget {
  final OdooService odooService;
  final int invoiceId;
  final String invoiceName;
  final double initialAmount;
  final String
      partnerId; // Tambahkan partner ID untuk menentukan domain checkbook

  const CheckWizardDialog({
    Key? key,
    required this.odooService,
    required this.invoiceId,
    required this.invoiceName,
    required this.initialAmount,
    required this.partnerId,
  }) : super(key: key);

  @override
  _CheckWizardDialogState createState() => _CheckWizardDialogState();
}

class _CheckWizardDialogState extends State<CheckWizardDialog> {
  final _formKey = GlobalKey<FormState>();
  bool isChecked = false;
  double amountTotal = 0;
  String? receiptVia;
  int? selectedCheckbookId;
  List<Map<String, dynamic>> checkbooks = [];

  @override
  void initState() {
    super.initState();
    amountTotal = widget.initialAmount;
    _fetchCheckbooks();
  }

  Future<void> _fetchCheckbooks() async {
    try {
      final fetchedCheckbooks =
          await widget.odooService.fetchCheckbooks(widget.partnerId);
      setState(() {
        checkbooks = fetchedCheckbooks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching checkbooks: $e')),
      );
    }
  }

  Future<void> _confirmCheck() async {
    try {
      // Create the wizard record
      final wizardId = await widget.odooService.createPaymentWizard(
        invoiceId: widget.invoiceId,
        isCheck: isChecked,
        amount: amountTotal,
        receiptVia: receiptVia,
        checkbookId: selectedCheckbookId,
      );

      // Confirm the wizard
      await widget.odooService.confirmWizardAction(wizardId);

      Navigator.of(context).pop(true); // Indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.invoiceName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Check'),
                value: isChecked,
                onChanged: (value) {
                  setState(() {
                    isChecked = value ?? false;
                  });
                },
              ),
              TextFormField(
                initialValue: amountTotal.toString(),
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final double? parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
                onSaved: (value) {
                  amountTotal = double.parse(value!);
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Receipt Via'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'giro', child: Text('Giro')),
                ],
                value: receiptVia,
                onChanged: (value) {
                  setState(() {
                    receiptVia = value;
                    if (value != 'giro') {
                      selectedCheckbookId =
                          null; // Reset checkbook if receiptVia changes
                    }
                  });
                },
                validator: (value) {
                  if (value == null) return 'Select a receipt method';
                  return null;
                },
              ),
              if (receiptVia == 'giro' && checkbooks.isNotEmpty) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'No Giro'),
                  items: checkbooks.map<DropdownMenuItem<int>>((checkbook) {
                    return DropdownMenuItem<int>(
                      value: checkbook['id'] as int,
                      child: Text(checkbook['name'] ?? 'Unnamed Giro'),
                    );
                  }).toList(),
                  value: selectedCheckbookId,
                  onChanged: (value) {
                    setState(() {
                      selectedCheckbookId = value;
                    });
                  },
                  validator: (value) {
                    if (receiptVia == 'giro' && value == null) {
                      return 'Select a giro number';
                    }
                    return null;
                  },
                ),
              ] else if (receiptVia == 'giro' && checkbooks.isEmpty) ...[
                const SizedBox(height: 8),
                const Text('No Giro available'),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              _confirmCheck();
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
