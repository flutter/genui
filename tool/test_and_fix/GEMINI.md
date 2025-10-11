# `test_and_fix` Package

## Overview

The `test_and_fix` package is a command-line tool designed to automate the process of running tests, analysis, and code formatting across all Flutter projects within the `genui` monorepo. It replaces the functionality of the original `run_all_tests_and_fixes.sh` script with a more robust and platform-independent Dart solution.

## Implementation Details

The tool is implemented as a single executable Dart script located in `bin/test_and_fix.dart`. It uses the `process_runner` package to execute multiple processes in parallel, significantly speeding up the testing and analysis workflow.

### Project Discovery

The tool begins by scanning the monorepo for Flutter projects. It identifies projects by searching for `pubspec.yaml` files that contain the `sdk: flutter` dependency. To avoid unnecessary processing, it excludes common directories like `.dart_tool`, `build`, `packages/spikes`, and the tool's own directory.

### Task Execution

Once the projects are identified, the tool creates a series of jobs to be executed. These jobs are categorized as follows:

-   **Global Jobs:** These are tasks that run once for the entire repository, including `dart fix --apply .` and `dart format .`.
-   **Project-Specific Jobs:** For each discovered Flutter project, the tool runs `flutter analyze` to perform static analysis and `flutter test` to execute unit tests (if a `test` directory exists).
-   **Copyright Fix:** The tool also runs the `fix_copyright` tool to ensure all copyright headers are up-to-date, using the command `dart run tool/fix_copyright/bin/fix_copyright.dart --force`.

### Parallelism and Output Handling

All jobs are managed by a `ProcessPool` from the `process_runner` package, which runs them in parallel to maximize efficiency. The tool captures the `stdout` and `stderr` streams of each job.

After all jobs have completed, the tool intelligently separates the results into successful and failed jobs. It then prints the output of all successful jobs, followed by a clearly marked section for any failed jobs, making it easy to identify and address issues. If any job fails, the tool exits with a non-zero exit code, making it suitable for use in CI/CD pipelines.

## File Layout

-   `bin/test_and_fix.dart`: The main executable script for the tool.
-   `pubspec.yaml`: Defines the package's dependencies, including `process_runner`.
-   `README.md`: Provides a user-friendly guide on how to use the tool.
-   `DESIGN.md`: Outlines the architecture and design of the tool.
-   `test/`: Contains unit tests for the tool's logic.