# Genkit Flow

To run the flow, use the following command:

```bash
npx tsx src/index.ts
```

## Running a Single Test

You can run the script for a single model and data point by using the `--model` and `--prompt` command-line flags. This is useful for quick tests and debugging.

### Syntax

```bash
npx tsx src/index.ts --model='<model_name>' --prompt=<prompt_name>
```

### Example

To run the test with the `gpt-5-nano (reasoning: minimal)` model and the `generateDogUIs` prompt, use the following command:

```bash
npx tsx src/index.ts --model='gpt-5-nano (reasoning: minimal)' --prompt=generateDogUIs
```

## Controlling Output

By default, the script only prints the summary table and any errors that occur during generation. To see the full JSON output for each successful generation, use the `--verbose` flag.

### Example

```bash
npx tsx src/index.ts --verbose
```
