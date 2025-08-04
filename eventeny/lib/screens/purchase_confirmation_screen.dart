import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ticket.dart';
import '../models/event.dart';
import '../core/constants/app_constants.dart';
import '../services/api_service.dart';

class PurchaseConfirmationScreen extends StatefulWidget {
  final Ticket ticket;
  final Event event;
  final int quantity;
  final double totalPrice;

  const PurchaseConfirmationScreen({
    Key? key,
    required this.ticket,
    required this.event,
    required this.quantity,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<PurchaseConfirmationScreen> createState() => _PurchaseConfirmationScreenState();
}

class _PurchaseConfirmationScreenState extends State<PurchaseConfirmationScreen> {
  Timer? _timer;
  int _remainingSeconds = 300; // 5 minutes = 300 seconds
  bool _isProcessing = false;
  bool _isCompleted = false;
  bool _isHeld = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _purchaseTicket();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _autoCancelPurchase();
          }
        });
      }
    });
  }

  Future<void> _purchaseTicket() async {
    try {
      print('PurchaseConfirmationScreen: Purchasing ticket ${widget.ticket.id}, quantity: ${widget.quantity}');
      
      final result = await ApiService.purchaseTicket(widget.ticket.id, widget.quantity);
      
      if (result['success'] == true) {
        setState(() {
          _isHeld = true; // Mark as purchased/held
        });
        print('PurchaseConfirmationScreen: Ticket purchased successfully');
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to purchase ticket. Please try again.';
        });
        print('PurchaseConfirmationScreen: Failed to purchase ticket');
      }
    } catch (e) {
      print('PurchaseConfirmationScreen: Error purchasing ticket: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _autoCancelPurchase() {
    _timer?.cancel();
    if (mounted && !_isCompleted) {
      setState(() {
        _errorMessage = 'Purchase time expired. Please try again.';
      });
      
      // Release the purchased ticket to restore quantity
      _releaseTicket();
      
      // Auto-navigate back after showing error
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(false); // false = purchase not completed
        }
      });
    }
  }

  Future<void> _confirmPurchase() async {
    if (_isProcessing || _isCompleted) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('PurchaseConfirmationScreen: Confirming purchase for ticket ${widget.ticket.id}, quantity: ${widget.quantity}');
      
      // Purchase is already done in initState, just confirm
      
      setState(() {
        _isCompleted = true;
        _isProcessing = false;
      });
      
      _timer?.cancel();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.purchaseSuccess),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.of(context).pop(true); // true = purchase completed
      }
    } catch (e) {
      print('PurchaseConfirmationScreen: Error confirming purchase: $e');
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  Future<void> _releaseTicket() async {
    try {
      if (_isHeld) {
        print('PurchaseConfirmationScreen: Releasing ticket ${widget.ticket.id}, quantity: ${widget.quantity}');
        
        final result = await ApiService.purchaseTicket(widget.ticket.id, -widget.quantity); // Negative quantity to restore
        
        if (result['success'] == true) {
          print('PurchaseConfirmationScreen: Ticket released successfully');
        } else {
          print('PurchaseConfirmationScreen: Failed to release ticket: ${result['error']}');
        }
      }
    } catch (e) {
      print('PurchaseConfirmationScreen: Error releasing ticket: $e');
    }
  }

  void _cancelPurchase() async {
    if (_isProcessing || _isCompleted) return;
    
    _timer?.cancel();
    
    // Release the purchased ticket to restore quantity
    await _releaseTicket();
    
    Navigator.of(context).pop(false); // false = purchase not completed
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirm Purchase',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 36,
        titleSpacing: 0,
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer Card
            Card(
              elevation: AppConstants.cardElevation,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 48,
                      color: _remainingSeconds > 60 ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Time Remaining',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _remainingSeconds > 60 ? Colors.orange : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your purchase before time expires',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Purchase Details Card
            Card(
              elevation: AppConstants.cardElevation,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Event Info
                    Row(
                      children: [
                        Icon(Icons.event, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Ticket Info
                    Row(
                      children: [
                        Icon(Icons.confirmation_number, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.ticket.title} (${widget.ticket.type})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Quantity
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Quantity: ${widget.quantity}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Price per ticket
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Price per ticket: \$${widget.ticket.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // Total Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${widget.totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing || _isCompleted ? null : _cancelPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing || _isCompleted ? null : _confirmPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Confirm Purchase'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 