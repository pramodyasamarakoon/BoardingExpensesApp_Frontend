import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double borderRadius;
  final bool disabled; // ✅ New property for disabling the button
  final bool isLoading;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor = kPrimaryColor,
    this.textColor = Colors.white,
    this.height = 45.0,
    this.borderRadius = 14.0,
    this.disabled = false, // ✅ Default to false (enabled)
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              disabled ? Colors.grey : backgroundColor, // ✅ Grey if disabled
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        onPressed: disabled ? null : onPressed, // ✅ Disable button when needed
        child:
            isLoading
                ? SizedBox(
                  width: 20, // Smaller width
                  height: 20, // Smaller height
                  child: const CircularProgressIndicator(
                    strokeWidth: 2, // Thinner stroke width
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  text,
                  style: TextStyle(color: textColor, fontSize: 14.0),
                ),
      ),
    );
  }
}
