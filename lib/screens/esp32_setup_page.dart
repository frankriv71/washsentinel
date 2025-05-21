// lib/screens/esp32_setup_page.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ESP32SetupPage extends StatefulWidget {
  @override
  _ESP32SetupPageState createState() => _ESP32SetupPageState();
}

class _ESP32SetupPageState extends State<ESP32SetupPage> {
  // 1) BLE
  final _ble = FlutterReactiveBle();
  final _serviceUUID = Uuid.parse("12345678-1234-5678-1234-56789abcdef0");
  final _ssidUUID    = Uuid.parse("11111111-1111-1111-1111-111111111111");
  final _passUUID    = Uuid.parse("22222222-2222-2222-2222-222222222222");

  StreamSubscription<DiscoveredDevice>? _scanSub;
  DiscoveredDevice? _device;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  QualifiedCharacteristic? _ssidChar;
  QualifiedCharacteristic? _passChar;

  // 2) Wi-Fi form
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _scanning  = false;
  bool _connecting = false;
  bool _connected = false;

  // 3) QR Scanner
  final _qrKey = GlobalKey(debugLabel: 'QR');
  bool _scanningQr = false;

  @override
  void initState() {
    super.initState();
    _autoDetectSSID();
    _startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _autoDetectSSID() async {
    try {
      final name = await WifiInfo().getWifiName();
      if (name != null && mounted) {
        setState(() => _ssidCtrl.text = name.replaceAll('"', ''));
      }
    } catch (_) {
      // ignore
    }
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _scanSub?.cancel();
      _scanSub = _ble
          .scanForDevices(withServices: [_serviceUUID], scanMode: ScanMode.lowLatency)
          .listen((device) {
        if (device.name == "WashSentinel" && mounted && _device == null) {
          _device = device;
          _connectToDevice();
        }
      }, onError: (e) {
        // scan error
      }, onDone: () {
        if (mounted) setState(() => _scanning = false);
      });
    });
  }

  void _connectToDevice() {
    if (_device == null) return;
    setState(() => _connecting = true);

    _connSub = _ble
        .connectToDevice(
      id: _device!.id,
      connectionTimeout: const Duration(seconds: 5),
    )
        .listen((state) async {
      if (state.connectionState == DeviceConnectionState.connected) {
        final services = await _ble.discoverServices(_device!.id);
        for (final s in services) {
          if (s.serviceId == _serviceUUID) {
            for (final c in s.characteristics) {
              if (c.characteristicId == _ssidUUID) {
                _ssidChar = QualifiedCharacteristic(
                  serviceId: _serviceUUID,
                  characteristicId: _ssidUUID,
                  deviceId: _device!.id,
                );
              }
              if (c.characteristicId == _passUUID) {
                _passChar = QualifiedCharacteristic(
                  serviceId: _serviceUUID,
                  characteristicId: _passUUID,
                  deviceId: _device!.id,
                );
              }
            }
          }
        }
        setState(() {
          _connecting = false;
          _connected = true;
        });
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        setState(() {
          _connected = false;
          _connecting = false;
          // you could retry or go back to scanning
        });
      }
    }, onError: (e) {
      setState(() {
        _connecting = false;
        _connected  = false;
      });
    });
  }

  Future<void> _scanQr() async {
    setState(() => _scanningQr = true);
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _QRScannerScreen(key: _qrKey)),
    );
    setState(() => _scanningQr = false);
    if (result != null) {
      // expect WIFI:S:<ssid>;T:WPA;P:<pass>;;
      final match = RegExp(r'WIFI:S:([^;]+);.*P:([^;]+);;').firstMatch(result);
      if (match != null) {
        setState(() {
          _ssidCtrl.text = match.group(1)!;
          _passCtrl.text = match.group(2)!;
        });
      }
    }
  }

  Future<void> _sendCredentials() async {
    if (!_connected || _ssidChar == null || _passChar == null) return;
    final ssidBytes = utf8.encode(_ssidCtrl.text);
    final passBytes = utf8.encode(_passCtrl.text);
    try {
      await _ble.writeCharacteristicWithResponse(_ssidChar!, value: ssidBytes);
      await Future.delayed(Duration(milliseconds: 200));
      await _ble.writeCharacteristicWithResponse(_passChar!, value: passBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Credentials sent!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending credentials: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) still scanning for device
    if (!_connected) {
      return Scaffold(
        appBar: AppBar(title: Text("Pair ESP32 via BLE")),
        body: Center(
          child: _scanning || _connecting
              ? CircularProgressIndicator()
              : Text("Searching for ESP32…"),
        ),
        floatingActionButton: !_scanning
            ? FloatingActionButton(
          child: Icon(Icons.refresh),
          onPressed: _startScan,
        )
            : null,
      );
    }

    // 2) connected → show form
    return Scaffold(
      appBar: AppBar(title: Text("Send Wi-Fi Credentials")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ssidCtrl,
              decoration: InputDecoration(labelText: "Wi-Fi SSID"),
            ),
            TextField(
              controller: _passCtrl,
              decoration: InputDecoration(labelText: "Wi-Fi Password"),
              obscureText: true,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.qr_code_scanner),
                  label: Text("Scan QR"),
                  onPressed: _scanningQr ? null : _scanQr,
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  child: Text("Send to ESP32"),
                  onPressed: _sendCredentials,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple full-screen QR scanner using qr_code_scanner
class _QRScannerScreen extends StatelessWidget {
  const _QRScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRView(
        key: key!,
        onQRViewCreated: (ctrl) {
          ctrl.scannedDataStream.listen((scan) {
            ctrl.pauseCamera();
            Navigator.pop(context, scan.code);
          });
        },
      ),
    );
  }
}
