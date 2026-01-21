# GenUI specifications

This folder (./specs) provides technical specifications for the GenUI repository,
targeted at both AI models and human developers.

## Index of Specifications

This directory contains the following specifications:

- [Style Guide](styleguide.md)

## Note for AI models

If you are an AI model, please read all the specifications in this folder, and follow them carefully.
To signal, that you have read and understood the specifications, please start your reviews and responses with the following text:

```
I have read and understood the specifications in ./specs.
```

## Documentation

1. Documentation in the repository (all .md files) should be clear, consistent, concise and up-to-date.
2. Documentation should not contain details that are easy to infer from the code.
3. If code does not match the documentation, there should be TODO comments in the code to signal the discrepancy should be resolved.

## Code reviews

Do not review pull requests when they are in draft state, unless explicitly requested by the author.

## Key commands

- **Run all checks and tests:**

  ```bash
  ./tool/run_all_tests_and_fixes.sh
  ```
