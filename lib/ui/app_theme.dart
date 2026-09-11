import 'package:flutter/material.dart';

/// Shared across every branch so the three examples look identical and only
/// their routing layer differs.
ThemeData buildAppTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
  useMaterial3: true,
);
