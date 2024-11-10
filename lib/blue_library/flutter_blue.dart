import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'device_screen.dart'; // Import the DeviceScreen from another file

class BluetoothScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Devices'),
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Start scanning for devices
              FlutterBlue.instance.startScan(timeout: Duration(seconds: 4));
            },
          ),
        ],
      ),
      body: StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state == BluetoothState.on) {
            return DeviceListScreen();
          }
          return BluetoothOffScreen(state: state);
        },
      ),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  final BluetoothState? state;

  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_disabled, size: 200.0, color: Colors.grey),
          Text(
            'Bluetooth is ${state != null ? state.toString().split('.')[1] : 'not available'}.',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class DeviceListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _connectedDevices(),
            Divider(),
            _scannedDevices(context),
          ],
        ),
      ),
    );
  }

  Widget _connectedDevices() {
    return StreamBuilder<List<BluetoothDevice>>(
      stream: Stream.periodic(Duration(seconds: 2)).asyncMap((_) => FlutterBlue.instance.connectedDevices),
      initialData: [],
      builder: (context, snapshot) {
        return Column(
          children: snapshot.data!.map((device) {
            return ListTile(
              title: Text(device.name.isEmpty ? 'Unnamed Device' : device.name), // Handle unnamed devices
              subtitle: Text(device.id.toString()),
              trailing: StreamBuilder<BluetoothDeviceState>(
                stream: device.state,
                initialData: BluetoothDeviceState.disconnected,
                builder: (context, snapshot) {
                  return ElevatedButton(
                    child: Text('DISCONNECT'),
                    onPressed: () {
                      if (snapshot.data == BluetoothDeviceState.connected) {
                        device.disconnect();
                      }
                    },
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _scannedDevices(BuildContext context) {
    return StreamBuilder<List<ScanResult>>(
      stream: FlutterBlue.instance.scanResults,
      initialData: [],
      builder: (context, snapshot) {
        // Use a Set to keep track of unique device IDs
        Set<String> uniqueDeviceIds = {};

        // Filter out scanned devices to ensure uniqueness and non-empty names
        List<ScanResult> uniqueResults = snapshot.data!.where((result) {
          String deviceId = result.device.id.toString();
          if (result.device.name.isNotEmpty && !uniqueDeviceIds.contains(deviceId)) {
            uniqueDeviceIds.add(deviceId);
            return true; // Include this device
          }
          return false; // Exclude this duplicate device or device without a name
        }).toList();

        return Column(
          children: uniqueResults.map((result) {
            return InkWell(
              onTap: () {
                // Navigate to DeviceScreen when tapping the ListTile
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DeviceScreen(device: result.device), // Use result.device here
                  ),
                );
              },
              child: ListTile(
                title: Text(result.device.name),
                subtitle: Text(result.device.id.toString()),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
