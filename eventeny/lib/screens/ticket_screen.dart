import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';
import '../models/event.dart';
import '../models/ticket.dart';
import '../providers/event_provider.dart';
import '../providers/ticket_provider.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/ticket_card.dart';
import '../widgets/image_gallery.dart';
import 'purchase_confirmation_screen.dart';

class TicketScreen extends StatefulWidget {
  final String eventId;

  const TicketScreen({super.key, required this.eventId});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  @override
  void initState() {
    super.initState();
    // Add debug logging
    print('TicketScreen initialized with eventId: ${widget.eventId}');
    
    // Fetch tickets when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Fetching tickets for eventId: ${widget.eventId}');
      context.read<TicketProvider>().fetchTickets(widget.eventId);
    });
  }

  @override
  void dispose() {
    // Clear tickets when leaving the screen
    context.read<TicketProvider>().clearTickets();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Tickets',
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

      ),
      body: Builder(
        builder: (context) {
          try {
            return Consumer2<EventProvider, TicketProvider>(
              builder: (context, eventProvider, ticketProvider, child) {
                // Add debug logging
                print('TicketScreen rebuild - State: ${ticketProvider.state}, HasTickets: ${ticketProvider.hasTickets}');
                
                // Get event details
                Event? event;
                try {
                  event = eventProvider.getEventById(int.parse(widget.eventId));
                } catch (e) {
                  print('Error parsing eventId: $e');
                  return AppErrorWidget(
                    message: 'Invalid event ID: ${widget.eventId}',
                    onRetry: () => Navigator.pop(context),
                  );
                }
                
                return _buildContent(event, ticketProvider);
              },
            );
          } catch (e) {
            print('Error in TicketScreen build: $e');
            return AppErrorWidget(
              message: 'An error occurred while loading the ticket screen: $e',
              onRetry: () {
                setState(() {});
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildContent(Event? event, TicketProvider ticketProvider) {
    switch (ticketProvider.state) {
      case TicketState.initial:
        return const AppLoadingWidget(
          message: 'Initializing...',
        );
        
      case TicketState.loading:
        return const AppLoadingWidget(
          message: 'Loading tickets...',
        );

      case TicketState.purchasing:
        return const AppLoadingWidget(
          message: 'Processing purchase...',
        );

      case TicketState.error:
        print('TicketScreen error: ${ticketProvider.errorMessage}');
        final isEventUnavailable = ticketProvider.errorMessage?.contains('no longer available') == true;
        return AppErrorWidget(
          message: ticketProvider.errorMessage ?? AppConstants.unknownError,
          onRetry: isEventUnavailable ? null : () {
            print('Retry triggered for eventId: ${widget.eventId}');
            ticketProvider.refreshTickets();
          },
        );

      case TicketState.loaded:
        print('Tickets loaded: ${ticketProvider.tickets.length} tickets');
        if (!ticketProvider.hasTickets) {
          return AppErrorWidget(
            message: AppConstants.noTicketsFound,
            icon: Icons.confirmation_number_outlined,
            onRetry: () => ticketProvider.refreshTickets(),
          );
        }

        final availableTickets = ticketProvider.getAvailableTickets();
        final soldOutTickets = ticketProvider.getSoldOutTickets();
        
        print('Available tickets: ${availableTickets.length}, Sold out: ${soldOutTickets.length}');

        return RefreshIndicator(
          onRefresh: () async {
            print('Pull to refresh triggered for eventId: ${widget.eventId}');
            await ticketProvider.fetchTickets(widget.eventId);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                // Event Image Gallery - Show all images if available
                if (event != null && event.imageUrls.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      children: [
                        ImageGallery(
                          imageUrls: event.imageUrls,
                          height: 250,
                        ),
                        if (event.hasMultipleImages) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${event.imageUrls.length} images available - swipe to view',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                
                // Event Details Header - Always show with proper top padding
                if (event != null)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      left: AppConstants.defaultPadding,
                      right: AppConstants.defaultPadding,
                      top: event.imageUrls.isNotEmpty ? 0 : AppConstants.defaultPadding,
                      bottom: 0,
                    ),
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (event.organizer != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.organizer!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.location,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatDate(event.date),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            event.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Available tickets section
                if (availableTickets.isNotEmpty) ...[
                  _buildSectionHeader('Available Tickets'),
                  ...availableTickets.map((ticket) => TicketCard(
                    ticket: ticket,
                    onPurchase: () => _showPurchaseDialog(ticket),
                  )),
                ],
                
                // Sold out tickets section
                if (soldOutTickets.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionHeader('Sold Out'),
                  ...soldOutTickets.map((ticket) => TicketCard(
                    ticket: ticket,
                  )),
                ],
                
                // Bottom padding for better scrolling
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(Ticket ticket) {
    int selectedQuantity = 1;
    final maxQuantity = ticket.availableQuantity;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Purchase ${ticket.title}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price: \$${ticket.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('Available: ${ticket.availableQuantity}'),
                  if (ticket.hasLimitedAvailability) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Limited availability',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Quantity:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedQuantity > 1 
                            ? () => setState(() => selectedQuantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                        color: selectedQuantity > 1 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[400],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$selectedQuantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: selectedQuantity < maxQuantity 
                            ? () => setState(() => selectedQuantity++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        color: selectedQuantity < maxQuantity 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\$${(selectedQuantity * ticket.price).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _navigateToPurchaseConfirmation(ticket, selectedQuantity, selectedQuantity * ticket.price);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _navigateToPurchaseConfirmation(Ticket ticket, int quantity, double totalPrice) async {
    final eventProvider = context.read<EventProvider>();
    final ticketProvider = context.read<TicketProvider>();
    
    // Get event details
    Event? event;
    try {
      event = eventProvider.getEventById(int.parse(widget.eventId));
    } catch (e) {
      print('Error getting event for purchase: $e');
      return;
    }
    
    if (event == null) {
      print('Event not found for purchase');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseConfirmationScreen(
          ticket: ticket,
          event: event!, // Use null assertion since we checked it's not null
          quantity: quantity,
          totalPrice: totalPrice,
        ),
      ),
    );

    // Handle the result from purchase confirmation screen
    if (result == true) {
      // Purchase was successful, refresh tickets
      await ticketProvider.refreshTickets();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.purchaseSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (result == false) {
      // Purchase was cancelled or failed, no action needed
      print('Purchase was cancelled or failed');
    }
  }



  void _showSuccessMessage(Ticket ticket, int quantity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          quantity > 1 
              ? 'Successfully purchased $quantity ${ticket.title} tickets!' 
              : 'Successfully purchased ${ticket.title}!'
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
