// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { googleAI } from '@genkit-ai/google-genai';
import { genkit, z } from 'genkit';
import * as fs from 'fs';
import * as path from 'path';
import { openAI } from '@genkit-ai/compat-oai/openai';
import { anthropic } from 'genkitx-anthropic';
import { modelsToTest } from './models';
import { prompts, TestPrompt } from './prompts';
import { validateSchema } from './validator';

const ai = genkit({
  plugins: [googleAI({ apiKey: process.env.GEMINI_API_KEY! }), openAI(), anthropic({ apiKey: process.env.ANTHROPIC_API_KEY }),
  ],
});

// Define a UI component generator flow
export const componentGeneratorFlow = ai.defineFlow(
  {
    name: 'componentGeneratorFlow',
    inputSchema: z.object({ prompt: z.string(), model: z.any(), config: z.any().optional(), schema: z.any() }),
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

    if (!output) throw new Error('Failed to generate component');

    return output;
  },
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
    const [key, value] = arg.split('=');
    if (key.startsWith('--')) {
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
  if (typeof args.model === 'string') {
    filteredModels = modelsToTest.filter(m => m.name === args.model);
    if (filteredModels.length === 0) {
      console.error(`Model "${args.model}" not found.`);
      process.exit(1);
    }
  }

  let filteredPrompts = prompts;
  if (typeof args.prompt === 'string') {
    filteredPrompts = prompts.filter(p => p.name === args.prompt);
    if (filteredPrompts.length === 0) {
      console.error(`Prompt "${args.prompt}" not found.`);
      process.exit(1);
    }
  }

  const generationPromises: Promise<InferenceResult>[] = [];

  for (const prompt of filteredPrompts) {
    const schemaString = fs.readFileSync(path.join(__dirname, prompt.schema), 'utf-8');
    const schema = JSON.parse(schemaString);
    for (const modelConfig of filteredModels) {
      console.log(`Queueing generation for model: ${modelConfig.name}, prompt: ${prompt.name}`);
      const startTime = Date.now();
      generationPromises.push(
        componentGeneratorFlow({
          prompt: prompt.promptText,
          model: modelConfig.model,
          config: modelConfig.config,
          schema,
        }).then(component => {
          const validationResults = validateSchema(component, prompt.schema);
          return {
            modelName: modelConfig.name,
            prompt,
            component,
            error: null,
            latency: Date.now() - startTime,
            validationResults,
          };
        }).catch(error => ({
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

  console.log('\n--- Generation Results ---');
  for (const modelName in resultsByModel) {
    for (const result of resultsByModel[modelName]) {
      const hasError = !!result.error;
      const hasValidationFailures = result.validationResults.length > 0;
      const hasComponent = !!result.component;

      if (hasError || hasValidationFailures || (verbose && hasComponent)) {
        console.log(`\n----------------------------------------`);
        console.log(`Model: ${modelName}`);
        console.log(`----------------------------------------`);
        console.log(`\nQuery: ${result.prompt.name}`);

        if (hasError) {
          console.error('Error generating component:', result.error);
        } else if (hasComponent) {
          if (hasValidationFailures) {
            console.log('Validation Failures:');
            result.validationResults.forEach(failure => console.log(`- ${failure}`));
          }
          if (verbose) {
            if (hasValidationFailures) {
              console.log('Generated schema:');
            }
            console.log(JSON.stringify(result.component, null, 2));
          }
        }
      }
    }
  }

  console.log('\n--- Summary ---');
  for (const modelName in resultsByModel) {
    console.log(`\n----------------------------------------`);
    console.log(`Model: ${modelName}`);
    console.log(`----------------------------------------`);
    const header = `${'Prompt Name'.padEnd(30)}${'Latency (ms)'.padEnd(15)}${'Val Failure Count'.padEnd(20)}${'Status'}`;
    const divider = '-'.repeat(header.length);
    console.log(header);
    console.log(divider);

    let modelFailures = 0;
    let modelValidationFailures = 0;

    for (const result of resultsByModel[modelName]) {
      if (result.error) {
        modelFailures++;
      }
      const validationFailureCount = result.validationResults?.length || 0;
      modelValidationFailures += validationFailureCount;

      const promptName = result.prompt.name.padEnd(30);
      const latency = `${result.latency}ms`.padEnd(15);
      const valFailureCount = validationFailureCount.toString().padEnd(20);
      const statusContent = result.error ? 'FAILED' : '';
      const status = statusContent.padEnd(8);
      console.log(`${promptName}${latency}${valFailureCount}${status}`);
    }
    console.log(divider);
    console.log(`Total failures: ${modelFailures}`);
    console.log(`Total validation failures: ${modelValidationFailures}`);
  }

  console.log('\n--- Overall Summary ---');
  const totalModelApiFailures = results.filter(r => r.error).length;
  const totalValidationFailures = results.reduce((acc, r) => acc + r.validationResults.length, 0);
  const testsWithAnyFailure = results.filter(r => r.error || r.validationResults.length > 0).length;
  const modelsWithFailures = [...new Set(
    results
      .filter(r => r.error || r.validationResults.length > 0)
      .map(r => r.modelName)
  )].join(', ');

  console.log(`Number of model API failures: ${totalModelApiFailures}`);
  console.log(`Number of validation failures in total: ${totalValidationFailures}`);
  console.log(`Number of tests with either a model failure or at least 1 validation failure: ${testsWithAnyFailure}`);
  if (modelsWithFailures) {
    console.log(`Models with at least one failure: ${modelsWithFailures}`);
  }
}


main().catch(console.error);