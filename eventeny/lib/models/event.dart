import '../core/errors/app_exceptions.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? organizer;
  final bool isActive;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    this.imageUrl,
    this.imageUrls = const [],
    this.organizer,
    this.isActive = true,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    try {
      List<String> imageUrls = [];
      
      // Check for image_urls array first (new format)
      if (json['image_urls'] != null) {
        if (json['image_urls'] is List) {
          imageUrls = (json['image_urls'] as List).map((e) => e.toString()).toList();
        } else if (json['image_urls'] is String) {
          // Handle pipe-separated string from GROUP_CONCAT
          imageUrls = json['image_urls'].split('|').where((url) => url.isNotEmpty).toList();
        }
      }
      
      // Handle comma-separated URLs in image_url field (current format)
      String? singleImageUrl = json['image_url']?.toString();
      if (singleImageUrl != null && singleImageUrl.isNotEmpty) {
        if (singleImageUrl.contains(',')) {
          // Split by comma and clean up whitespace/newlines
          imageUrls = singleImageUrl
              .split(',')
              .map((url) => url.trim().replaceAll('\n', '').replaceAll('\r', ''))
              .where((url) => url.isNotEmpty)
              .toList();
          // Set singleImageUrl to the first image for backward compatibility
          singleImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
          print('Event.fromJson: Found ${imageUrls.length} images in comma-separated string: $imageUrls');
        } else {
          // Single image URL
          if (imageUrls.isEmpty) {
            imageUrls = [singleImageUrl];
          }
        }
      }

      final event = Event(
        id: int.parse(json['id'].toString()),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        date: DateTime.parse(json['date']),
        imageUrl: singleImageUrl,
        imageUrls: imageUrls,
        organizer: json['organizer']?.toString(),
        // Handle is_active as string "1"/"0" or boolean
        isActive: json['is_active'] == null ? true : 
                 json['is_active'] is bool ? json['is_active'] : 
                 json['is_active'].toString() == '1' || json['is_active'].toString().toLowerCase() == 'true',
      );
      
      print('Event.fromJson: Created event "${event.title}" with ${event.imageUrls.length} images');
      return event;
    } catch (e) {
      throw ValidationException('Invalid event data format: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': date.toIso8601String(),
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'organizer': organizer,
      'is_active': isActive,
    };
  }

  // Get primary image (first image or fallback to single imageUrl)
  String? get primaryImageUrl {
    return imageUrls.isNotEmpty ? imageUrls.first : imageUrl;
  }

  // Check if event has multiple images
  bool get hasMultipleImages => imageUrls.length > 1;

  Event copyWith({
    int? id,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    String? imageUrl,
    List<String>? imageUrls,
    String? organizer,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      organizer: organizer ?? this.organizer,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, title: $title, location: $location, date: $date, isActive: $isActive, imageCount: ${imageUrls.length})';
  }
}
