import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';
import '../bitmap.dart';
import 'dart:async';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/material.dart';
import 'print_utils.dart';
import 'package:image/image.dart' as img;

class PrintPage extends StatefulWidget {
  @override
  _PrintPageState createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  BluetoothManager bluetoothManager = BluetoothManager.instance;
  late BluetoothDevice _device;
  bool _connected = false;
  String tips = 'no device connect';
  bool _isLoading = false;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isLoading = true;
    });

    bluetoothManager.startScan(timeout: Duration(seconds: 4));
    bool isConnected = await bluetoothManager.isConnected;
    bluetoothManager.state.listen((state) {
      print('cur device status: $state');

      switch (state) {
        case BluetoothManager.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothManager.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });
    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  void _onConnect() async {
    if (_device != null && _device.address != null) {
      await bluetoothManager.connect(_device);
    } else {
      setState(() {
        tips = 'please select device';
      });
      print('please select device');
    }
  }

  void _onDisconnect() async {
    await bluetoothManager.disconnect();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth"),
      ),
      body: RefreshIndicator(
        onRefresh: () => bluetoothManager.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Text(tips),
                  ),
                ],
              ),
              Divider(),
              StreamBuilder<List<BluetoothDevice>>(
                stream: bluetoothManager.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => ListTile(
                    title: Text(d.name ?? ''),
                    subtitle: Text(d.address!),
                    onTap: () async {
                      setState(() {
                        _device = d;
                      });
                    },
                    trailing: _device != null && _device.address == d.address
                        ? Icon(
                      Icons.check,
                      color: Colors.green,
                    )
                        : null,
                  ))
                      .toList(),
                ),
              ),
              Divider(),
              Container(
                padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        OutlinedButton(
                          child: Text('connect'),
                          onPressed: _connected ? null : _onConnect,
                        ),
                        SizedBox(width: 10.0),
                        OutlinedButton(
                          child: Text('disconnect'),
                          onPressed: _connected ? _onDisconnect : null,
                        ),
                      ],
                    ),
                    OutlinedButton(
                      child: Text('Send test data'),
                      onPressed: _connected ? _printReceiptJavaImage : null,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: bluetoothManager.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => bluetoothManager.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
              child: Icon(Icons.search),
              onPressed: () => bluetoothManager.startScan(timeout: Duration(seconds: 4)),
            );
          }
        },
      ),
    );
  }

  Future<void> _printReceiptJavaImage() async {
    setState(() {
      _isPrinting = true;
    });
    print("Connecting to the printer...");

    try {


      // Step 3: Image handling
      print("Loading and processing image...");
      // Load the image from assets
      img.Image? image = await ImageToEscPosConverter.loadImageFromAssets('assets/images/payment_test.png');

      if (image == null) {
        print('Image loading failed.');
      } else {

      }


    } catch (e) {
      print("Error during printing: $e");
      _showMessage('Error during printing: $e');
    } finally {
      setState(() {
        _isPrinting = false; // Reset the printing state
      });
    }
  }
}
