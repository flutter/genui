// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { ai, z } from "./genkit";
import { generateUiRequestSchema, Part as ClientPart } from "./schemas";
import { googleAI } from "@genkit-ai/googleai";
import { logger } from "./logger";
import { Message, Part } from "@genkit-ai/ai";

const widgetSchema = z.object({
  id: z.string().describe("The unique ID for the widget."),
  widget: z.any().describe("The widget definition."),
});

const uiDefinitionSchema = z.object({
  root: z.string().describe("The ID of the root widget in the UI tree."),
  widgets: z
    .array(widgetSchema)
    .describe("A list of all the widget definitions for this UI surface."),
});

const updateSurfaceInputSchema = z.object({
  surfaceId: z.string().describe("The unique ID for the UI surface."),
  definition: uiDefinitionSchema.describe(
    "A JSON object that defines the UI surface."
  ),
});
type UpdateSurfaceInput = z.infer<typeof updateSurfaceInputSchema>;

const updateSurfaceTool = ai.defineTool(
  {
    name: "updateSurface",
    description:
      "Add or update a UI surface. The 'definition' must conform to the JSON schema provided in the system prompt.",
    inputSchema: updateSurfaceInputSchema,
    outputSchema: z.object({ status: z.string() }),
  },
  async (args: object) => {
    logger.debug(`Received tool call with arguments:\n${JSON.stringify(args)}`);
    return { status: "updated" };
  }
);

const deleteSurfaceInputSchema = z.object({
  surfaceId: z.string().describe("The unique ID for the UI surface."),
});
type DeleteSurfaceInput = z.infer<typeof deleteSurfaceInputSchema>;

const deleteSurfaceTool = ai.defineTool(
  {
    name: "deleteSurface",
    description: "Delete a UI surface.",
    inputSchema: deleteSurfaceInputSchema,
    outputSchema: z.object({ status: z.string() }),
  },
  async () => ({ status: "deleted" })
);

export const generateUiFlow = ai.defineFlow(
  {
    name: "generateUi",
    inputSchema: generateUiRequestSchema,
    outputSchema: z.unknown(),
  },
  async (request, streamingCallback) => {
    const catalog = request.catalog;
    if (!catalog) {
      logger.error(`No catalog provided in the request.`);
      throw new Error("No catalog provided in the request.");
    }
    logger.debug("Successfully retrieved catalog from request.");

    // Convert the dynamic catalog (which is a JSON schema) to a string.
    const catalogSchemaString = JSON.stringify(catalog, null, 2);

    // Create a dynamic system prompt that includes the schema. This instructs
    // the model on how to structure the 'definition' parameter for this call.
    const systemPrompt = `
You are an expert UI generation agent. Your goal is to generate a UI based on the user's request.

When the user interacts with the UI, you will receive a message containing a JSON block with an array of UI events. You should use the data from these events, especially the 'value' of the action event, to understand the current state of the UI and decide on the next step.

When you use the 'updateSurface' tool, the 'definition' parameter you provide MUST be a JSON object that strictly conforms to the following JSON Schema:
\`\`\`json
${catalogSchemaString}
\`\`\`

After you have successfully called the 'updateSurface' tool and have received a 'toolResponse' with a status of 'updated', you should consider the user's request fulfilled. Respond with a short confirmation message to the user and then stop. Do not call the tool again unless the user asks for further changes.
`.trim();

    // Transform conversation to Genkit's format
    const genkitConversation: Message[] = request.conversation.map(
      (message) => {
        const uiEventParts = message.parts.filter(
          (part) => part.type === "uiEvent"
        );
        const otherParts = message.parts.filter(
          (part) => part.type !== "uiEvent"
        );

        const content: Part[] = otherParts
          .map((part: ClientPart): Part | undefined => {
            if (part.type === "text") {
              return { text: part.text };
            }
            if (part.type === "image") {
              if (part.url) {
                const mediaPart: {
                  media: { url: string; contentType?: string };
                } = {
                  media: { url: part.url },
                };
                if (part.mimeType) {
                  mediaPart.media.contentType = part.mimeType;
                }
                return mediaPart;
              }
              if (part.base64 && part.mimeType) {
                const dataUrl = `data:${part.mimeType};base64,${part.base64}`;
                return { media: { url: dataUrl, contentType: part.mimeType } };
              }
            }
            if (part.type === "ui") {
              return {
                toolRequest: {
                  name: "updateSurface",
                  input: part.definition,
                },
              };
            }
            // uiEvent is handled below
            return undefined;
          })
          .filter((p): p is Part => p !== undefined);

        if (uiEventParts.length > 0) {
          const events = uiEventParts.map(
            (part) => (part as Record<string, unknown>).event
          );

          content.push({
            text: `The user interacted with the UI, resulting in the following events.


${JSON.stringify(events, null, 2)}

`,
          });
        }

        return new Message({
          role: message.role,
          content,
        });
      }
    );

    try {
      logger.debug(
        genkitConversation,
        "Starting AI generation for conversation"
      );
      const { stream, response } = ai.generateStream({
        model: googleAI.model("gemini-2.5-pro"),
        // Add the dynamic system prompt to the generation call.
        system: systemPrompt,
        messages: genkitConversation,
        // Use the statically defined tools.
        tools: [updateSurfaceTool, deleteSurfaceTool],
      });

      for await (const chunk of stream) {
        logger.debug({ chunk }, "Chunk from AI");
        if (chunk.toolRequests) {
          logger.info("Transforming tool request to A2UI protocol.");
          for (const toolRequest of chunk.toolRequests) {
            if (toolRequest.toolRequest.name === "updateSurface") {
              const { surfaceId, definition } = toolRequest.toolRequest
                .input as UpdateSurfaceInput;
              const { root, widgets } = definition;
              streamingCallback({
                surfaceUpdate: {
                  surfaceId,
                  components: widgets,
                },
              });
              streamingCallback({
                beginRendering: {
                  surfaceId,
                  root,
                },
              });
            } else if (toolRequest.toolRequest.name === "deleteSurface") {
              const { surfaceId } = toolRequest.toolRequest
                .input as DeleteSurfaceInput;
              streamingCallback({
                deleteSurface: {
                  surfaceId,
                },
              });
            }
          }
        }
      }

      const finalResponse = await response;
      if (finalResponse.text) {
        logger.info(
          "Skipping final text response from AI, as it's not part of the A2UI protocol."
        );
      }

      return finalResponse;
    } catch (error) {
      logger.error(error, "An error occurred during AI generation");
      throw error;
    }
  }
);
