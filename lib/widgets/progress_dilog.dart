import 'package:flutter/material.dart';

class ProgressDilog extends StatelessWidget {
  String? message;
  ProgressDilog({super.key, this.message});
  @override
  Widget build(BuildContext context) {
    return Dialog(
backgroundColor: Colors.black,
child: Container(
  margin: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Row(
    children: [
      const SizedBox(width: 26),
      const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
      ),
      const SizedBox(width: 26),
      Text(
        message!,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
      ),
    ],
  ),
),
    );
  }
}
