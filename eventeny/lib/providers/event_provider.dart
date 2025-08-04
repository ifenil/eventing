import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

enum EventState { initial, loading, loaded, error }

class EventProvider with ChangeNotifier {
  EventState _state = EventState.initial;
  List<Event> _events = [];
  String? _errorMessage;
  final WebSocketService _webSocketService = WebSocketService();
  
  // Getter for testing purposes
  WebSocketService get webSocketService => _webSocketService;

  // Getters
  EventState get state => _state;
  List<Event> get events => _events.where((event) => event.isActive).toList();
  String? get errorMessage => _errorMessage;
  bool get hasEvents => _events.isNotEmpty;
  bool get isWebSocketActive => _webSocketService.isConnected;

  Future<void> fetchEvents() async {
    try {
      print('EventProvider: Starting to fetch events');
      _state = EventState.loading;
      _errorMessage = null;
      notifyListeners();

      print('EventProvider: Calling API service...');
      final events = await ApiService.fetchEvents();
      
      print('EventProvider: Received ${events.length} events from API');
      _events = events;
      
      // Debug logging for each event
      for (int i = 0; i < _events.length; i++) {
        final event = _events[i];
        print('EventProvider: Event $i - ID: ${event.id}, Title: ${event.title}, IsActive: ${event.isActive}, Images: ${event.imageUrls.length}');
      }
      
      _state = EventState.loaded;
      notifyListeners();
      
      // Start WebSocket connection for real-time updates
      _startWebSocketConnection();
    } catch (e) {
      print('EventProvider: Error fetching events: $e');
      _errorMessage = e.toString();
      _state = EventState.error;
      notifyListeners();
    }
  }

  void _startWebSocketConnection() {
    print('EventProvider: Starting WebSocket connection for real-time updates');
    _webSocketService.connect(
      onEventUpdate: _handleWebSocketEventUpdate,
    );
    
    // Test the connection after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      print('EventProvider: Testing WebSocket connection...');
      _webSocketService.testConnection();
    });
  }

  void _handleWebSocketEventUpdate(Map<String, dynamic> eventData) {
    try {
      print('EventProvider: Processing WebSocket event update: $eventData');
      
      final eventId = eventData['id'];
      
      if (eventId != null) {
        // Convert eventId to int for comparison
        final intEventId = eventId is int ? eventId : int.parse(eventId.toString());
        
        // Check if this is a complete event update or just an ID (for deletion)
        final hasCompleteData = eventData.containsKey('title') && 
                               eventData.containsKey('description') && 
                               eventData.containsKey('location');
        
        if (hasCompleteData) {
          // Complete event data - update or add
          final updatedEvent = Event.fromJson(eventData);
          final existingIndex = _events.indexWhere((e) => e.id == intEventId);
          
          if (existingIndex != -1) {
            // Update existing event
            _events[existingIndex] = updatedEvent;
            print('EventProvider: Updated event $intEventId via WebSocket');
          } else {
            // Add new event
            _events.add(updatedEvent);
            print('EventProvider: Added new event $intEventId via WebSocket');
          }
        } else {
          // Only ID provided - likely a deletion or deactivation
          final existingIndex = _events.indexWhere((e) => e.id == intEventId);
          if (existingIndex != -1) {
            _events.removeAt(existingIndex);
            print('EventProvider: Removed event $intEventId via WebSocket');
          } else {
            print('EventProvider: Event $intEventId not found for removal');
          }
        }
        
        // Force UI update
        notifyListeners();
        print('EventProvider: UI updated with ${_events.length} events');
      } else {
        print('EventProvider: Invalid event data received: $eventData');
      }
    } catch (e) {
      print('EventProvider: Error handling WebSocket event update: $e');
    }
  }

  Future<void> refreshEvents() async {
    await fetchEvents();
  }

  Event? getEventById(int id) {
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Event> getActiveEvents() {
    final activeEvents = _events.where((event) => event.isActive).toList();
    print('EventProvider: Found ${activeEvents.length} active events');
    return activeEvents;
  }

  void clearEvents() {
    print('EventProvider: Clearing events and disconnecting WebSocket');
    _events = [];
    _state = EventState.initial;
    _errorMessage = null;
    _webSocketService.disconnect();
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }
} 