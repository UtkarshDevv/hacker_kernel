import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_product_page.dart';
import 'dart:convert';
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productData = prefs.getString('products');
    if (productData != null) {
      setState(() {
        _products = List<Map<String, dynamic>>.from(jsonDecode(productData));
        _filteredProducts = _products;
      });
    }
  }

  Future<void> _deleteProduct(String name) async {
    setState(() {
      _products.removeWhere((product) => product['name'] == name);
      _filteredProducts = _products;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', jsonEncode(_products));
    Fluttertoast.showToast(msg: "Product deleted successfully!");
  }

  void _searchProduct(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
    } else {
      setState(() {
        _filteredProducts = _products
            .where((product) =>
                product['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hi-Fi Shop & Service'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search products...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _searchProduct,
                  ),
                ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text('No Product Found'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 items per row
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 3 / 4,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];

                            // Decode base64 image
                            Uint8List? imageBytes;
                            if (product['image'] != null) {
                              imageBytes =
                                  base64Decode(product['image'] as String);
                            }

                            return Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: imageBytes != null
                                        ? Image.memory(
                                            imageBytes,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      product['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\₹${product['price']}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteProduct(product['name']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductPage(),
            ),
          );

          if (result == true) {
            _loadProducts();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
