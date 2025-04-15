import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              height: 100,
              width: 100,
              color: Colors.red,
            ),
            const Text(
              'LokaSync',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
        ],)
      )
    );
  }
}