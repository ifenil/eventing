import 'package:flutter/foundation.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

enum TicketState { initial, loading, loaded, error, purchasing }

class TicketProvider with ChangeNotifier {
  TicketState _state = TicketState.initial;
  List<Ticket> _tickets = [];
  String? _errorMessage;
  String? _currentEventId;
  bool _isPurchasing = false;
  final WebSocketService _webSocketService = WebSocketService();

  // Getters
  TicketState get state => _state;
  List<Ticket> get tickets => _tickets;
  String? get errorMessage => _errorMessage;
  bool get hasTickets => _tickets.isNotEmpty;
  bool get isPurchasing => _isPurchasing;
  bool get isWebSocketActive => _webSocketService.isConnected;



  Future<void> fetchTickets(String eventId) async {
    try {
      print('TicketProvider: Starting to fetch tickets for eventId: $eventId');
      _state = TicketState.loading;
      _errorMessage = null;
      _currentEventId = eventId;
      notifyListeners();

      print('TicketProvider: Calling API service...');
      final tickets = await ApiService.fetchTickets(eventId);
      
      print('TicketProvider: Received ${tickets.length} tickets from API');
      _tickets = tickets;
      
      for (int i = 0; i < _tickets.length; i++) {
        final ticket = _tickets[i];
        print('TicketProvider: Ticket $i - ID: ${ticket.id}, Title: ${ticket.title}, IsActive: ${ticket.isActive}, Available: ${ticket.availableQuantity}, IsSoldOut: ${ticket.isSoldOut}');
      }
      
      _state = TicketState.loaded;
      notifyListeners();
      
      // Start WebSocket connection for real-time updates
      _startWebSocketConnection();
    } catch (e) {
      print('TicketProvider: Error fetching tickets: $e');
      _errorMessage = e.toString();
      _state = TicketState.error;
      notifyListeners();
    }
  }

  void _startWebSocketConnection() {
    print('TicketProvider: Starting WebSocket connection for real-time updates');
    _webSocketService.connect(
      onTicketUpdate: _handleWebSocketTicketUpdate,
      onEventUpdate: _handleWebSocketEventUpdate,
    );
  }

  void _handleWebSocketTicketUpdate(Map<String, dynamic> ticketData) {
    try {
      print('TicketProvider: Processing WebSocket ticket update: $ticketData');
      
      final ticketId = ticketData['id'];
      final newAvailableQuantity = ticketData['available_quantity'];
      
      if (ticketId != null && newAvailableQuantity != null) {
        // Find and update the ticket in the list
        final index = _tickets.indexWhere((t) => t.id == ticketId);
        if (index != -1) {
          final oldTicket = _tickets[index];
          final updatedTicket = oldTicket.copyWith(
            availableQuantity: newAvailableQuantity,
          );
          
          _tickets[index] = updatedTicket;
          print('TicketProvider: Updated ticket $ticketId quantity to $newAvailableQuantity via WebSocket');
          
          // Force UI update
          notifyListeners();
        } else {
          print('TicketProvider: Ticket $ticketId not found in current list');
        }
      } else {
        print('TicketProvider: Invalid ticket data received: $ticketData');
      }
    } catch (e) {
      print('TicketProvider: Error handling WebSocket update: $e');
    }
  }

  void _handleWebSocketEventUpdate(Map<String, dynamic> eventData) {
    try {
      print('TicketProvider: Processing WebSocket event update: $eventData');
      
      final eventId = eventData['id'];
      
      if (eventId != null) {
        // Convert eventId to int for comparison
        final intEventId = eventId is int ? eventId : int.parse(eventId.toString());
        
        // Check if this event update affects the current event being viewed
        if (_currentEventId != null && intEventId.toString() == _currentEventId) {
          // Check if this is a complete event update or just an ID (for deletion/deactivation)
          final hasCompleteData = eventData.containsKey('title') && 
                                 eventData.containsKey('description') && 
                                 eventData.containsKey('location');
          
          if (hasCompleteData) {
            // Complete event data - check if event is still active
            final isActive = eventData['is_active'] == 1 || eventData['is_active'] == true;
            if (!isActive) {
              // Event was deactivated, show error
              _errorMessage = 'This event is no longer available.';
              _state = TicketState.error;
              notifyListeners();
              print('TicketProvider: Event $intEventId was deactivated');
            }
          } else {
            // Only ID provided - event was deleted/deactivated
            _errorMessage = 'This event is no longer available.';
            _state = TicketState.error;
            notifyListeners();
            print('TicketProvider: Event $intEventId was deleted/deactivated');
          }
        }
      } else {
        print('TicketProvider: Invalid event data received: $eventData');
      }
    } catch (e) {
      print('TicketProvider: Error handling WebSocket event update: $e');
    }
  }

  Future<void> refreshTickets() async {
    if (_currentEventId != null) {
      await fetchTickets(_currentEventId!);
    }
  }

  Future<bool> purchaseTicket(Ticket ticket, int quantity) async {
    try {
      print('TicketProvider: Starting purchase for ticket ${ticket.id}, quantity: $quantity');
      _isPurchasing = true;
      notifyListeners();

      final result = await ApiService.purchaseTicket(ticket.id, quantity);
      
      // Check if the response indicates success
      if (result['success'] == true) {
        print('TicketProvider: Purchase successful, updating ticket quantity');
        
        // Update the ticket quantity locally
        final updatedTicket = ticket.copyWith(
          availableQuantity: result['available_quantity'] ?? ticket.availableQuantity - quantity,
        );
        
        // Find and update the ticket in the list
        final index = _tickets.indexWhere((t) => t.id == ticket.id);
        if (index != -1) {
          _tickets[index] = updatedTicket;
          print('TicketProvider: Updated ticket ${ticket.id} quantity to ${updatedTicket.availableQuantity}');
        }
        
        notifyListeners();
        return true;
      } else {
        print('TicketProvider: Purchase failed - no success flag in response');
        _errorMessage = 'Purchase failed - unexpected response';
        return false;
      }
    } catch (e) {
      print('TicketProvider: Error purchasing ticket: $e');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }



  List<Ticket> getAvailableTickets() {
    final availableTickets = _tickets.where((ticket) => 
      ticket.isActive && !ticket.isSoldOut
    ).toList();
    
    print('TicketProvider: Found ${availableTickets.length} available tickets');
    for (final ticket in availableTickets) {
      print('TicketProvider: Checking ticket ${ticket.id} - IsSoldOut: ${ticket.isSoldOut}, IsActive: ${ticket.isActive}, IsAvailable: ${!ticket.isSoldOut}');
    }
    
    return availableTickets;
  }

  List<Ticket> getSoldOutTickets() {
    final soldOutTickets = _tickets.where((ticket) => 
      ticket.isActive && ticket.isSoldOut
    ).toList();
    
    print('TicketProvider: Found ${soldOutTickets.length} sold out tickets');
    return soldOutTickets;
  }

  Ticket? getTicketById(int id) {
    try {
      return _tickets.firstWhere((ticket) => ticket.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearTickets() {
    print('TicketProvider: Clearing tickets and disconnecting WebSocket');
    _tickets = [];
    _state = TicketState.initial;
    _errorMessage = null;
    _currentEventId = null;
    _isPurchasing = false;
    _webSocketService.disconnect();
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }
} 