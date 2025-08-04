<?php
header('Content-Type: application/json');

$mysqli = new mysqli("localhost", "root", "", "event_tickets");

if ($mysqli->connect_error) {
  echo json_encode(['error' => 'Database connection failed']);
  exit;
}

// Validate required fields for creating an event
$required_fields = ['title', 'description', 'location', 'date', 'image_url', 'organizer', 'is_active'];
foreach ($required_fields as $field) {
  if (!isset($_POST[$field])) {
    echo json_encode(['error' => "$field is required"]);
    exit;
  }
}

// Escape and prepare fields
$title = $mysqli->real_escape_string($_POST['title']);
$description = $mysqli->real_escape_string($_POST['description']);
$location = $mysqli->real_escape_string($_POST['location']);
$date = $mysqli->real_escape_string($_POST['date']);
$image_url = $mysqli->real_escape_string($_POST['image_url']);
$organizer = $mysqli->real_escape_string($_POST['organizer']);
$is_active = intval($_POST['is_active']);

// Insert query
$insert_query = "INSERT INTO events (title, description, location, date, image_url, organizer, is_active) 
                 VALUES ('$title', '$description', '$location', '$date', '$image_url', '$organizer', $is_active)";

$result = $mysqli->query($insert_query);

if (!$result) {
  echo json_encode(['error' => 'Failed to add event']);
  exit;
}

$event_id = $mysqli->insert_id;

// Fetch inserted event
$event_result = $mysqli->query("SELECT * FROM events WHERE id = $event_id");
$new_event = $event_result->fetch_assoc();
$new_event['is_active'] = intval($new_event['is_active']);

// Notify webhook
notifyWebhook([
  'type' => 'event_updated',
  'data' => $new_event
]);

echo json_encode([
  'success' => true,
  'event_id' => $event_id,
  'new_event' => $new_event
]);

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
