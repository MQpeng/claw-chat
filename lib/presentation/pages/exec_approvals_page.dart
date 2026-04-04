import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

class ExecApprovalsPage extends ConsumerStatefulWidget {
  const ExecApprovalsPage({super.key});

  @override
  ConsumerState<ExecApprovalsPage> createState() => _ExecApprovalsPageState();
}

class _ExecApprovalsPageState extends ConsumerState<ExecApprovalsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // TODO: Fetch and edit allowlist from gateway API
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exec),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terminal_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
             Text(l10n.exec, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
             Text(l10n.comingSoon),
          ],
        ),
      ),
    );
  }
}
