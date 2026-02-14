import 'package:flutter/material.dart';

class NeonButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const NeonButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.color = const Color(0xFF00F2EA), // Cyan default
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 15),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
