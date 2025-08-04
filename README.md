# 🎫 Eventing - Real-Time Event Ticket Management App

A modern Flutter application for managing events and ticket purchases with real-time updates via WebSocket integration.

## ✨ Features

### 🎯 Core Functionality
- **Event Discovery**: Browse and view multiple events with detailed information
- **Ticket Management**: Purchase multiple types of tickets for each event
- **Real-Time Updates**: Live ticket quantity updates via WebSocket
- **Purchase Flow**: 5-minute purchase confirmation window with auto-cancel
- **Active Event Filtering**: Only displays active events (`is_active = 1`)

### 🎨 User Interface
- **Modern Material Design 3**: Clean, intuitive interface
- **Responsive Design**: Optimized for various screen sizes
- **Image Gallery**: Swipeable image galleries for events with multiple images
- **Pull-to-Refresh**: Manual refresh capability on all screens
- **Loading States**: Smooth loading indicators and error handling
- **Real-Time Status**: WebSocket connection status indicators

### 🔄 Real-Time Features
- **WebSocket Integration**: Persistent connection for live updates
- **Event Updates**: Real-time event creation, updates, and deletion
- **Ticket Updates**: Live ticket quantity changes after purchases
- **Auto-Reconnection**: Automatic WebSocket reconnection on connection loss
- **Event Deactivation**: Automatic removal of deactivated events

### 🛡️ Error Handling & Validation
- **Robust Error Handling**: Comprehensive error states and user feedback
- **Network Resilience**: Graceful handling of network issues
- **Data Validation**: Input validation and data integrity checks
- **Fallback Mechanisms**: Graceful degradation when services are unavailable

## 🏗️ Architecture

### Clean Architecture Principles
```
lib/
├── core/                    # Core application logic
│   ├── constants/          # App-wide constants
│   ├── errors/             # Custom exception classes
│   └── utils/              # Utility functions
├── models/                 # Data models
├── providers/              # State management (Provider pattern)
├── screens/                # UI screens
├── services/               # API and WebSocket services
└── widgets/                # Reusable UI components
```

### State Management
- **Provider Pattern**: Using `ChangeNotifierProvider` for state management
- **EventProvider**: Manages event data and WebSocket event updates
- **TicketProvider**: Handles ticket data, purchases, and WebSocket ticket updates

### Data Flow
1. **API Service**: Handles HTTP requests to backend
2. **WebSocket Service**: Manages real-time communication
3. **Providers**: Manage state and business logic
4. **Screens**: Display UI and handle user interactions
5. **Widgets**: Reusable UI components

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- PHP backend with MySQL database

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ifenil/eventing.git
   cd eventeny
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure backend URL**
   Update `lib/core/constants/app_constants.dart`:
   ```dart
   static const String baseUrl = 'http://10.0.0.125/event_api';
   static const String webSocketUrl = 'ws://10.0.0.125:8080';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Backend Setup

#### Required PHP Endpoints

**1. Get Events** (`get_events.php`)
```php
GET /get_events.php
Response: JSON array of events
```

**2. Get Tickets** (`get_tickets.php`)
```php
GET /get_tickets.php?event_id={id}
Response: JSON array of tickets for the event
```

**3. Purchase Ticket** (`purchase_ticket.php`)
```php
POST /purchase_ticket.php
Body: {
  "ticket_id": "1",
  "quantity": "2"
}
Response: {
  "success": true,
  "ticket_id": 1,
  "available_quantity": 73
}
```

#### WebSocket Server
- **URL**: `ws://10.0.0.125:8080`
- **Message Format**: JSON with `type` and `data` fields

**Event Updates**:
```json
{
  "type": "event_updated",
  "data": {
    "id": 1,
    "title": "Event Title",
    "description": "Event description",
    "location": "Event location",
    "date": "2025-01-01 10:00:00",
    "image_url": "image_urls",
    "organizer": "Organizer name",
    "is_active": 1
  }
}
```

**Ticket Updates**:
```json
{
  "type": "ticket_updated",
  "data": {
    "id": 1,
    "event_id": 1,
    "title": "Ticket Title",
    "type": "VIP",
    "available_quantity": 45
  }
}
```

## 📱 App Flow

### 1. Home Screen
- Displays list of active events
- Real-time event updates via WebSocket
- Pull-to-refresh functionality
- Event filtering (only active events)

### 2. Event Details & Tickets
- Event information with image gallery
- Available and sold-out tickets
- Real-time ticket quantity updates
- Purchase dialog with quantity selection

### 3. Purchase Confirmation
- 5-minute countdown timer
- Purchase details display
- Immediate ticket purchase on screen open
- Auto-release if not confirmed within time limit

### 4. Real-Time Updates
- WebSocket connection for live updates
- Automatic reconnection on connection loss
- Event creation, updates, and deletion
- Ticket quantity changes after purchases

## 🔧 Configuration

### App Constants (`lib/core/constants/app_constants.dart`)
```dart
class AppConstants {
  // API Endpoints
  static const String baseUrl = 'http://your-backend-url/event_api';
  static const String eventsEndpoint = '/get_events.php';
  static const String ticketsEndpoint = '/get_tickets.php';
  static const String purchaseEndpoint = '/purchase_ticket.php';

  // WebSocket Configuration
  static const String webSocketUrl = 'ws://your-backend-url:8080';
  static const int webSocketReconnectDelay = 3000;

  // App Configuration
  static const String appName = 'Eventing';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double cardElevation = 2.0;
}
```

### Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  http: ^1.1.0
  web_socket_channel: ^2.4.0
  intl: ^0.18.1
  flutter_launcher_icons: ^0.13.1
```

## 🎨 UI Components

### Custom Widgets
- **EventCard**: Displays event information with images
- **TicketCard**: Shows ticket details and purchase button
- **ImageGallery**: Swipeable image gallery for multiple images
- **AppLoadingWidget**: Consistent loading indicator
- **AppErrorWidget**: Error display with retry functionality

### Design System
- **Material Design 3**: Modern design language
- **Consistent Spacing**: Standardized padding and margins
- **Color Scheme**: Primary color theming
- **Typography**: Consistent text styles
- **Responsive Layout**: Adapts to different screen sizes

## 🔄 Real-Time Features

### WebSocket Integration
- **Persistent Connection**: Maintains connection for live updates
- **Auto-Reconnection**: Automatically reconnects on connection loss
- **Event Handling**: Processes different types of real-time messages
- **Error Recovery**: Graceful handling of connection issues

### Purchase Flow
1. **Quantity Selection**: User selects ticket quantity
2. **Immediate Purchase**: API call made when confirmation screen opens
3. **5-Minute Timer**: Countdown for user confirmation
4. **Auto-Release**: If not confirmed, quantity is restored
5. **Success Handling**: Updates UI and shows success message

**Built with ❤️**
