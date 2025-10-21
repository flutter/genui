// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { googleAI } from "@genkit-ai/google-genai";
import { configure } from "genkit";

export default configure({
  plugins: [googleAI()],
  logLevel: "debug",
  enableTracingAndMetrics: true,
});
