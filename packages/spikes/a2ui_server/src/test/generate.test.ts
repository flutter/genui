// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import * as genkit from "../genkit";
import { generateUiFlow } from "../generate";
import { GenerateUiRequest } from "../schemas";
import { Message } from "@genkit-ai/ai";

// A mock for the streaming response
// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function* createMockStream(chunks: any[]) {
  for (const chunk of chunks) {
    yield chunk;
  }
}

describe("generateUiFlow", () => {
  let mockGenerateStream: jest.SpyInstance;

  beforeEach(() => {
    mockGenerateStream = jest
      .spyOn(genkit.ai, "generateStream")
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      .mockImplementation((): any => ({
        stream: createMockStream([]),
        response: Promise.resolve({}),
      }));
  });

  afterEach(() => {
    mockGenerateStream.mockRestore();
  });

  it("should throw an error if no catalog is provided", async () => {
    await expect(async () => {
      const result = generateUiFlow.stream({
        catalog: null,
        conversation: [],
      } as unknown as GenerateUiRequest);
      for await (const _chunk of result.stream) {
        // This should not be reached.
      }
    }).rejects.toThrow("Expected object, received null");
  });

  it("should handle an empty conversation", async () => {
    mockGenerateStream.mockReturnValue({
      stream: createMockStream([{ text: "Hello!" }]),
      response: Promise.resolve({ text: "Hello!" }),
    });

    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [],
    };

    const stream = generateUiFlow.stream(request);
    for await (const _ of stream.stream) {
      // consume stream
    }

    expect(mockGenerateStream).toHaveBeenCalledTimes(1);
    const call = mockGenerateStream.mock.calls[0][0];
    expect(call.messages).toEqual([]);
  });

  it("should correctly map a user text message", async () => {
    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [
        {
          role: "user",
          parts: [{ type: "text", text: "Hello, world!" }],
        },
      ],
    };

    const stream = generateUiFlow.stream(request);
    for await (const _ of stream.stream) {
      /* consume */
    }

    expect(mockGenerateStream).toHaveBeenCalledTimes(1);
    const call = mockGenerateStream.mock.calls[0][0];
    expect(call.messages).toHaveLength(1);
    expect(call.messages[0]).toBeInstanceOf(Message);
    expect(call.messages[0].role).toBe("user");
    expect(call.messages[0].content).toEqual([{ text: "Hello, world!" }]);
  });

  it("should correctly map an image message with a URL", async () => {
    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [
        {
          role: "user",
          parts: [
            {
              type: "image",
              url: "https://example.com/image.png",
              mimeType: "image/png",
            },
          ],
        },
      ],
    };

    const stream = generateUiFlow.stream(request);
    for await (const _ of stream.stream) {
      /* consume */
    }

    expect(mockGenerateStream).toHaveBeenCalledTimes(1);
    const call = mockGenerateStream.mock.calls[0][0];
    expect(call.messages[0].content).toEqual([
      {
        media: {
          url: "https://example.com/image.png",
          contentType: "image/png",
        },
      },
    ]);
  });

  it("should correctly map an image message with a URL and no mimeType", async () => {
    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [
        {
          role: "user",
          parts: [
            {
              type: "image",
              url: "https://example.com/image.png",
            },
          ],
        },
      ],
    };

    const stream = generateUiFlow.stream(request);
    for await (const _ of stream.stream) {
      /* consume */
    }

    expect(mockGenerateStream).toHaveBeenCalledTimes(1);
    const call = mockGenerateStream.mock.calls[0][0];
    expect(call.messages[0].content).toEqual([
      { media: { url: "https://example.com/image.png" } },
    ]);
  });

  it("should correctly map an image message with base64 data", async () => {
    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [
        {
          role: "user",
          parts: [
            {
              type: "image",
              base64: "base64string",
              mimeType: "image/jpeg",
            },
          ],
        },
      ],
    };

    const stream = generateUiFlow.stream(request);
    for await (const _ of stream.stream) {
      /* consume */
    }

    expect(mockGenerateStream).toHaveBeenCalledTimes(1);
    const call = mockGenerateStream.mock.calls[0][0];
    expect(call.messages[0].content).toEqual([
      {
        media: {
          url: "data:image/jpeg;base64,base64string",
          contentType: "image/jpeg",
        },
      },
    ]);
  });

  it("should correctly transform an updateSurface tool request", async () => {
    const uiDefinition = {
      surfaceId: "s1",
      root: "w1",
      widgets: [{ id: "w1", widget: { type: "text", text: "Hi" } }],
    };

    mockGenerateStream.mockReturnValue({
      stream: createMockStream([
        {
          toolRequests: [
            {
              toolRequest: {
                name: "updateSurface",
                input: {
                  surfaceId: "s1",
                  definition: uiDefinition,
                },
              },
            },
          ],
        },
      ]),
      response: Promise.resolve({}),
    });

    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [],
    };

    const stream = generateUiFlow.stream(request);
    const chunks = [];
    for await (const chunk of stream.stream) {
      chunks.push(chunk);
    }

    expect(chunks).toHaveLength(2);
    expect(chunks[0]).toEqual({
      surfaceUpdate: {
        surfaceId: "s1",
        components: uiDefinition.widgets,
      },
    });
    expect(chunks[1]).toEqual({
      beginRendering: {
        surfaceId: "s1",
        root: "w1",
      },
    });
  });

  it("should correctly transform a deleteSurface tool request", async () => {
    mockGenerateStream.mockReturnValue({
      stream: createMockStream([
        {
          toolRequests: [
            {
              toolRequest: {
                name: "deleteSurface",
                input: {
                  surfaceId: "s1",
                },
              },
            },
          ],
        },
      ]),
      response: Promise.resolve({}),
    });

    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [],
    };

    const stream = generateUiFlow.stream(request);
    const chunks = [];
    for await (const chunk of stream.stream) {
      chunks.push(chunk);
    }

    expect(chunks).toHaveLength(1);
    expect(chunks[0]).toEqual({
      deleteSurface: {
        surfaceId: "s1",
      },
    });
  });

  it("should ignore text responses", async () => {
    mockGenerateStream.mockReturnValue({
      stream: createMockStream([{ text: "This should be ignored." }]),
      response: Promise.resolve({ text: "This should also be ignored." }),
    });

    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [],
    };

    const stream = generateUiFlow.stream(request);
    const chunks = [];
    for await (const chunk of stream.stream) {
      chunks.push(chunk);
    }

    expect(chunks).toHaveLength(0);
  });

  it("should correctly map a user message with a UI event part", async () => {
    const uiEvent = {
      surfaceId: "s1",
      widgetId: "w1",
      eventType: "tap",
      isAction: true,
      value: { text: "current text" },
      timestamp: new Date().toISOString(),
    };

    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [
        {
          role: "user",
          parts: [{ type: "uiEvent", event: uiEvent }],
        },
      ],
    };

    const stream = generateUiFlow.stream(request);
    for await (const _ of stream.stream) {
      /* consume */
    }

    expect(mockGenerateStream).toHaveBeenCalledTimes(1);
    const call = mockGenerateStream.mock.calls[0][0];
    expect(call.messages[0].role).toBe("user");
    expect(call.messages[0].content).toHaveLength(1);
    expect(call.messages[0].content[0].text).toContain(
      JSON.stringify([uiEvent], null, 2)
    );
  });

  it("should correctly map a message with mixed parts", async () => {
    const uiEvent = {
      surfaceId: "s1",
      widgetId: "w1",
      eventType: "tap",
      isAction: true,
      timestamp: new Date().toISOString(),
    };

    const request: GenerateUiRequest = {
      catalog: { type: "object" },
      conversation: [
        {
          role: "user",
          parts: [
            { type: "text", text: "I clicked the button." },
            { type: "uiEvent", event: uiEvent },
          ],
        },
      ],
    };

    const stream = generateUiFlow.stream(request);
    for await (const _ of stream.stream) {
      /* consume */
    }

    expect(mockGenerateStream).toHaveBeenCalledTimes(1);
    const call = mockGenerateStream.mock.calls[0][0];
    expect(call.messages[0].content).toHaveLength(2);
    expect(call.messages[0].content[0]).toEqual({
      text: "I clicked the button.",
    });
    expect(call.messages[0].content[1].text).toContain(
      JSON.stringify([uiEvent], null, 2)
    );
  });

  describe("schema validation", () => {
    it("should throw a validation error for image with base64 but no mimeType", async () => {
      const request = {
        catalog: { type: "object" },
        conversation: [
          {
            role: "user",
            parts: [{ type: "image", base64: "abc" }],
          },
        ],
      } as unknown as GenerateUiRequest;

      await expect(async () => {
        const result = generateUiFlow.stream(request);
        for await (const _ of result.stream) {
          /* consume */
        }
      }).rejects.toThrow(
        "If base64 is provided, mimeType must also be provided."
      );
    });

    it("should throw a validation error for image with both url and base64", async () => {
      const request = {
        catalog: { type: "object" },
        conversation: [
          {
            role: "user",
            parts: [
              {
                type: "image",
                url: "http://a.com/b.png",
                base64: "abc",
                mimeType: "image/png",
              },
            ],
          },
        ],
      } as unknown as GenerateUiRequest;

      await expect(async () => {
        const result = generateUiFlow.stream(request);
        for await (const _ of result.stream) {
          /* consume */
        }
      }).rejects.toThrow(
        "If url is provided, base64 and mimeType should not be."
      );
    });

    it("should throw a validation error for image with neither url nor base64", async () => {
      const request = {
        catalog: { type: "object" },
        conversation: [
          {
            role: "user",
            parts: [{ type: "image", mimeType: "image/png" }],
          },
        ],
      } as unknown as GenerateUiRequest;

      await expect(async () => {
        const result = generateUiFlow.stream(request);
        for await (const _ of result.stream) {
          /* consume */
        }
      }).rejects.toThrow("Either url or base64 must be provided.");
    });
  });
});
