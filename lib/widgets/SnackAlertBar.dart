import 'package:flutter/material.dart';

SnackBar SnackAlertBar(String text, {Color color = Colors.red}) {
  return SnackBar(
    content: Text(
      text,
      style: const TextStyle(color: Colors.white),
    ),
    backgroundColor: color,
  );
}