import '../core/errors/app_exceptions.dart';

class Ticket {
  final int id;
  final int eventId;
  final String title;
  final String type;
  final double price;
  final int quantity;
  final int availableQuantity;
  final String? description;
  final bool isActive;

  Ticket({
    required this.id,
    required this.eventId,
    required this.title,
    required this.type,
    required this.price,
    required this.quantity,
    required this.availableQuantity,
    this.description,
    this.isActive = true,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    try {
      return Ticket(
        id: int.parse(json['id'].toString()),
        eventId: int.parse(json['event_id'].toString()),
        title: json['title']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        price: double.parse(json['price'].toString()),
        quantity: int.parse(json['quantity'].toString()),
        // Use quantity as availableQuantity if available_quantity doesn't exist
        availableQuantity: json['available_quantity'] != null 
            ? int.parse(json['available_quantity'].toString())
            : int.parse(json['quantity'].toString()),
        description: json['description']?.toString(),
        // Handle is_active as string "1"/"0" or boolean
        isActive: json['is_active'] == null ? true : 
                 json['is_active'] is bool ? json['is_active'] : 
                 json['is_active'].toString() == '1' || json['is_active'].toString().toLowerCase() == 'true',
      );
    } catch (e) {
      throw ValidationException('Invalid ticket data format: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'title': title,
      'type': type,
      'price': price,
      'quantity': quantity,
      'available_quantity': availableQuantity,
      'description': description,
      'is_active': isActive,
    };
  }

  bool get isSoldOut => availableQuantity <= 0;
  bool get hasLimitedAvailability => availableQuantity < quantity * 0.2;

  Ticket copyWith({
    int? id,
    int? eventId,
    String? title,
    String? type,
    double? price,
    int? quantity,
    int? availableQuantity,
    String? description,
    bool? isActive,
  }) {
    return Ticket(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      type: type ?? this.type,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticket &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Ticket(id: $id, title: $title, type: $type, price: $price, available: $availableQuantity, isActive: $isActive)';
  }
}
