<?php
$mysqli = new mysqli("localhost", "root", "", "event_tickets");
$event_id = $_GET['event_id'];
$result = $mysqli->query("SELECT * FROM tickets WHERE event_id = $event_id");
$tickets = [];

while ($row = $result->fetch_assoc()) {
  $tickets[] = $row;
}

header('Content-Type: application/json');
echo json_encode($tickets);
?>
