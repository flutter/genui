// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import pino from "pino";

// By default, logging is off ('silent').
// To enable logging, set the LOG_LEVEL environment variable.
// e.g., LOG_LEVEL=info pnpm run genkit:dev
// Supported levels: 'fatal', 'error', 'warn', 'info', 'debug', 'trace'.
const logLevel = process.env.LOG_LEVEL || "silent";

export const logger = pino({
  level: logLevel,
  // Use pino-pretty for human-readable logs in development.
  ...(process.env.NODE_ENV !== "production" && {
    transport: {
      target: "pino-pretty",
      options: {
        colorize: true,
      },
    },
  }),
});
