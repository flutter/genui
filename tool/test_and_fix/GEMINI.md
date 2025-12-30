# `test_and_fix` Package

## Overview

The `test_and_fix` package is a command-line tool designed to automate the process of running tests, analysis, and code formatting across all Dart and Flutter projects within the `genui` monorepo. It replaces the functionality of the original `run_all_tests_and_fixes.sh` script with a more robust and platform-independent Dart solution.

It is not meant to be used to run specific tests, but rather as something that is run right before committing code to ensure that the code is in a good state.

## Implementation Details

The tool is architected with a separation of concerns: the command-line argument parsing and the core logic.

### Entry Point

The main executable script is located in `bin/test_and_fix.dart`. It is responsible for:

- Parsing command-line arguments:
  - `--help` (`-h`): Prints usage information.
  - `--verbose` (`-v`): Prints the full output for all jobs, including successful ones.
  - `--all`: Runs checks on all projects, including those that are normally skipped (e.g., `spikes`).
- Instantiating and running the `TestAndFix` class.
- Exiting with an appropriate exit code based on the success of the run.

### Core Logic

The core logic resides in the `TestAndFix` class in `lib/test_and_fix.dart`. It uses the `process_runner` package to execute multiple processes in parallel, significantly speeding up the testing and analysis workflow.

### Project Discovery

The tool begins by scanning the monorepo for projects. It identifies projects by searching for `pubspec.yaml` files. To avoid unnecessary processing, it excludes certain directories.

- **Always excluded:** `.dart_tool`, `ephemeral`, `firebase_core`, `build`.
- **Excluded by default (unless `--all` is passed):** `spikes`, `fix_copyright`, `test_and_fix`.

### Task Execution

Once the projects are identified, the tool creates a series of jobs to be executed in parallel using a `ProcessPool`. These jobs are categorized as follows:

- **Global Jobs:** These are tasks that run once for the entire repository:

  1.  `dart fix --apply .`
  2.  `dart format .` (depends on `dart fix`)
  3.  `dart run tool/fix_copyright/bin/fix_copyright.dart --force` (depends on `dart format`)

- **Project-Specific Jobs:** For each discovered project, the tool runs the following (depending on the global jobs):
  - `dart analyze`: Performs static analysis.
  - `dart test` or `flutter test`: If a `test` directory exists, it runs the appropriate test command. The tool checks the `pubspec.yaml` to determine if it's a Flutter project.

### Output Handling

After all jobs have completed, the tool intelligently separates the results into successful and failed jobs. It first prints a summary of successful jobs, followed by a clearly marked section with the detailed output of any failed jobs, making it easy to identify and address issues. If any job fails, the tool exits with a non-zero exit code, making it suitable for use in CI/CD pipelines.

## File Layout

- `bin/test_and_fix.dart`: The main executable script for the tool.
- `lib/test_and_fix.dart`: Contains the core `TestAndFix` class and its logic.
- `pubspec.yaml`: Defines the package's dependencies, including `process_runner` and `args`.
- `README.md`: Provides a user-friendly guide on how to use the tool.
- `test/`: Contains unit tests for the tool's logic, including project discovery and command execution.
