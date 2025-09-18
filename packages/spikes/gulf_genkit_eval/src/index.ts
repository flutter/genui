// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { googleAI } from "@genkit-ai/google-genai";
import { genkit, z } from "genkit";
import * as fs from "fs";
import * as path from "path";
import { openAI } from "@genkit-ai/compat-oai/openai";
import { anthropic } from "genkitx-anthropic";
import { modelsToTest } from "./models";
import { prompts, TestPrompt } from "./prompts";
import { validateSchema } from "./validator";

const ai = genkit({
  plugins: [
    googleAI({ apiKey: process.env.GEMINI_API_KEY! }),
    openAI(),
    anthropic({ apiKey: process.env.ANTHROPIC_API_KEY }),
  ],
});

// Define a UI component generator flow
export const componentGeneratorFlow = ai.defineFlow(
  {
    name: "componentGeneratorFlow",
    inputSchema: z.object({
      prompt: z.string(),
      model: z.any(),
      config: z.any().optional(),
      schema: z.any(),
    }),
    outputSchema: z.any(),
  },
  async ({ prompt, model, config, schema }) => {
    // Generate structured component data using the schema from the file
    const { output } = await ai.generate({
      prompt,
      model,
      output: { jsonSchema: schema },
      config,
    });

    if (!output) throw new Error("Failed to generate component");

    return output;
  }
);

interface InferenceResult {
  modelName: string;
  prompt: TestPrompt;
  component: any;
  error: any;
  latency: number;
  validationResults: string[];
}

// Run the flow
async function main() {
  const args = process.argv.slice(2).reduce((acc, arg) => {
    const [key, value] = arg.split("=");
    if (key.startsWith("--")) {
      if (value) {
        acc[key.substring(2)] = value;
      } else {
        acc[key.substring(2)] = true;
      }
    }
    return acc;
  }, {} as Record<string, string | boolean>);

  const verbose = !!args.verbose;

  let filteredModels = modelsToTest;
  if (typeof args.model === "string") {
    filteredModels = modelsToTest.filter((m) => m.name === args.model);
    if (filteredModels.length === 0) {
      console.error(`Model "${args.model}" not found.`);
      process.exit(1);
    }
  }

  let filteredPrompts = prompts;
  if (typeof args.prompt === "string") {
    filteredPrompts = prompts.filter((p) => p.name === args.prompt);
    if (filteredPrompts.length === 0) {
      console.error(`Prompt "${args.prompt}" not found.`);
      process.exit(1);
    }
  }

  const generationPromises: Promise<InferenceResult>[] = [];

  for (const prompt of filteredPrompts) {
    const schemaString = fs.readFileSync(
      path.join(__dirname, prompt.schema),
      "utf-8"
    );
    const schema = JSON.parse(schemaString);
    for (const modelConfig of filteredModels) {
      console.log(
        `Queueing generation for model: ${modelConfig.name}, prompt: ${prompt.name}`
      );
      const startTime = Date.now();
      generationPromises.push(
        componentGeneratorFlow({
          prompt: prompt.promptText,
          model: modelConfig.model,
          config: modelConfig.config,
          schema,
        })
          .then((component) => {
            const validationResults = validateSchema(component, prompt.schema);
            return {
              modelName: modelConfig.name,
              prompt,
              component,
              error: null,
              latency: Date.now() - startTime,
              validationResults,
            };
          })
          .catch((error) => ({
            modelName: modelConfig.name,
            prompt,
            component: null,
            error,
            latency: Date.now() - startTime,
            validationResults: [],
          }))
      );
    }
  }

  const results = await Promise.all(generationPromises);

  const resultsByModel: Record<string, InferenceResult[]> = {};

  for (const result of results) {
    if (!resultsByModel[result.modelName]) {
      resultsByModel[result.modelName] = [];
    }
    resultsByModel[result.modelName].push(result);
  }

  console.log("\n--- Generation Results ---");
  for (const modelName in resultsByModel) {
    console.log(`\n----------------------------------------`);
    console.log(`Model: ${modelName}`);
    console.log(`----------------------------------------`);
    for (const result of resultsByModel[modelName]) {
      console.log(`\nQuery: ${result.prompt.name}`);
      console.log(`Latency: ${result.latency}ms`);
      if (result.component) {
        const hasValidationFailures = result.validationResults.length > 0;
        if (hasValidationFailures) {
          console.log("Validation Failures:");
          result.validationResults.forEach((failure) =>
            console.log(`- ${failure}`)
          );
          console.log("Generated schema:");
          console.log(JSON.stringify(result.component, null, 2));
        } else if (verbose) {
          console.log(JSON.stringify(result.component, null, 2));
        }
      } else {
        console.error("Error generating component:", result.error);
      }
    }
  }

  console.log("\n--- Summary ---");
  console.log(
    "Model".padEnd(40),
    "Prompt Name".padEnd(30),
    "Latency (ms)".padEnd(15),
    "Val Failure Count".padEnd(20),
    "Status"
  );
  console.log("-".repeat(115));
  let totalFailures = 0;
  let totalValidationErrors = 0;
  for (const result of results) {
    if (result.error) {
      totalFailures++;
    }
    totalValidationErrors += result.validationResults?.length || 0;
    const modelName = result.modelName.padEnd(40);
    const promptName = result.prompt.name.padEnd(30);
    const latency = (result.latency + "ms").padEnd(15);
    const valFailureCount = (result.validationResults?.length || 0)
      .toString()
      .padEnd(20);
    const status = result.error ? "FAILED" : "PASSED";
    console.log(
      `${modelName}${promptName}${latency}${valFailureCount}${status}`
    );
  }
  console.log("-".repeat(115));
  const totalsLabel = "Totals:".padEnd(40);
  const emptyPrompt = "".padEnd(30);
  const emptyLatency = "".padEnd(15);
  const totalValidationErrorsStr = totalValidationErrors.toString().padEnd(20);
  const totalFailuresStr = `${totalFailures} failures`;
  console.log(
    `${totalsLabel}${emptyPrompt}${emptyLatency}${totalValidationErrorsStr}${totalFailuresStr}`
  );
}

main().catch(console.error);
