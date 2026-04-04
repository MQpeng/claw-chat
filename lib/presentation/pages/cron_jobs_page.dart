import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

class CronJobsPage extends ConsumerStatefulWidget {
  const CronJobsPage({super.key});

  @override
  ConsumerState<CronJobsPage> createState() => _CronJobsPageState();
}

class _CronJobsPageState extends ConsumerState<CronJobsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // TODO: Fetch cron jobs from gateway API
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cronJobs),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Create new cron job
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.comingSoon)),
              );
            },
            tooltip: l10n.get('createJob') ?? 'Create Job',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
             Text(l10n.cronJobs, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
             Text(l10n.comingSoon),
          ],
        ),
      ),
    );
  }
}

extension on AppLocalizations {
  String get(String key) {
    return key;
  }
}
