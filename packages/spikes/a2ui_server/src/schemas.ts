// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { z } from "./genkit";

// A schema for a JSON schema.
export const jsonSchema: z.ZodType = z.record(z.any());

// Schemas for conversation parts, based on the client's `MessagePart`
const textPartSchema = z.object({
  type: z.literal("text"),
  text: z.string(),
});

const uiEventPartSchema = z.object({
  type: z.literal("uiEvent"),
  event: z.object({
    surfaceId: z.string(),
    widgetId: z.string(),
    eventType: z.string(),
    isAction: z.boolean(),
    value: z.any().optional(),
    timestamp: z.string(),
  }),
});

const imagePartSchema = z
  .object({
    type: z.literal("image"),
    base64: z.string().optional(),
    mimeType: z.string().optional(),
    url: z.string().optional(),
  })
  .superRefine((data, ctx) => {
    const hasUrl = !!data.url;
    const hasBase64 = !!data.base64;
    const hasMimeType = !!data.mimeType;

    if (hasUrl && hasBase64) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "If url is provided, base64 should not be.",
      });
    }
    if (!hasUrl && !hasBase64) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Either url or base64 must be provided.",
      });
    }
    if (hasBase64 && !hasMimeType) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "If base64 is provided, mimeType must also be provided.",
      });
    }
  });

const uiPartSchema = z.object({
  type: z.literal("ui"),
  definition: z.object({
    surfaceId: z.string(),
    root: z.string(),
    components: z.array(z.record(z.unknown())),
  }),
});

const partSchema = z.union([
  textPartSchema,
  imagePartSchema,
  uiPartSchema,
  uiEventPartSchema,
]);
// This defines the valid structure for a message in the conversation.
const messageSchema = z.object({
  role: z.enum(["user", "model"]),
  parts: z.array(partSchema),
});

export const generateUiRequestSchema = z.object({
  catalog: jsonSchema,
  conversation: z.array(messageSchema),
});

type Part = z.infer<typeof partSchema>;
type Message = z.infer<typeof messageSchema>;
type GenerateUiRequest = z.infer<typeof generateUiRequestSchema>;

export type { Part, Message, GenerateUiRequest };
