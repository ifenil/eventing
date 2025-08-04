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

// Delete event query
$delete_query = "DELETE FROM events WHERE id = $event_id";
$result = $mysqli->query($delete_query);

if (!$result) {
  echo json_encode(['error' => 'Failed to delete event']);
  exit;
}

// Notify webhook about deletion
notifyWebhook([
  'type' => 'event_updated',
  'data' => ['id' => $event_id]
]);

echo json_encode([
  'success' => true,
  'deleted_event_id' => $event_id
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
