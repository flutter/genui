# test_and_fix

A command-line tool to run tests and apply fixes to the genui monorepo.

## Usage

To run the tool, execute the following command from the root of the repository:

```bash
dart run tool/test_and_fix/bin/test_and_fix.dart
```

You can also pass the `--verbose` (or `-v`) flag to see the full output of all jobs, even the successful ones.

The tool will automatically discover all Flutter projects in the repository and run the following tasks in parallel:

- `dart fix --apply .`
- `dart format .`
- `dart run tool/fix_copyright/bin/fix_copyright.dart --force`
- `dart analyze` (for each project)
- `flutter test` (for each project with a `test` directory)

The output of successful jobs will be printed first, followed by the output of any failed jobs. If any jobs fail, the tool will exit with a non-zero exit code.
