// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { startFlowServer } from "@genkit-ai/express";
import { generateUiFlow } from "./generate";

startFlowServer({
  flows: [generateUiFlow],
});
