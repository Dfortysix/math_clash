import 'package:flutter/material.dart';

class PvPGameScreen extends StatelessWidget {
  final String roomId;
  const PvPGameScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PvP Game'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('PvP Game Screen\nRoom ID: $roomId', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
} 