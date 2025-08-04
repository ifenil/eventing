import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../models/event.dart';
import '../models/ticket.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 10);
  static final http.Client _client = http.Client();

  static Future<List<Event>> fetchEvents() async {
    try {
      const url = '${AppConstants.baseUrl}${AppConstants.eventsEndpoint}';
      print('ApiService: Fetching events from: $url');
      final response = await _client.get(Uri.parse(url)).timeout(_timeout);
      print('ApiService: Events response status: ${response.statusCode}');
      print('ApiService: Events response body: ${response.body}');
      return _handleResponse<List<Event>>(
        response,
        (data) {
          print('ApiService: Parsed events data: $data');
          return (data as List).map((e) => Event.fromJson(e)).toList();
        },
      );
    } on http.ClientException catch (e) {
      print('ApiService: Client exception: $e');
      throw NetworkException('Failed to connect to server: ${e.message}');
    } catch (e) {
      print('ApiService: Unexpected error in fetchEvents: $e');
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch events: $e');
    }
  }

  static Future<List<Ticket>> fetchTickets(String eventId) async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.ticketsEndpoint}?event_id=$eventId';
      print('ApiService: Fetching tickets from: $url');
      final response = await _client.get(Uri.parse(url)).timeout(_timeout);
      print('ApiService: Tickets response status: ${response.statusCode}');
      print('ApiService: Tickets response body: ${response.body}');
      return _handleResponse<List<Ticket>>(
        response,
        (data) {
          print('ApiService: Parsed tickets data: $data');
          return (data as List).map((e) => Ticket.fromJson(e)).toList();
        },
      );
    } on http.ClientException catch (e) {
      print('ApiService: Client exception: $e');
      throw NetworkException('Failed to connect to server: ${e.message}');
    } catch (e) {
      print('ApiService: Unexpected error in fetchTickets: $e');
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch tickets: $e');
    }
  }

  static Future<Map<String, dynamic>> purchaseTicket(int ticketId, int quantity) async {
    try {
      const url = '${AppConstants.baseUrl}/purchase_ticket.php';
      print('ApiService: Purchasing ticket $ticketId, quantity: $quantity');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'ticket_id': ticketId.toString(),
          'quantity': quantity.toString(),
        },
      ).timeout(_timeout);
      
      print('ApiService: Purchase response status: ${response.statusCode}');
      print('ApiService: Purchase response body: ${response.body}');
      
      // Handle the response directly since it's already JSON
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final jsonData = json.decode(response.body);
          print('ApiService: Parsed purchase response: $jsonData');
          
          // Check if there's an error in the response
          if (jsonData.containsKey('error')) {
            throw AppException(jsonData['error']);
          }
          
          return jsonData;
        } catch (e) {
          print('ApiService: JSON parsing error: $e');
          throw ValidationException('Invalid response format: $e');
        }
      } else {
        throw AppException('Request failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('ApiService: Client exception in purchase: $e');
      throw NetworkException('Failed to connect to server: ${e.message}');
    } catch (e) {
      print('ApiService: Unexpected error in purchaseTicket: $e');
      if (e is AppException) rethrow;
      throw AppException('Failed to purchase ticket: $e');
    }
  }



  static T _handleResponse<T>(http.Response response, T Function(dynamic) parser) {
    print('ApiService: Handling response with status: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final jsonData = json.decode(response.body);
        print('ApiService: Successfully decoded JSON: $jsonData');
        return parser(jsonData);
      } catch (e) {
        print('ApiService: JSON parsing error: $e');
        throw ValidationException('Invalid response format: $e');
      }
    } else if (response.statusCode == 404) {
      throw NetworkException('Resource not found');
    } else if (response.statusCode >= 500) {
      throw ServerException('Server error: ${response.statusCode}');
    } else {
      throw AppException('Request failed: ${response.statusCode}');
    }
  }

  static void dispose() {
    _client.close();
  }
}
