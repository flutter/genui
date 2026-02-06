# `json_schema_builder` Change Log

## 0.1.4 (in progress)

- **Fix**: Remove `package:intl` dependency (#682, #686).
- **Internal**: Enable stricter dynamic-related analysis (#652).
- **Internal**: Use null-aware elements per latest lint update (#690).

## 0.1.3

- Use [`email_validator`](https://pub.dev/packages/email_validator) package to
  validate emails instead of a regular expression.
- Reduce required version for `meta` package to 1.16.0.

## 0.1.2

- Add dartdoc comments to all public APIs.
- Treat failures to fetch remote schemas as validation failures.
- Add web compatibility using conditional imports for `dart:io`.

## 0.1.1

- Fix homepage link

## 0.1.0

- Initial version.
