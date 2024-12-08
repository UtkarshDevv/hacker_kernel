import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io'; // For handling picked image file
import 'dart:typed_data'; // For handling image bytes
import 'package:flutter/foundation.dart'; // For kIsWeb

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  File? _image; // To store the selected image on non-web platforms
  Uint8List? _imageBytes; // To store image bytes for web compatibility
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // For web platforms, read the image as bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        // For mobile platforms, store the image as a File
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } else {
      Fluttertoast.showToast(msg: "No image selected.");
    }
  }

  Future<void> _addProduct() async {
    final String name = _nameController.text.trim();
    final String priceStr = _priceController.text.trim();
    if (name.isEmpty || priceStr.isEmpty) {
      Fluttertoast.showToast(msg: "Both name and price are required.");
      return;
    }

    final double? price = double.tryParse(priceStr);
    if (price == null) {
      Fluttertoast.showToast(msg: "Invalid price.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String? productData = prefs.getString('products');
    List<Map<String, dynamic>> products = [];
    if (productData != null) {
      products = List<Map<String, dynamic>>.from(jsonDecode(productData));
    }

    if (products.any((product) => product['name'] == name)) {
      Fluttertoast.showToast(msg: "Product already exists.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Convert image to a base64 string
    String? imageString;
    if (kIsWeb && _imageBytes != null) {
      imageString = base64Encode(_imageBytes!);
    } else if (_image != null) {
      imageString = base64Encode(_image!.readAsBytesSync());
    }

    products.add({
      'name': name,
      'price': price,
      'image': imageString, // Store the image as a base64 string
    });

    await prefs.setString('products', jsonEncode(products));

    Fluttertoast.showToast(msg: "Product added successfully!");

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
              ),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
              ),
            ),
            const SizedBox(height: 20),

            // Button to pick an image
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Select Product Image"),
            ),
            const SizedBox(height: 20),

            // Display selected image if available
            if (kIsWeb && _imageBytes != null)
              Image.memory(
                _imageBytes!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              )
            else if (!kIsWeb && _image != null)
              Image.file(
                _image!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),

            // Add Product Button
            ElevatedButton(
              onPressed: _isLoading ? null : _addProduct,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Add Product"),
            ),
          ],
        ),
      ),
    );
  }
}
