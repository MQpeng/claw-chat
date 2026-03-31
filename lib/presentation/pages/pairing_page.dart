import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        constraints: BoxConstraints(
          minHeight: screenHeight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(10),
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
                const SizedBox(height: 16),
                 Text(
                  l10n.connectToOpenClaw,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                 Text(
                  l10n.enterGatewayUrlAndTokenManually,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: _isTesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
