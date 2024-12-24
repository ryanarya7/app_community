import 'package:flutter/material.dart';
import 'odoo_service.dart';

class CollectionScreen extends StatefulWidget {
  final OdooService odooService;

  const CollectionScreen({Key? key, required this.odooService})
      : super(key: key);

  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late Future<List<Map<String, dynamic>>> collectionList;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  void _loadCollections() {
    collectionList = widget.odooService.fetchCollections();
  }

  void _refresh() {
    setState(() {
      _loadCollections();
    });
  }

  void _navigateToFormCollection() {
    Navigator.pushNamed(context, '/formCollection').then((_) {
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections', 
          style: TextStyle(
            fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.blue[300],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: collectionList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading collections: ${snapshot.error}'),
            );
          }

          final collections = snapshot.data ?? [];
          if (collections.isEmpty) {
            return const Center(child: Text('No collections available.'));
          }

          return ListView.builder(
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell( // Tambahkan InkWell untuk membuat Card dapat diklik
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/collectionDetail',
                      arguments: collection['id'], // Kirim ID collection ke layar detail
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              collection['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getStateColor(collection['state']),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                collection['state'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Details
                        Text(
                          'Created By: ${collection['create_uid']?[1] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created At: ${collection['create_date'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transfer Date: ${collection['transfer_date'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 14),
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _navigateToFormCollection,
      //   child: const Icon(Icons.add),
      //   backgroundColor: Colors.blue,
      // ),
    );
  }

  // Helper to get state color
  Color _getStateColor(String? state) {
    switch (state) {
      case 'draft':
        return Colors.grey;
      case 'transfer':
        return Colors.blue;
      case 'received':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      case 'return':
        return Colors.yellow;
      default:
        return Colors.black54;
    }
  }
}
