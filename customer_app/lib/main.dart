import 'dart:math';
import 'package:flutter/material';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const CustomerApp());
}

class Product {
  final String id;
  final String name;
  final String category;
  final int price; // in Rupees
  final String icon;
  final int stockCount;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.icon,
    required this.stockCount,
  });
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  // Global cart state (Product -> quantity)
  final Map<Product, int> _cart = {};

  void _addToCart(Product product) {
    setState(() {
      if (_cart.containsKey(product)) {
        _cart[product] = _cart[product]! + 1;
      } else {
        _cart[product] = 1;
      }
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      if (_cart.containsKey(product)) {
        if (_cart[product] == 1) {
          _cart.remove(product);
        } else {
          _cart[product] = _cart[product]! - 1;
        }
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zepto Delivery Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF0055), // Vibrant Zepto Magenta/Pink
          primary: const Color(0xFFFF0055),
          secondary: const Color(0xFF1E293B),
          background: const Color(0xFFFAFAFA),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          bodyLarge: TextStyle(fontSize: 15, color: Color(0xFF475569)),
        ),
      ),
      home: MainNavigationScreen(
        cart: _cart,
        onAdd: _addToCart,
        onRemove: _removeFromCart,
        onClear: _clearCart,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final Map<Product, int> cart;
  final Function(Product) onAdd;
  final Function(Product) onRemove;
  final VoidCallback onClear;

  const MainNavigationScreen({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    required this.onClear,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      StorefrontScreen(cart: widget.cart, onAdd: widget.onAdd, onRemove: widget.onRemove),
      CartScreen(cart: widget.cart, onAdd: widget.onAdd, onRemove: widget.onRemove, onClear: widget.onClear),
      const OrderTrackingScreen(),
    ];

    // Compute badge count
    final totalItems = widget.cart.values.fold<int>(0, (sum, qty) => sum + qty);

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.flash_on),
            label: 'Shop Now',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (totalItems > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$totalItems',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Track Order',
          ),
        ],
      ),
    );
  }
}

class StorefrontScreen extends StatefulWidget {
  final Map<Product, int> cart;
  final Function(Product) onAdd;
  final Function(Product) onRemove;

  const StorefrontScreen({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  String _selectedCategory = 'Fruits';

  // Rich grocery catalog data matching Firestore schema expectations
  final List<Product> _catalog = const [
    // Fruits
    Product(id: 'prod-f1', name: 'Fresh Apples (4pcs)', category: 'Fruits', price: 120, icon: '🍎', stockCount: 25),
    Product(id: 'prod-f2', name: 'Robusta Bananas (1 Dozen)', category: 'Fruits', price: 60, icon: '🍌', stockCount: 30),
    Product(id: 'prod-f3', name: 'Alphonso Mangoes (2pcs)', category: 'Fruits', price: 180, icon: '🥭', stockCount: 15),
    // Vegetables
    Product(id: 'prod-v1', name: 'Organic Potatoes (1kg)', category: 'Vegetables', price: 30, icon: '🥔', stockCount: 50),
    Product(id: 'prod-v2', name: 'Hybrid Tomatoes (500g)', category: 'Vegetables', price: 45, icon: '🍅', stockCount: 40),
    Product(id: 'prod-v3', name: 'Spring Onions (250g)', category: 'Vegetables', price: 35, icon: '🧅', stockCount: 20),
    // Dairy
    Product(id: 'prod-d1', name: 'Full Cream Milk (1L)', category: 'Dairy', price: 66, icon: '🥛', stockCount: 60),
    Product(id: 'prod-d2', name: 'Salted Butter (100g)', category: 'Dairy', price: 58, icon: '🧈', stockCount: 45),
    Product(id: 'prod-d3', name: 'Mozzarella Cheese (200g)', category: 'Dairy', price: 140, icon: '🧀', stockCount: 18),
    // Snacks
    Product(id: 'prod-s1', name: 'Classic Salted Chips', category: 'Snacks', price: 20, icon: '🍟', stockCount: 80),
    Product(id: 'prod-s2', name: 'Chocolate Cookies (150g)', category: 'Snacks', price: 40, icon: '🍪', stockCount: 35),
    Product(id: 'prod-s3', name: 'Caramel Popcorn (80g)', category: 'Snacks', price: 60, icon: '🍿', stockCount: 25),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter product listing based on category selection
    final filteredProducts = _catalog.where((p) => p.category == _selectedCategory).toList();
    final totalBill = widget.cart.entries.fold<int>(0, (sum, entry) => sum + (entry.key.price * entry.value));

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery in 10 Mins', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Row(
              children: [
                Text('Home - Skyview Residency, GGN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80), // Extra bottom padding for cart widget space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items, brand, categories...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Categories Grid
                const Text('Shop by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCategoryItem('Fruits', '🍎', Colors.red[50]!),
                    _buildCategoryItem('Vegetables', '🥦', Colors.green[50]!),
                    _buildCategoryItem('Dairy', '🥛', Colors.blue[50]!),
                    _buildCategoryItem('Snacks', '🍪', Colors.orange[50]!),
                  ],
                ),
                const SizedBox(height: 24),

                // Products Dynamic Grid
                Text('Fresh $_selectedCategory', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final qty = widget.cart[product] ?? 0;

                      return Card(
                        color: Colors.white,
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon display
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(product.icon, style: const TextStyle(fontSize: 48)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Stock: ${product.stockCount}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.between,
                                children: [
                                  Text(
                                    '₹${product.price}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                  
                                  // Cart controls
                                  if (qty > 0)
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => widget.onRemove(product),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.remove, size: 14, color: Theme.of(context).primaryColor),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                        GestureDetector(
                                          onTap: () => widget.onAdd(product),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.add, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Theme.of(context).primaryColor,
                                        elevation: 0,
                                        side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1.5),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => widget.onAdd(product),
                                      child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Sliding Cart Preview Sheet
          if (totalBill > 0)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Card(
                color: const Color(0xFF1E293B), // Premium Slate/Charcoal 800
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.cart.values.fold<int>(0, (sum, qty) => sum + qty)} ITEMS ADDED',
                            style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                          Text(
                            '₹$totalBill',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'VIEW CART',
                            style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12, color: const Color(0xFF00F0FF)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, String emoji, Color bgColor) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : bgColor,
              borderRadius: BorderRadius.circular(18),
              border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 2) : Border.all(color: Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            ),
          )
        ],
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  final Map<Product, int> cart;
  final Function(Product) onAdd;
  final Function(Product) onRemove;
  final VoidCallback onClear;

  const CartScreen({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    required this.onClear,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isPlacingOrder = false;

  Future<void> _checkoutAndWriteFirestore() async {
    if (widget.cart.isEmpty) return;

    setState(() {
      _isPlacingOrder = true;
    });

    final random = Random();
    final orderId = 'Z-${10000 + random.nextInt(90000)}';
    final totalBill = widget.cart.entries.fold<int>(0, (sum, entry) => sum + (entry.key.price * entry.value));

    // Construct Payload document
    final orderData = {
      'order_id': orderId,
      'customer_id': 'cust_aarav',
      'store_id': 'DS-01', // Target store Cyber City
      'driver_id': null,
      'status': 'pending',
      'items': widget.cart.entries.map((entry) => {
        'product_id': entry.key.id,
        'name': entry.key.name,
        'quantity': entry.value,
        'price': entry.key.price,
      }).toList(),
      'total_amount': totalBill,
      'delivery_address': {
        'address_text': 'Apartment 4B, Skyview Residency, Gurgaon',
        'latitude': 28.4960,
        'longitude': 77.0890
      },
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String()
    };

    try {
      // Connects directly to Firestore orders collection
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderData);
      
      if (mounted) {
        widget.onClear(); // Wipe cart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('Order $orderId placed successfully! Dispatch trigger activated.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Firestore Write Error: $e');
      // Graceful local stub feedback if Firestore connection is mock/unreachable
      if (mounted) {
        widget.onClear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).primaryColor,
            content: Text('Simulation: Order $orderId created locally. (Database mock enabled)'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.cart.entries.fold<int>(0, (sum, entry) => sum + (entry.key.price * entry.value));
    final deliveryFee = subtotal > 0 ? 15 : 0;
    final totalBill = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order')),
      body: widget.cart.isEmpty
          ? const Center(
              child: Text('Your shopping cart is empty.', style: TextStyle(color: Colors.grey)),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.cart.length,
                      itemBuilder: (context, index) {
                        final product = widget.cart.keys.elementAt(index);
                        final qty = widget.cart[product]!;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(product.icon, style: const TextStyle(fontSize: 28)),
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Qty: $qty x ₹${product.price}'),
                          trailing: Text('₹${product.price * qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        const Text('Items Subtotal', style: TextStyle(fontSize: 14)),
                        Text('₹$subtotal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        const Text('10-Min Delivery Fee', style: TextStyle(fontSize: 14)),
                        Text('₹$deliveryFee', style: const TextStyle(fontSize: 14, color: Colors.green)),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        const Text('Total Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '₹$totalBill',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Checkout trigger button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isPlacingOrder ? null : _checkoutAndWriteFirestore,
                      child: _isPlacingOrder
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('PAY & PLACE ORDER (FIRESTORE)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Route Map')),
      body: Container(
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bike, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('Live Driver Tracking Active', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Coordinates mapping DLF Cyber City -> Destination', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
