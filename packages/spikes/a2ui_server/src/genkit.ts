// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { genkit, z } from "genkit";
import { googleAI } from "@genkit-ai/googleai";

export { z };

export const ai = genkit({
  plugins: [googleAI()],
  model: "googleai/gemini-1.5-flash",
});
