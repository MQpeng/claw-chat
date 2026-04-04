import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

class ChannelsPage extends ConsumerStatefulWidget {
  const ChannelsPage({super.key});

  @override
  ConsumerState<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends ConsumerState<ChannelsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // TODO: Fetch channels from gateway API
    // For now, show placeholder with "coming soon"
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.channels),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new channel (scan QR)
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.comingSoon)),
              );
            },
            tooltip: l10n.addChannel,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
             Text(l10n.channels, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
             Text(l10n.comingSoon),
          ],
        ),
      ),
    );
  }
}
