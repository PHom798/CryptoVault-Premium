import 'package:flutter/material.dart';
import 'screens/wallet_dashboard.dart';  // ⭐ IMPORT THIS

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: WalletDashboard(),  // ⭐ YOUR MAIN SCREEN
    );
  }
}