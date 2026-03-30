import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/constants/app_config.dart';

class PairingPage extends ConsumerStatefulWidget {
  const PairingPage({super.key});

  @override
  ConsumerState<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends ConsumerState<PairingPage> {
  bool _isScanning = false;
  final _gatewayUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isTesting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('app_config');
    if (configJson != null) {
      try {
        final config = AppConfig.fromJson(json.decode(configJson));
        setState(() {
          _gatewayUrlController.text = config.gatewayUrl;
          _tokenController.text = config.token;
        });
        // Auto test connection if config exists
        _testAndConnect();
      } catch (e) {
        // Invalid config, ignore
      }
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });
  }

  void _onQrScanned(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) return;

    try {
      final decoded = json.decode(rawValue);
      final url = decoded['url'] as String;
      final token = decoded['token'] as String;

      setState(() {
        _gatewayUrlController.text = url;
        _tokenController.text = token;
        _isScanning = false;
      });

      _testAndConnect();
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid QR code format';
      });
    }
  }

  Future<void> _testAndConnect() async {
    setState(() {
      _isTesting = true;
      _errorMessage = null;
    });

    final gatewayUrl = _gatewayUrlController.text.trim();
    final token = _tokenController.text.trim();

    if (gatewayUrl.isEmpty || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in both Gateway URL and Token';
        _isTesting = false;
      });
      return;
    }

    // Save config
    final config = AppConfig(gatewayUrl: gatewayUrl, token: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_config', json.encode(config.toJson()));

    // TODO: Implement actual connection test
    // For now, just save and navigate to chat page
    setState(() {
      _isTesting = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isScanning = false;
              });
            },
          ),
        ),
        body: MobileScanner(
          onDetect: _onQrScanned,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('claw-chat'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Connect to OpenClaw',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan QR code from OpenClaw Web UI or enter configuration manually',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Manual Configuration'),
            const SizedBox(height: 8),
            TextField(
              controller: _gatewayUrlController,
              decoration: const InputDecoration(
                labelText: 'Gateway URL',
                hintText: 'https://your-gateway.example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Token',
                hintText: 'Your pairing token',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isTesting ? null : _testAndConnect,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isTesting
                  ? const CircularProgressIndicator()
                  : const Text('Save & Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
