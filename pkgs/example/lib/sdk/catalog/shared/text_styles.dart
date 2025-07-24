import 'package:flutter/material.dart';

abstract class AppTextStyles {
  static TextStyle normal(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!;
  }

  static TextStyle h1(BuildContext context) => normal(
    context,
  ).copyWith(fontSize: 46.0, fontWeight: FontWeight.w900, inherit: true);

  static TextStyle h2(BuildContext context) => normal(
    context,
  ).copyWith(fontSize: 26.0, fontWeight: FontWeight.w200, inherit: true);

  static TextStyle h3(BuildContext context) => normal(
    context,
  ).copyWith(fontSize: 24.0, fontWeight: FontWeight.w200, inherit: true);
}
