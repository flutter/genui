// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { requestHandler } from './a2a';
import { JsonRpcTransportHandler } from '@a2a-js/sdk/server';
import cors from 'cors';
import express from 'express';
import { JSONRPCSuccessResponse } from '@a2a-js/sdk';

const port = process.env.PORT || 10002;

const app = express();
app.use(cors({
  origin: '*',
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  preflightContinue: false,
  optionsSuccessStatus: 204,
}));
app.use((req, res, next) => {
  if (req.headers['content-type'] === 'text/event-stream') {
    req.headers['content-type'] = 'application/json';
  }
  next();
});
app.use(express.json());

const transportHandler = new JsonRpcTransportHandler(requestHandler);

app.post('/', async (req, res) => {
  console.log('--- INCOMING REQUEST ---');
  console.log('Headers:', JSON.stringify(req.headers, null, 2));
  console.log('Body:', JSON.stringify(req.body, null, 2));
  console.log('----------------------');
  try {
    const rpcResponseOrStream = await transportHandler.handle(req.body);

    // Check if the method is a streaming method
    if (req.body.method === 'message/stream' || req.body.method === 'tasks/resubscribe') {
      const stream = rpcResponseOrStream as AsyncGenerator<JSONRPCSuccessResponse, void, undefined>;

      res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');
      res.flushHeaders();

      for await (const event of stream) {
        res.write(`data: ${JSON.stringify(event)}\n\n`);
      }
      res.end();
    } else {
      res.json(rpcResponseOrStream);
    }
  } catch (e) {
    const err = e as Error;
    res.status(500).json({ error: err.message });
  }
});

app.get('/.well-known/agent-card.json', async (req, res) => {
  try {
    const agentCard = await requestHandler.getAgentCard();
    res.json(agentCard);
  } catch (e) {
    const err = e as Error;
    res.status(500).json({ error: err.message });
  }
});

app.listen(port, () => {
  console.log(`🚀 A2A Server started on http://localhost:${port}`);
});
