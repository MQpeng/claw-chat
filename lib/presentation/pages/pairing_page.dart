import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_config.dart';
import '../providers/connection_provider.dart';

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
    final connection = ref.watch(connectionProvider);
    if (connection.config != null) {
      setState(() {
        _gatewayUrlController.text = connection.config!.gatewayUrl;
        _tokenController.text = connection.config!.token;
      });
    }
  }

  void _startScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.scanQRCode),
          ),
          body: MobileScanner(
            onDetect: _onQrScanned,
          ),
        ),
      ),
    );
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
      });

      Navigator.of(context).pop();
      _testAndConnect();
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.invalidQRCodeFormat;
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
        _errorMessage = AppLocalizations.of(context)!.pleaseFillInBothGatewayURLAndToken;
        _isTesting = false;
      });
      return;
    }

    // Save config via connection provider
    final config = AppConfig(gatewayUrl: gatewayUrl, token: token);
    await ref.read(connectionProvider.notifier).saveConfig(config);

    setState(() {
      _isTesting = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(AppLocalizations.of(context)!.configurationSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [
                    Colors.blue.withOpacity(0.02),
                    Colors.blue.withOpacity(0.05),
                  ]
                : [
                    Colors.blue.withOpacity(0.05),
                    Colors.transparent,
                  ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/openclaw_logo.svg',
                    colorFilter: ColorFilter.mode(theme.colorScheme.primary, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(height: 24),
               Text(
                l10n.connectToOpenClaw,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
               Text(
                l10n.scanQRCodeFromOpenClawWebUI,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _startScan,
                        icon: const Icon(Icons.qr_code_scanner),
                         label: Text(l10n.scanQRCode),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                       Text(
                        l10n.manualConfiguration,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                       TextField(
                        controller: _gatewayUrlController,
                        decoration:  InputDecoration(
                          labelText: l10n.gatewayURL,
                          hintText: 'https://your-gateway.example.com',
                          prefixIcon: const Icon(Icons.link),
                        ),
                          keyboardType: TextInputType.url,
                          textCapitalization: TextCapitalization.none,
                      ),
                      const SizedBox(height: 16),
                       TextField(
                        controller: _tokenController,
                        decoration:  InputDecoration(
                          labelText: l10n.token,
                          hintText: l10n.yourPairingToken,
                          prefixIcon: const Icon(Icons.key),
                        ),
                          obscureText: true,
                          textCapitalization: TextCapitalization.none,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                                fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isTesting ? null : _testAndConnect,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                          child: _isTesting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              :  Text(l10n.saveAndConnect),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
