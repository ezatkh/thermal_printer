import 'package:flutter/material.dart';
import '../bitmap.dart';
import 'tsplPrinter.dart'; // Import the TSPLPrinter class
import 'dart:ui' as ui;
import 'package:image/image.dart' as img; // For image manipulation

class TSPLPrinterScreen extends StatelessWidget {
  final TSPLPrinter printerService = TSPLPrinter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth TSPL Printer"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Replace with your printer's address
                String printerAddress = "60:6E:41:65:8C:04";

                // Create an instance of TSPLPrinter
                TSPLPrinter printerService = TSPLPrinter();

                try {
                  // Connect to the printer
                  await printerService.connect(printerAddress);
                  await printerService.printImage();
                }
                catch (e) {
                  print("Error: $e"); // Handle any errors that occur during connection or printing
                } finally {
                 //  printerService.disconnect();
                }
              },

              child: Text("Print Image"),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     String printerAddress = "60:6E:41:65:8C:04"; // Replace with your printer's address
            //     await printerService.connect(printerAddress);
            //     await printerService.printImage2('assets/temp.bmp');
            //   },
            //   child: Text("Print Image"),
            // ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String printerAddress = "60:6E:41:65:8C:04"; // Replace with your printer's address
                await printerService.connect(printerAddress);
                await printerService.printTestText();
              },
              child: Text("Print Hello World"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                printerService.disconnect();
              },
              child: Text("Disconnect"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Set button color to red for emphasis
              ),
            ),
          ],
        ),
      ),
    );
  }
}
