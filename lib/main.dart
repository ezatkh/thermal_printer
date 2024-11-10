import 'package:flutter/material.dart';
import 'TSPL/tsplPrinterScreen.dart';
import 'blue_library/flutter_blue.dart';
import 'bluetooth_thermal_library/flutter_bluetooth_library.dart';
import 'flutter_bluetooth/flutter_bluetooth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth TSPL Printer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // home: TSPLPrinterScreen(), // Set TSPLPrinterScreen as the home
       home: PrintImageExample(),
    );
  }
}
