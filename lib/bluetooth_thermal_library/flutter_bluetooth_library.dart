import 'package:flutter/material.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PrintImageExample extends StatefulWidget {
  @override
  _PrintImageExampleState createState() => _PrintImageExampleState();
}

class _PrintImageExampleState extends State<PrintImageExample> {
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  String targetAddress = "60:6E:41:65:8C:04";
  @override
  void initState() {
    super.initState();
    connectToPrinter();
  }

  void connectToPrinter() async {
    List<BluetoothDevice> devices = await printer.getBondedDevices();
    // Find the device with the specified address
    BluetoothDevice? targetDevice = devices.firstWhere(
          (device) => device.address == targetAddress,
    );
    // If the device is found, connect to it
    if (targetDevice != null) {
      await printer.connect(targetDevice);
    } else {
      print("Device with address $targetAddress not found");
    }
  }

  Future<List<int>> prepareImageForPrint(img.Image image) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    img.Image resized = img.copyResize(image, width: 576);
    List<int> commands = [];
    commands += generator.imageRaster(resized, align: PosAlign.center);
    commands += generator.feed(2);

    return commands;
  }

  void printImage() async {
    img.Image image = img.decodeImage((await rootBundle.load('assets/payment_test.png')).buffer.asUint8List())!;
    List<int> imageData = await prepareImageForPrint(image);
    printer.writeBytes(Uint8List.fromList(imageData));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Print Image to Thermal Printer"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: printImage,
          child: Text("Print Image"),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: PrintImageExample(),
  ));
}
