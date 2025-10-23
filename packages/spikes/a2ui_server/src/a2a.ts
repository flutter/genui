// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { v4 as uuidv4 } from 'uuid';
import {
  AgentCard,
  DataPart,
  TextPart,
} from '@a2a-js/sdk';
import {
  AgentExecutor,
  RequestContext,
  ExecutionEventBus,
  DefaultRequestHandler,
  InMemoryTaskStore,
} from '@a2a-js/sdk/server';
import { generateUiFlow } from './generate';
import { GenerateUiRequest } from './schemas';

// 1. Define the Agent Card
const a2uiAgentCard: AgentCard = {
  name: 'A2UI Genkit Server',
  description: 'An agent that generates UIs using the A2UI protocol.',
  protocolVersion: '0.3.0',
  version: '1.0.0',
  url: 'http://localhost:10002/', // This needs to be publicly accessible in production
  skills: [
    {
      id: 'a2ui-chat',
      name: 'A2UI Chat',
      description: 'Generates a UI based on a chat conversation.',
      tags: ['chat'],
      examples: [],
    },
  ],
  capabilities: {
    streaming: true,
  },
  defaultInputModes: ['text/plain'],
  defaultOutputModes: ['text/plain'],
  preferredTransport: 'JSONRPC',
};

// 2. Implement the AgentExecutor
class A2UIAgentExecutor implements AgentExecutor {
  async execute(
    requestContext: RequestContext,
    eventBus: ExecutionEventBus
  ): Promise<void> {
    const { userMessage: message, taskId, contextId } = requestContext;

    // Extract the text prompt from the incoming message
    const userPrompt = message.parts
      .filter((part): part is TextPart => part.kind === 'text')
      .map((part) => (part).text)
      .join('\n');

    if (!userPrompt) {
      eventBus.finished();
      return;
    }

    const flowRequest: GenerateUiRequest = {
      catalog: { type: 'object', properties: {} },
      conversation: [
        {
          role: 'user',
          parts: [{ type: 'text', text: userPrompt }],
        },
      ],
    };

    try {
      const { stream } = generateUiFlow.stream(flowRequest);

      for await (const chunk of stream) {
        const dataPart: DataPart = {
          kind: 'data',
          data: { a2uiMessages: [chunk] },
        };

        eventBus.publish({
          kind: 'message',
          messageId: uuidv4(),
          role: 'agent',
          parts: [dataPart],
          contextId: contextId,
          referenceTaskIds: [taskId],
        });
      }
    } catch (error) {
      console.error('Error executing Genkit flow:', error);
    } finally {
      eventBus.finished();
    }
  }

  async cancelTask(taskId: string, eventBus: ExecutionEventBus): Promise<void> {
    console.log(`Cancellation requested for task: ${taskId}`);
    eventBus.finished();
  }
}

// 3. Set up the A2A Request Handler
const agentExecutor = new A2UIAgentExecutor();
export const requestHandler = new DefaultRequestHandler(
  a2uiAgentCard,
  new InMemoryTaskStore(),
  agentExecutor
);
