import 'package:flutter/material.dart';
import 'odoo_service.dart';
import 'form_header_quotation_screen.dart';

class SaleOrderListScreen extends StatefulWidget {
  final OdooService odooService;

  const SaleOrderListScreen({super.key, required this.odooService});

  @override
  State<SaleOrderListScreen> createState() => _SaleOrderListScreenState();
}

class _SaleOrderListScreenState extends State<SaleOrderListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _quotations = [];
  List<Map<String, dynamic>> _filteredQuotations = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _limit = 20;
  int _offset = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuotations();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotations({bool isRefreshing = false}) async {
    if (_isLoading || (!_hasMore && !isRefreshing)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (isRefreshing) {
        _quotations.clear();
        _offset = 0;
        _hasMore = true;
      }

      final fetchedQuotations = await widget.odooService.fetchQuotations(
        limit: _limit,
        offset: _offset,
      );

      if (!mounted) return; // Periksa apakah widget masih terpasang

      setState(() {
        _quotations.addAll(fetchedQuotations);
        _filteredQuotations = _applySearchQuery(_searchQuery);
        _hasMore = fetchedQuotations.length == _limit;
        _offset += _limit;
      });
    } catch (e) {
      if (mounted) {
        // Periksa apakah widget masih terpasang sebelum menampilkan SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quotations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _applySearchQuery(String query) {
    return query.isEmpty
        ? _quotations
        : _quotations
            .where((quotation) =>
                (quotation['name']?.toString().toLowerCase() ?? '')
                    .contains(query.toLowerCase()) ||
                (quotation['partner_id']?[1]?.toString().toLowerCase() ?? '')
                    .contains(query.toLowerCase()) ||
                (quotation['partner_shipping_id']?[1]
                            ?.toString()
                            .toLowerCase() ??
                        '')
                    .contains(query.toLowerCase()))
            .toList();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _loadQuotations();
    }
  }

  void _filterQuotations(String query) {
    setState(() {
      _searchQuery = query;
      _filteredQuotations = _applySearchQuery(query);
    });
  }

  Widget _buildQuotationTile(Map<String, dynamic> item) {
    final name = item['name'] ?? 'No Name';
    final customer = item['partner_id']?[1] ?? '-';
    final shippingAddress = item['partner_shipping_id']?[1] ?? '-';
    final dateOrder = item['date_order']?.split(' ')[0] ?? 'Unknown'; // Format tanggal
    final totalPrice = item['amount_total'] ?? 0.0; // Total price
    final state = item['state'] ?? 'quotation'; // Default ke quotation

    Color _getStateColor(String state) {
      switch (state) {
        case 'sent':
          return Colors.grey;
        case 'cancel':
          return Colors.red;
        case 'sale':
          return Colors.green;
        case 'draft':
        default:
          return Colors.blue;
      }
    }

    String _getStateLabel(String state) {
      switch (state) {
        case 'sent':
          return 'Sent';
        case 'cancel':
          return 'Cancelled';
        case 'sale':
          return 'Sales Order';
        case 'draft':
        default:
          return 'Quotation';
      }
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 1.8, horizontal: 6.0),
                    margin: const EdgeInsets.only(left: 8.0),
                    decoration: BoxDecoration(
                      color: _getStateColor(state),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    child: Text(
                      _getStateLabel(state),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              dateOrder,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("Customer: $customer"),
            Text("Shipping Address: $shippingAddress"),
            const SizedBox(height: 5),
            Text(
              "Total: Rp ${totalPrice.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/quotationDetail',
            arguments: item['id'],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Orders', 
          style: TextStyle(
            fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.blue[300],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadQuotations(isRefreshing: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterQuotations,
              decoration: InputDecoration(
                hintText: 'Search sales orders...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredQuotations.isEmpty && !_isLoading
                ? const Center(child: Text('No quotations found.'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredQuotations.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredQuotations.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = _filteredQuotations[index];
                      return _buildQuotationTile(item);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FormHeaderQuotation(odooService: widget.odooService),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
