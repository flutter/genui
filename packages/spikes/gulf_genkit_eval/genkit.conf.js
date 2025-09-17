import { googleAI } from '@genkit-ai/google-genai';
import { configure } from 'genkit';

export default configure({
  plugins: [
    googleAI(),
  ],
  logLevel: 'debug',
  enableTracingAndMetrics: true,
});
