<?php
header('Content-Type: application/json');

$mysqli = new mysqli("localhost", "root", "", "event_tickets");

if ($mysqli->connect_error) {
  echo json_encode(['error' => 'Database connection failed']);
  exit;
}

if (!isset($_POST['event_id'])) {
  echo json_encode(['error' => 'event_id is required']);
  exit;
}

$event_id = intval($_POST['event_id']);

// Allowed fields to update
$allowed_fields = ['title', 'description', 'location', 'date', 'image_url', 'organizer', 'is_active'];
$updates = [];

foreach ($allowed_fields as $field) {
  if (isset($_POST[$field])) {
    $value = $mysqli->real_escape_string($_POST[$field]);
    if ($field === 'is_active') {
      $value = intval($value);
    } else {
      $value = "'$value'";
    }
    $updates[] = "$field = $value";
  }
}

if (empty($updates)) {
  echo json_encode(['error' => 'No valid fields provided to update']);
  exit;
}

// Run update
$update_query = "UPDATE events SET " . implode(', ', $updates) . " WHERE id = $event_id";
$result = $mysqli->query($update_query);

if (!$result) {
  echo json_encode(['error' => 'Failed to update event']);
  exit;
}

// Fetch updated row
$event_result = $mysqli->query("SELECT * FROM events WHERE id = $event_id");
$updated_event = $event_result->fetch_assoc();

// 🔧 Fix is_active type
$updated_event['is_active'] = intval($updated_event['is_active']);

// 🔔 WebSocket Notification
notifyWebhook([
  'type' => 'event_updated',
  'data' => $updated_event
]);

echo json_encode([
  'success' => true,
  'event_id' => $event_id,
  'updated_event' => $updated_event
]);

// ✅ Working webhook function
function notifyWebhook($eventData) {
  $url = 'http://localhost:3000/webhook';

  $payload = json_encode($eventData); 

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
