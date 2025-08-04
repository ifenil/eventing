// server.js
const WebSocket = require('ws');
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const wss = new WebSocket.Server({ port: 8080 });
const app = express();
const PORT = 3000; // HTTP webhook port

app.use(cors());
app.use(bodyParser.json());

let clients = [];

wss.on('connection', (ws) => {
  console.log('📡 New WebSocket client connected');
  clients.push(ws);

  ws.on('close', () => {
    clients = clients.filter((c) => c !== ws);
    console.log('❌ WebSocket client disconnected');
  });
});

// POST /webhook
app.post('/webhook', (req, res) => {
  const event = req.body;

  const message = JSON.stringify({
    type: event.type,
    data: event.data,
  });

  console.log(`🔔 Webhook received: ${message}`);

  // Push to all WebSocket clients
  clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });

  res.json({ status: 'pushed', payload: message });
});

app.listen(PORT, () => {
  console.log(`🚀 Webhook server running at http://localhost:${PORT}/webhook`);
});
