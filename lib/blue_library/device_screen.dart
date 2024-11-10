import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import '../bitmap.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late BluetoothDevice device;
  bool isConnected = false;


  @override
  void initState() {
    super.initState();
    device = widget.device;
    _connectToDevice();
  }

  void _connectToDevice() async {
    await device.connect();
    setState(() {
      isConnected = true;
    });
  }

  void _disconnectFromDevice() async {
    await device.disconnect();
    setState(() {
      isConnected = false;
    });
  }

  Future<void> printBitmapImage(BuildContext context) async {
    try {
      // Check if the device is already connected
      if (!isConnected) {
        await device.connect();
        setState(() {
          isConnected = true;
        });
      }

      // Load the image from assets
      img.Image? image = await ImageToEscPosConverter.loadAndCheckBmpImage('assets/temp.bmp');

      if (image == null) {
        _showMessage('Image loading or format check failed.');
        return;
      }

      // Load printer profile and setup ESC/POS generator
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);


      // Prepare bytes for printing
      final List<int> bytesToPrint = [
        ...generator.reset(),
        ...generator.imageRaster(image),
        ...generator.feed(2),
        ...generator.cut(),
      ];

      // Discover services after connecting
      List<BluetoothService> services = await device.discoverServices();

      // Find the correct characteristic for writing
      BluetoothCharacteristic? writeCharacteristic;
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            writeCharacteristic = characteristic;
            break;
          }
        }
        if (writeCharacteristic != null) break;
      }
      if (writeCharacteristic == null) {
        _showMessage('Write characteristic not found.');
        return;
      }
      // Send the print data to the printer
      await writeCharacteristic.write(bytesToPrint, withoutResponse: true);
      _showMessage('Image printed successfully!');
      print('Image printed successfully!');
    }
    catch (e) {
      _showMessage('Error during printing: $e');
      print('Error during printing: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (context, snapshot) {
              bool isConnected = snapshot.data == BluetoothDeviceState.connected;
              return Row(
                children: [
                  if (isConnected)
                    IconButton(
                      icon: Icon(Icons.image, color: Colors.black),
                      onPressed: () {
                        printBitmapImage(context); // Call printImage when button is pressed
                      },
                    ),
                  TextButton(
                    onPressed: () {
                      if (isConnected) {
                        _disconnectFromDevice();
                      } else {
                        _connectToDevice();
                      }
                    },
                    child: Text(
                      isConnected ? 'DISCONNECT' : 'CONNECT',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (context, snapshot) {
                return ListTile(
                  leading: Icon(snapshot.data == BluetoothDeviceState.connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled),
                  title: Text('Device is ${snapshot.data.toString().split('.')[1]}'),
                  subtitle: Text('${device.id}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
