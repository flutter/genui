To integrate `json_serializable` with `freezed` in Dart for robust and immutable data models with automatic JSON serialization and deserialization, follow these steps:

*   **Add Dependencies:** Include `freezed_annotation`, `json_annotation` as regular dependencies, and `build_runner`, `freezed`, `json_serializable` as dev dependencies in your `pubspec.yaml`:

Code

```
dependencies:
      freezed_annotation: ^latest_version
      json_annotation: ^latest_version

    dev_dependencies:
      build_runner: ^latest_version
      freezed: ^latest_version
      json_serializable: ^latest_version
```

Then run `dart pub get` (or `flutter pub get` for Flutter projects).

*   **Define Your Freezed Class:** Create a Dart file (e.g., `user.dart`) and define your data model using `freezed`. Crucially, you need to:

    *   Import `freezed_annotation.dart` and `json_annotation.dart`.
    *   Declare two `part` files: one for `freezed` (`.freezed.dart`) and one for `json_serializable` (`.g.dart`).
    *   Annotate your `factory` constructor within the `freezed` class with `@JsonSerializable()`.
    *   Add a `factory` constructor named `fromJson` that connects to the generated `_$YourClassNameFromJson` function.
    *   Override the `toJson` method to connect to the generated `_$YourClassNameToJson` function.

Code

```
import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:json_annotation/json_annotation.dart';

    part 'user.freezed.dart';
    part 'user.g.dart';

    @freezed
    class User with _$User {
      @JsonSerializable() // Apply JsonSerializable to the factory constructor
      const factory User({
        required String name,
        required int age,
      }) = _User;

      // Connect to the generated fromJson function
      factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

      // Connect to the generated toJson function
      @override
      Map<String, dynamic> toJson() => _$UserToJson(this);
    }
```

*   **Generate Code:** Run the `build_runner` command to generate the necessary code for both `freezed` and `json_serializable`:

Code

```
dart run build_runner build --delete-conflicting-outputs
```

(or `flutter pub run build_runner build --delete-conflicting-outputs` for Flutter projects).

This command will generate `user.freezed.dart` (for `freezed`) and `user.g.dart` (for `json_serializable`), containing the boilerplate code for immutability, `copyWith`, `equals`, `hashCode`, `toString`, and the `fromJson`/`toJson` methods.

Now, your `User` class will be immutable, offer handy utility methods from `freezed`, and automatically handle JSON serialization and deserialization via `json_serializable`.