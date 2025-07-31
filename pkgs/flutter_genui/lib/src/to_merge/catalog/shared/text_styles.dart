import 'package:flutter/material.dart';

abstract class GenUiTextStyles {
  static TextStyle normal(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          fontSize: 14.0,
          inherit: true,
          fontWeight: FontWeight.w300,
        );
  }

  static TextStyle link(BuildContext context) => normal(
        context,
      ).copyWith(color: Colors.blue, inherit: true);

  static TextStyle h1(BuildContext context) => normal(
        context,
      ).copyWith(fontSize: 30.0, fontWeight: FontWeight.w700, inherit: true);

  static TextStyle h2(BuildContext context) => normal(
        context,
      ).copyWith(fontSize: 22.0, fontWeight: FontWeight.w500, inherit: true);
}
