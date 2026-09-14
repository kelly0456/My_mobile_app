import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../data/services/mpesa_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  static const routName = "/CartScreen";

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final MpesaService _mpesaService = MpesaService();
  bool _isProcessing = false;

  Future<void> _handleCheckout() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final phoneController = TextEditingController();

    // 1. Show Phone Number Dialog
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('M-Pesa Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your M-Pesa phone number to pay:'),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. 07XXXXXXXX',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.length >= 10) {
                Navigator.pop(ctx, phoneController.text);
              }
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (phone == null) return;

    // 2. Initiate STK Push
    setState(() => _isProcessing = true);

    final result = await _mpesaService.initiateStkPush(
      phone: phone,
      amount: cart.totalAmount,
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your phone for the M-Pesa prompt.')),
      );
      // Optional: Clear cart after successful initiation or wait for callback
      // cart.clearCart(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${result['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: cart.itemCount == 0 || _isProcessing
                ? null
                : () => _showClearCartDialog(context, cart),
          ),
        ],
      ),
      body: _isProcessing 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Processing payment...'),
              ],
            ))
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          'KES ${cart.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: cart.itemCount == 0 ? null : _handleCheckout,
                      icon: const Icon(Icons.payment),
                      label: const Text('CHECKOUT WITH M-PESA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: cart.itemCount == 0
                      ? const Center(child: Text('Your cart is empty!'))
                      : ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (ctx, i) {
                            final cartItem = cart.items.values.toList()[i];
                            final productId = cart.items.keys.toList()[i];
                            return Dismissible(
                              key: ValueKey(cartItem.id),
                              background: Container(
                                color: Theme.of(context).colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white, size: 40),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => cart.removeItem(productId),
                              child: Card(
                                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(backgroundImage: NetworkImage(cartItem.imageUrl)),
                                  title: Text(cartItem.productName),
                                  subtitle: Text('KES ${cartItem.price.toStringAsFixed(0)} x ${cartItem.quantity}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => cart.incrementQuantity(productId),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to remove all items from the cart?'),
        actions: [
          TextButton(child: const Text('No'), onPressed: () => Navigator.pop(ctx)),
          TextButton(child: const Text('Yes'), onPressed: () { cart.clearCart(); Navigator.pop(ctx); }),
        ],
      ),
    );
  }
}
