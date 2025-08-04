import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/app_constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  Function(Map<String, dynamic>)? _onTicketUpdate;
  Function(Map<String, dynamic>)? _onEventUpdate;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  void connect({
    Function(Map<String, dynamic>)? onTicketUpdate,
    Function(Map<String, dynamic>)? onEventUpdate,
  }) {
    print('WebSocketService: Connect called - Current state: connected=$_isConnected, connecting=$_isConnecting');
    
    // Always update callbacks
    _onTicketUpdate = onTicketUpdate;
    _onEventUpdate = onEventUpdate;
    
    if (_isConnecting) {
      print('WebSocketService: Already connecting, skipping');
      return;
    }
    
    if (_isConnected && _channel != null) {
      print('WebSocketService: Already connected, updating callbacks only');
      return;
    }

    print('WebSocketService: Setting up WebSocket callbacks and connecting');
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      print('WebSocketService: Connecting to ${AppConstants.webSocketUrl}');
      _isConnecting = true;
      _isConnected = false;

      _channel = WebSocketChannel.connect(
        Uri.parse(AppConstants.webSocketUrl),
      );

      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) {
          print('WebSocketService: Stream error: $error');
          _handleError(error);
        },
        onDone: () {
          print('WebSocketService: Stream done');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      _isConnected = true;
      _isConnecting = false;
      print('WebSocketService: Connected successfully to ${AppConstants.webSocketUrl}');
    } catch (e) {
      print('WebSocketService: Connection failed: $e');
      _isConnecting = false;
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      print('WebSocketService: Received message: $data');
      
      final parsed = jsonDecode(data);
      final type = parsed['type'];
      final messageData = parsed['data'];

      switch (type) {
        case 'ticket_updated':
          print('WebSocketService: Processing ticket update: $messageData');
          _onTicketUpdate?.call(messageData);
          break;
          
        case 'new_event':
          print('WebSocketService: Processing new event: $messageData');
          _onEventUpdate?.call(messageData);
          break;
          
        case 'event_updated':
          print('WebSocketService: Processing event update: $messageData');
          _onEventUpdate?.call(messageData);
          break;
          
        default:
          print('WebSocketService: Unknown message type: $type');
      }
    } catch (e) {
      print('WebSocketService: Error parsing message: $e');
    }
  }

  void _handleError(dynamic error) {
    print('WebSocketService: WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    print('WebSocketService: WebSocket disconnected');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
    }

    print('WebSocketService: Scheduling reconnect in ${AppConstants.webSocketReconnectDelay}ms');
    _reconnectTimer = Timer(
      const Duration(milliseconds: AppConstants.webSocketReconnectDelay),
      () {
        if (!_isConnected && !_isConnecting) {
          print('WebSocketService: Attempting to reconnect...');
          _connectWebSocket();
        }
      },
    );
  }

  void disconnect() {
    print('WebSocketService: Disconnecting...');
    
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }

    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _isConnecting = false;
    _onTicketUpdate = null;
    _onEventUpdate = null;
    
    print('WebSocketService: Disconnected');
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final jsonMessage = jsonEncode(message);
        print('WebSocketService: Sending message: $jsonMessage');
        _channel!.sink.add(jsonMessage);
      } catch (e) {
        print('WebSocketService: Error sending message: $e');
      }
    } else {
      print('WebSocketService: Cannot send message - not connected');
    }
  }

  // Method to manually trigger an update (for testing)
  void triggerTicketUpdate(Map<String, dynamic> ticketData) {
    if (_onTicketUpdate != null) {
      print('WebSocketService: Manually triggering ticket update: $ticketData');
      _onTicketUpdate!.call(ticketData);
    } else {
      print('WebSocketService: No ticket update callback registered');
    }
  }

  void triggerEventUpdate(Map<String, dynamic> eventData) {
    if (_onEventUpdate != null) {
      print('WebSocketService: Manually triggering event update: $eventData');
      _onEventUpdate!.call(eventData);
    } else {
      print('WebSocketService: No event update callback registered');
    }
  }

  // Test method to simulate WebSocket messages
  void testWebSocketMessage(String messageType, Map<String, dynamic> data) {
    print('WebSocketService: Testing $messageType message: $data');
    final testMessage = {
      'type': messageType,
      'data': data,
    };
    _handleMessage(jsonEncode(testMessage));
  }

  // Test WebSocket connection
  void testConnection() {
    print('WebSocketService: Testing connection...');
    print('WebSocketService: URL: ${AppConstants.webSocketUrl}');
    print('WebSocketService: Connected: $_isConnected');
    print('WebSocketService: Connecting: $_isConnecting');
    print('WebSocketService: Channel: ${_channel != null ? 'exists' : 'null'}');
    
    if (_isConnected && _channel != null) {
      print('WebSocketService: Connection appears to be active');
      // Send a test message
      sendMessage({
        'type': 'ping',
        'data': {'message': 'test from Flutter app'}
      });
    } else {
      print('WebSocketService: Connection is not active, attempting to connect...');
      _connectWebSocket();
    }
  }
} 