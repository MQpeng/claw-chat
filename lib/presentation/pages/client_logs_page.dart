import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ClientLogsPage extends StatefulWidget {
  const ClientLogsPage({super.key});

  @override
  State<ClientLogsPage> createState() => _ClientLogsPageState();
}

class _ClientLogsPageState extends State<ClientLogsPage> {
  final List<String> _logs = [];
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    // For now, we'll capture print output
    // In future we can implement persistent logging
    setState(() {
      _logs.clear();
    });
  }

  void _scrollToBottom() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearLogs() async {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _copyLogs() async {
    final text = _logs.join('\n');
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Logs'),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll ? 'Pause auto-scroll' : 'Resume auto-scroll',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _logs.isEmpty ? null : _copyLogs,
            tooltip: 'Copy all logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _logs.isEmpty ? null : _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bug_report_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text('No logs yet'),
                  const SizedBox(height: 8),
                  const Text('Logs will appear here when app runs'),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: SelectableText(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
