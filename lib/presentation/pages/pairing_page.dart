import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../../core/constants/app_config.dart';
import '../providers/connection_provider.dart';
import '../../../l10n/app_localizations.dart';

class PairingPage extends ConsumerStatefulWidget {
  const PairingPage({super.key});

  @override
  ConsumerState<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends ConsumerState<PairingPage> {
  final _gatewayUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isTesting = false;
  String? _errorMessage;
  bool _isScanning = false;
  bool _showToken = false;

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

  void _startQrScan() {
    setState(() {
      _isScanning = true;
    });
  }

  void _handleQrScan(String? qrText) {
    if (qrText == null) return;

    try {
      // Try to parse as JSON
      final data = json.decode(qrText) as Map<String, dynamic>;
      if (data.containsKey('gatewayUrl') && data.containsKey('token')) {
        setState(() {
          _gatewayUrlController.text = data['gatewayUrl'] as String;
          _tokenController.text = data['token'] as String;
          _isScanning = false;
        });
        return;
      }
    } catch (_) {
      // Not JSON, try to parse as URL with token fragment
      // Format: https://gateway.example.com#token_here
      final uri = Uri.tryParse(qrText);
      if (uri != null && uri.fragment.isNotEmpty) {
        setState(() {
          _gatewayUrlController.text = uri.replace(fragment: '').toString();
          _tokenController.text = uri.fragment;
          _isScanning = false;
        });
        return;
      }
    }

    // Invalid QR code
    setState(() {
      _errorMessage = AppLocalizations.of(context)!.invalidQrCode;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.scanQrCode),
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
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final barcode = barcodes.first;
              _handleQrScan(barcode.rawValue);
            }
          },
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark
          ? Colors.black
          : Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withOpacity(0.08),
                    colorScheme.primary.withOpacity(0.02),
                    Colors.grey[50]!,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width > 600 ? 32 : 24,
                vertical: 40,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo & Header
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.primary.withOpacity(0.15)
                            : colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: SvgPicture.asset(
                        'assets/images/openclaw_logo.svg',
                        colorFilter: ColorFilter.mode(
                          isDark ? colorScheme.primary : Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'OpenClaw',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.connectToOpenClaw,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.white70
                            : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // QR Scan Button
                    OutlinedButton.icon(
                      onPressed: _startQrScan,
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      label: Text(l10n.scanQRCode),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider with "OR"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n.or,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Manual Configuration Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surface
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                        border: isDark
                            ? Border.all(color: Colors.grey[800]!)
                            : null,
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.manualConfiguration,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Gateway URL Field
                          TextField(
                            controller: _gatewayUrlController,
                            decoration: InputDecoration(
                              labelText: l10n.gatewayURL,
                              hintText: 'https://your-gateway.example.com',
                              prefixIcon: Icon(
                                Icons.link,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey[900]
                                  : colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            keyboardType: TextInputType.url,
                            textCapitalization: TextCapitalization.none,
                            autocorrect: false,
                            onSubmitted: (_) => _testAndConnect(),
                          ),
                          const SizedBox(height: 16),

                          // Token Field with show/hide toggle
                          TextField(
                            controller: _tokenController,
                            decoration: InputDecoration(
                              labelText: l10n.token,
                              hintText: l10n.yourPairingToken,
                              prefixIcon: Icon(
                                Icons.key,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey[900]
                                  : colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showToken ? Icons.visibility_off : Icons.visibility,
                                ),
                                tooltip: _showToken
                                    ? l10n.hideToken
                                    : l10n.showToken,
                                onPressed: () {
                                  setState(() {
                                    _showToken = !_showToken;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_showToken,
                            textCapitalization: TextCapitalization.none,
                            autocorrect: false,
                            onSubmitted: (_) => _testAndConnect(),
                          ),

                          // Error Message
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Connect Button
                          FilledButton(
                            onPressed: _isTesting ? null : _testAndConnect,
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: isDark ? 0 : 2,
                            ),
                            child: _isTesting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(l10n.saveAndConnect),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
