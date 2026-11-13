import 'package:flutter/material.dart';

void main() => runApp(const StartupEngineTestApp());

class StartupEngineTestApp extends StatelessWidget {
  const StartupEngineTestApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF1565C0),
      body: SafeArea(
        child: Center(
          child: Text(
            'EVERYWEAR ENGINE TEST',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
