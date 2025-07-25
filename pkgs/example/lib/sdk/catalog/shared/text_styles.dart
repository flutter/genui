import 'package:flutter/material.dart';

abstract class GenUiTextStyles {
  static TextStyle normal(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!;
  }

  static TextStyle h1(BuildContext context) => normal(
    context,
  ).copyWith(fontSize: 36.0, fontWeight: FontWeight.w900, inherit: true);

  static TextStyle h2(BuildContext context) => normal(
    context,
  ).copyWith(fontSize: 22.0, fontWeight: FontWeight.w200, inherit: true);
}
