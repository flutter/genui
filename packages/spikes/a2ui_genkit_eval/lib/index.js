// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

"use strict";
var __createBinding =
  (this && this.__createBinding) ||
  (Object.create
    ? function (o, m, k, k2) {
        if (k2 === undefined) k2 = k;
        var desc = Object.getOwnPropertyDescriptor(m, k);
        if (
          !desc ||
          ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)
        ) {
          desc = {
            enumerable: true,
            get: function () {
              return m[k];
            },
          };
        }
        Object.defineProperty(o, k2, desc);
      }
    : function (o, m, k, k2) {
        if (k2 === undefined) k2 = k;
        o[k2] = m[k];
      });
var __setModuleDefault =
  (this && this.__setModuleDefault) ||
  (Object.create
    ? function (o, v) {
        Object.defineProperty(o, "default", { enumerable: true, value: v });
      }
    : function (o, v) {
        o["default"] = v;
      });
var __importStar =
  (this && this.__importStar) ||
  (function () {
    var ownKeys = function (o) {
      ownKeys =
        Object.getOwnPropertyNames ||
        function (o) {
          var ar = [];
          for (var k in o)
            if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
          return ar;
        };
      return ownKeys(o);
    };
    return function (mod) {
      if (mod && mod.__esModule) return mod;
      var result = {};
      if (mod != null)
        for (var k = ownKeys(mod), i = 0; i < k.length; i++)
          if (k[i] !== "default") __createBinding(result, mod, k[i]);
      __setModuleDefault(result, mod);
      return result;
    };
  })();
Object.defineProperty(exports, "__esModule", { value: true });
exports.componentGeneratorFlow = void 0;
const google_genai_1 = require("@genkit-ai/google-genai");
const genkit_1 = require("genkit");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const openai_1 = require("@genkit-ai/compat-oai/openai");
const genkitx_anthropic_1 = require("genkitx-anthropic");
// Read the schema file
const schemaString = fs.readFileSync(
  path.join(__dirname, "schema.json"),
  "utf-8"
);
const schema = JSON.parse(schemaString);
const ai = (0, genkit_1.genkit)({
  plugins: [
    (0, google_genai_1.googleAI)({ apiKey: process.env.GEMINI_API_KEY }),
    (0, openai_1.openAI)(),
    (0, genkitx_anthropic_1.anthropic)({
      apiKey: process.env.ANTHROPIC_API_KEY,
    }),
  ],
});
// Define a UI component generator flow
exports.componentGeneratorFlow = ai.defineFlow(
  {
    name: "componentGeneratorFlow",
    inputSchema: genkit_1.z.object({
      prompt: genkit_1.z.string(),
      model: genkit_1.z.any(),
    }),
    outputSchema: genkit_1.z.any(),
  },
  async ({ prompt, model }) => {
    // Generate structured component data using the schema from the file
    const { output } = await ai.generate({
      prompt,
      model,
      output: { jsonSchema: schema },
      // config: {
      //     thinkingConfig: { thinkingBudget: 0 }
      // },
    });
    if (!output) throw new Error("Failed to generate component");
    return output;
  }
);
// Run the flow
async function main() {
  const models = [
    openai_1.openAI.model("gpt-5-mini"),
    openai_1.openAI.model("gpt-5"),
    openai_1.openAI.model("gpt-5-nano"),
    google_genai_1.googleAI.model("gemini-2.5-flash"),
    google_genai_1.googleAI.model("gemini-2.5-flash-lite"),
    genkitx_anthropic_1.claude4Sonnet,
    genkitx_anthropic_1.claude35Haiku,
  ];
  const prompt = `Generate a JSON conforming to the schema to describe the following UI:

A root node has already been created with ID "root". You need to create a ComponentUpdate message now.

A vertical list with:
Dog breed information
Dog generator

The dog breed information is a card, which contains a title “Famous Dog breeds”, a header image, and a carousel of different dog breeds. The carousel information should be in the data model at /carousel.

The dog generator is another card which is a form that generates a fictional dog breed with a description
- Title
- Description text explaining what it is
- Dog breed name (text input)
- Number of legs (number input)
- Skills (checkboxes)
- Button called “Generate” which takes the data above and generates a new dog description
- A divider
- A section which shows the generated content
`;
  for (const model of models) {
    console.log(`Generating component with model: ${model.name}`);
    const component = await (0, exports.componentGeneratorFlow)({
      prompt,
      model,
    });
    console.log(JSON.stringify(component, null, 2));
  }
}
main().catch(console.error);
