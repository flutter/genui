// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { googleAI } from '@genkit-ai/google-genai';
import { openAI } from '@genkit-ai/compat-oai/openai';
import { claude35Haiku, claude4Sonnet } from 'genkitx-anthropic';

export interface ModelConfiguration {
    model: any;
    name: string;
    config?: any;
}

export const modelsToTest: ModelConfiguration[] = [
    {
        model: openAI.model('gpt-5'),
        name: 'gpt-5 (reasoning: minimal)',
        config: { reasoning_effort: 'minimal' },
    },
    {
        model: openAI.model('gpt-5-mini'),
        name: 'gpt-5-mini (reasoning: minimal)',
        config: { reasoning_effort: 'minimal' },
    },
    {
        model: openAI.model('gpt-5-nano'),
        name: 'gpt-5-nano (reasoning: minimal)',
        config: { reasoning_effort: 'minimal' },
    },
    {
        model: googleAI.model('gemini-2.5-flash'),
        name: 'gemini-2.5-flash (thinking: 0)',
        config: { thinkingConfig: { thinkingBudget: 0 } },
    },
    {
        model: googleAI.model('gemini-2.5-flash-lite'),
        name: 'gemini-2.5-flash-lite (thinking: 0)',
        config: { thinkingConfig: { thinkingBudget: 0 } },
    },
    {
        model: claude4Sonnet,
        name: 'claude-3-sonnet-20240229',
        config: {},
    },
    {
        model: claude35Haiku,
        name: 'claude-3-haiku-20240307',
        config: {},
    },
];
