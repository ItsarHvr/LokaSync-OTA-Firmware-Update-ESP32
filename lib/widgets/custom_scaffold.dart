import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;

  const CustomScaffold({super.key, required this.body}); // Using super parameter for `key`

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/background.png'), // Replace with your background image
            fit: BoxFit.fitWidth
          ),
        ),
        child: body,
      ),
    );
  }
}