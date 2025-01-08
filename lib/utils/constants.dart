import 'package:flutter/material.dart';

// Main Color Palette
const Color kMainColor = Color.fromARGB(255, 101, 100, 100);
const Color kSuccessColor = Color.fromARGB(255, 91, 167, 4);
const Color kErrorColor = Color.fromARGB(255, 202, 22, 9);
const Color kPrimaryColor = Color.fromARGB(255, 67, 68, 158);

// Font Sizes
const double kAppBarFontSize = 16.0;

// Padding and Margins
const double kDefaultPadding = 16.0;
const double kDefaultMargin = 16.0;

// Text Styles
const TextStyle kAppBarTextStyle = TextStyle(
  fontSize: kAppBarFontSize,
  color: kSuccessColor,
  fontWeight: FontWeight.bold,
);

// Example Box Decorations
const BoxDecoration kCardDecoration = BoxDecoration(
  color: kMainColor,
  borderRadius: BorderRadius.all(Radius.circular(8.0)),
  boxShadow: [
    BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(2, 2)),
  ],
);
