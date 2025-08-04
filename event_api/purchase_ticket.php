<?php
header('Content-Type: application/json');

$mysqli = new mysqli("localhost", "root", "", "event_tickets");

// Check for DB connection error
if ($mysqli->connect_error) {
  echo json_encode(['error' => 'Database connection failed']);
  exit;
}

// Validate POST input
if (!isset($_POST['ticket_id']) || !isset($_POST['quantity'])) {
  echo json_encode(['error' => 'ticket_id and quantity are required']);
  exit;
}

$ticket_id = intval($_POST['ticket_id']);
$quantity = intval($_POST['quantity']);

// Get current available quantity
$result = $mysqli->query("SELECT available_quantity, event_id, title, type FROM tickets WHERE id = $ticket_id AND is_active = 1");

if (!$result || $result->num_rows === 0) {
  echo json_encode(['error' => 'Ticket not found or inactive']);
  exit;
}

$row = $result->fetch_assoc();
$available = intval($row['available_quantity']);

if ($available < $quantity) {
  echo json_encode(['error' => 'Not enough tickets available']);
  exit;
}

// Update quantity
$new_available = $available - $quantity;
$mysqli->query("UPDATE tickets SET available_quantity = $new_available WHERE id = $ticket_id");

// 🔔 Trigger webhook
notifyWebhook([
  'id' => $ticket_id,
  'event_id' => $row['event_id'],
  'title' => $row['title'],
  'type' => $row['type'],
  'available_quantity' => $new_available
]);

// Return updated data
echo json_encode([
  'success' => true,
  'ticket_id' => $ticket_id,
  'available_quantity' => $new_available
]);

// Webhook function
function notifyWebhook($ticketData) {
  $url = 'http://localhost:3000/webhook';

  $payload = json_encode([
    'type' => 'ticket_updated',
    'data' => $ticketData
  ]);

  $options = [
    'http' => [
      'header'  => "Content-Type: application/json",
      'method'  => 'POST',
      'content' => $payload,
    ],
  ];

  $context = stream_context_create($options);
  @file_get_contents($url, false, $context);
}
?>
