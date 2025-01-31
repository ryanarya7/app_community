import 'package:flutter/material.dart';
import 'odoo_service.dart';
import 'form_header_quotation_screen.dart';
import 'currency_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

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
    final dateOrder =
        item['date_order']?.split(' ')[0] ?? 'Unknown'; // Format tanggal
    // final totalPrice = item['amount_total'] ?? 0.0; // Total price
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
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              dateOrder,
              style: GoogleFonts.lato(
                textStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(), // Kolom label (Customer, Shipping Address)
                1: FixedColumnWidth(12), // Kolom titik dua ":"
              },
              children: [
                TableRow(
                  children: [
                    Text(
                      "Customer",
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      " :",
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      customer,
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 2), // Jarak antar baris
                    SizedBox(),
                    SizedBox(),
                  ],
                ),
                TableRow(
                  children: [
                    Text(
                      "Delivery addr",
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      " :",
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      shippingAddress,
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyHelper()
                  .currencyFormatter
                  .format(item['amount_total'] ?? 0),
              style: GoogleFonts.lato(
                textStyle: TextStyle(color: Colors.green, fontSize: 13),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/quotationDetail',
            arguments: {
              'odooService': widget.odooService,
              'quotationId': item['id'],
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // Atur tinggi AppBar
        child: AppBar(
          automaticallyImplyLeading: false, // Menghapus tombol back
          backgroundColor: Colors.white,
          elevation: 1,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterQuotations,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                hintText: 'Search sales',
                hintStyle: GoogleFonts.poppins(
                  textStyle: TextStyle(color: Colors.grey),
                ),
                prefixIcon:
                    const Icon(CupertinoIcons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white, // Warna latar search bar
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.poppins(
                textStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.refresh, color: Colors.grey),
              onPressed: () => _loadQuotations(isRefreshing: true),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
        shape: const CircleBorder(), // Membuat tombol bulat sempurna
        backgroundColor: Colors.grey[300], // Ganti warna sesuai kebutuhan
        child: const Icon(
          CupertinoIcons.add,
          size: 30, // Sesuaikan ukuran ikon jika diperlukan
          color: Colors.blue, // Sesuaikan warna ikon jika diperlukan
        ),
      ),
    );
  }
}
