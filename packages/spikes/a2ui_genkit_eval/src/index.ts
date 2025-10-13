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
  runNumber: number;
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
  const keep = args.keep;
  let outputDir: string | null = null;

  if (keep) {
    if (typeof keep === 'string') {
      outputDir = keep;
    } else {
      outputDir = fs.mkdtempSync(path.join(process.cwd(), 'a2ui-eval-'));
    }
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }
    console.log(`Keeping output in: ${outputDir}`);
  }

  const runsPerPrompt = parseInt(args["runs-per-prompt"] as string, 10) || 1;

  let filteredModels = modelsToTest;
  if (typeof args.model === "string") {
    filteredModels = modelsToTest.filter((m) =>
      m.name.startsWith(args.model as string)
    );
    if (filteredModels.length === 0) {
      console.error(`No model found with prefix "${args.model}".`);
      process.exit(1);
    }
  }

  let filteredPrompts = prompts;
  if (typeof args.prompt === "string") {
    filteredPrompts = prompts.filter((p) =>
      p.name.startsWith(args.prompt as string)
    );
    if (filteredPrompts.length === 0) {
      console.error(`No prompt found with prefix "${args.prompt}".`);
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
      const modelDirName = modelConfig.name.replace(/[\/:]/g, '_');
      const modelOutputDir = outputDir
        ? path.join(outputDir, modelDirName)
        : null;
      if (modelOutputDir && !fs.existsSync(modelOutputDir)) {
        fs.mkdirSync(modelOutputDir, { recursive: true });
      }
      for (let i = 1; i <= runsPerPrompt; i++) {
        console.log(
          `Queueing generation for model: ${modelConfig.name}, prompt: ${
            prompt.name
          } (run ${i})`
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
              if (modelOutputDir) {
                const inputPath = path.join(
                  modelOutputDir,
                  `${prompt.name}.input.txt`
                );
                fs.writeFileSync(inputPath, prompt.promptText);

                const outputPath = path.join(
                  modelOutputDir,
                  `${prompt.name}.output.json`
                );
                fs.writeFileSync(outputPath, JSON.stringify(component, null, 2));
              }
              const validationResults = validateSchema(
                component,
                prompt.schema,
                prompt.matchers
              );
              return {
                modelName: modelConfig.name,
                prompt,
                component,
                error: null,
                latency: Date.now() - startTime,
                validationResults,
                runNumber: i,
              };
            })
            .catch((error) => {
              if (modelOutputDir) {
                const inputPath = path.join(
                  modelOutputDir,
                  `${prompt.name}.input.txt`
                );
                fs.writeFileSync(inputPath, prompt.promptText);

                const errorPath = path.join(
                  modelOutputDir,
                  `${prompt.name}.error.json`
                );
                const errorOutput = {
                  message: error.message,
                  stack: error.stack,
                  ...error,
                };
                fs.writeFileSync(errorPath, JSON.stringify(errorOutput, null, 2));
              }
              return {
                modelName: modelConfig.name,
                prompt,
                component: null,
                error,
                latency: Date.now() - startTime,
                validationResults: [],
                runNumber: i,
              };
            })
        );
      }
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
    for (const result of resultsByModel[modelName]) {
      const hasError = !!result.error;
      const hasValidationFailures = result.validationResults.length > 0;
      const hasComponent = !!result.component;

      if (hasError || hasValidationFailures || (verbose && hasComponent)) {
        console.log(`\n----------------------------------------`);
        console.log(`Model: ${modelName}`);
        console.log(`----------------------------------------`);
        console.log(`\nQuery: ${result.prompt.name} (run ${result.runNumber})`);

        if (hasError) {
          console.error("Error generating component:", result.error);
        } else if (hasComponent) {
          if (hasValidationFailures) {
            console.log("Validation Failures:");
            result.validationResults.forEach((failure) =>
              console.log(`- ${failure}`)
            );
          }
          if (verbose) {
            if (hasValidationFailures) {
              console.log("Generated schema:");
            }
            console.log(JSON.stringify(result.component, null, 2));
          }
        }
      }
    }
  }

  console.log("\n--- Summary ---");
  for (const modelName in resultsByModel) {
    console.log(`\n----------------------------------------`);
    console.log(`Model: ${modelName}`);
    console.log(`----------------------------------------`);
    const header = `${"Prompt Name".padEnd(40)}${"Avg Latency (ms)".padEnd(
      20
    )}${"Failed Runs".padEnd(15)}${"Tool Error Runs".padEnd(20)}`;
    const divider = "-".repeat(header.length);
    console.log(header);
    console.log(divider);

    const promptsInModel = resultsByModel[modelName].reduce((acc, result) => {
      if (!acc[result.prompt.name]) {
        acc[result.prompt.name] = [];
      }
      acc[result.prompt.name].push(result);
      return acc;
    }, {} as Record<string, InferenceResult[]>);

    let totalModelFailedRuns = 0;

    for (const promptName in promptsInModel) {
      const runs = promptsInModel[promptName];
      const totalRuns = runs.length;
      const errorRuns = runs.filter((r) => r.error).length;
      const failedRuns = runs.filter(
        (r) => r.error || r.validationResults.length > 0
      ).length;
      const totalLatency = runs.reduce((acc, r) => acc + r.latency, 0);
      const avgLatency = (totalLatency / totalRuns).toFixed(0);

      totalModelFailedRuns += failedRuns;

      const promptStr = promptName.padEnd(40);
      const latencyStr = `${avgLatency}ms`.padEnd(20);
      const failedRunsStr =
        failedRuns > 0
          ? `${failedRuns} / ${totalRuns}`.padEnd(15)
          : "".padEnd(15);
      const errorRunsStr =
        errorRuns > 0
          ? `${errorRuns} / ${totalRuns}`.padEnd(20)
          : "".padEnd(20);

      console.log(`${promptStr}${latencyStr}${failedRunsStr}${errorRunsStr}`);
    }

    console.log(divider);
    const totalRunsForModel = resultsByModel[modelName].length;
    console.log(
      `Total failed runs: ${totalModelFailedRuns} / ${totalRunsForModel}`
    );
  }

  console.log("\n--- Overall Summary ---");
  const totalRuns = results.length;
  const totalToolErrorRuns = results.filter((r) => r.error).length;
  const totalRunsWithAnyFailure = results.filter(
    (r) => r.error || r.validationResults.length > 0
  ).length;
  const modelsWithFailures = [
    ...new Set(
      results
        .filter((r) => r.error || r.validationResults.length > 0)
        .map((r) => r.modelName)
    ),
  ].join(", ");

  console.log(
    `Number of tool error runs: ${totalToolErrorRuns} / ${totalRuns}`
  );
  console.log(
    `Number of runs with any failure (tool error or validation): ${totalRunsWithAnyFailure} / ${totalRuns}`
  );
  if (modelsWithFailures) {
    console.log(`Models with at least one failure: ${modelsWithFailures}`);
  }
}

main().catch(console.error);
