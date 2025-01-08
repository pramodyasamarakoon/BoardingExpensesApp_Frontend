import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = kPrimaryColor, // Default blue background
    this.textColor = Colors.white, // Default black text
    this.height = 45.0, // Default button height
    this.borderRadius = 14.0, // Default border radius
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Full width
      height: height, // Set height from the parameter
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor, // Corrected background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius), // Border radius
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor, // Text color
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }
}
