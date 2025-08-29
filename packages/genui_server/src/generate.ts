import { ai, z } from "./genkit";
import { generateUiRequestSchema } from "./schemas";
import { googleAI } from "@genkit-ai/googleai";
import { cacheService, CacheFlowContext } from "./cache";
import { logger } from "./logger";

const addOrUpdateSurfaceTool = ai.defineTool(
  {
    name: "addOrUpdateSurface",
    description: "Add or update a UI surface.",
    inputSchema: z.object({
      surfaceId: z.string(),
      definition: z.unknown(),
    }),
    outputSchema: z.void(),
  },
  async () => {}
);

const deleteSurfaceTool = ai.defineTool(
  {
    name: "deleteSurface",
    description: "Delete a UI surface.",
    inputSchema: z.object({
      surfaceId: z.string(),
    }),
    outputSchema: z.void(),
  },
  async () => {}
);

export const generateUiFlow = ai.defineFlow(
  {
    name: "generateUi",
    inputSchema: generateUiRequestSchema,
    outputSchema: z.unknown(),
  },
  async (request, streamingCallback) => {
    const resolvedCache =
      (streamingCallback.context as CacheFlowContext)?.cache || cacheService;

    const catalog = await resolvedCache.getSessionCache(request.sessionId);
    if (!catalog) {
      logger.error(`Invalid session ID: ${request.sessionId}`);
      throw new Error("Invalid session ID");
    }
    logger.debug("Successfully retrieved catalog from cache.");

    try {
      logger.debug(
        request.conversation,
        "Starting AI generation for conversation"
      );
      const { stream, response } = ai.generateStream({
        model: googleAI.model("gemini-pro"),
        prompt: request.conversation,
        tools: [addOrUpdateSurfaceTool, deleteSurfaceTool],
      });

      for await (const chunk of stream) {
        logger.debug({ chunk }, "Chunk from AI");
        if (chunk.toolRequests) {
          logger.info("Yielding tool request from AI.");
          streamingCallback(chunk);
        }
      }
      return await response;
    } catch (error) {
      logger.error(error, "An error occurred during AI generation");
      throw error;
    }
  }
);
