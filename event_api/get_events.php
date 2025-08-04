<?php
$mysqli = new mysqli("localhost", "root", "", "event_tickets");
$result = $mysqli->query("SELECT * FROM events");
$events = [];

while ($row = $result->fetch_assoc()) {
  $events[] = $row;
}

header('Content-Type: application/json');
echo json_encode($events);
?>
