import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../providers/connection_provider.dart';

class DebugPage extends ConsumerStatefulWidget {
  const DebugPage({super.key});

  @override
  ConsumerState<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends ConsumerState<DebugPage> {
  final TextEditingController _methodController = TextEditingController();
  final TextEditingController _paramsController = TextEditingController();
  bool _loading = false;
  String _result = '';

  Future<void> _sendRequest() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final method = _methodController.text.trim();
      if (method.isEmpty) {
        setState(() {
          _result = 'Error: method name is empty';
          _loading = false;
        });
        return;
      }

      Map<String, dynamic> params = {};
      final paramsText = _paramsController.text.trim();
      if (paramsText.isNotEmpty) {
        params = jsonDecode(paramsText) as Map<String, dynamic>;
      }

      final connection = ref.read(connectionProvider);
      final client = ref.read(connectionProvider.notifier).client;
      final result = await client.request(method, params);

      setState(() {
        _result = const JsonEncoder.withIndent('  ').convert(result);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final connection = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debug),
      ),
      body: !connection.isConnected
          ? Center(
              child: Text(l10n.notConnected),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.debugManualRequest,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _methodController,
                    decoration: InputDecoration(
                      labelText: l10n.methodName,
                      border: const OutlineInputBorder(),
                      hintText: 'sessions.list',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _paramsController,
                    decoration: InputDecoration(
                      labelText: l10n.paramsJson,
                      border: const OutlineInputBorder(),
                      hintText: '{}',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendRequest,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Text(l10n.sendRequest),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.response,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _result,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
