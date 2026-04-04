import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../providers/connection_provider.dart';

class CronJobInfo {
  final String id;
  final String name;
  final String schedule;
  final bool enabled;
  final String? lastRun;
  final String? nextRun;

  CronJobInfo({
    required this.id,
    required this.name,
    required this.schedule,
    required this.enabled,
    this.lastRun,
    this.nextRun,
  });

  factory CronJobInfo.fromJson(Map json) {
    return CronJobInfo(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'],
      schedule: json['schedule'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      lastRun: json['lastRun'] as String?,
      nextRun: json['nextRun'] as String?,
    );
  }
}

final cronJobsProvider = FutureProvider<List<CronJobInfo>>((ref) async {
  final connection = ref.watch(connectionProvider);
  if (!connection.isConnected) {
    return [];
  }

  try {
    final client = ref.read(connectionProvider.notifier).client;
    final result = await client.request('cron.list', {});
    List jobs = [];
    if (result is Map && result.containsKey('result')) {
      jobs = result['result'] as List;
    } else if (result is List) {
      jobs = result;
    }

    return jobs.map((item) => CronJobInfo.fromJson(item)).toList();
  } catch (e) {
    return [];
  }
});

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
    final jobsAsync = ref.watch(cronJobsProvider);
    final connection = ref.watch(connectionProvider);

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
            tooltip: l10n.createJob,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(cronJobsProvider);
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: !connection.isConnected
          ? Center(
              child: Text(l10n.notConnected),
            )
          : jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('${l10n.error}: $error'),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                         Text(l10n.noCronJobs, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                         Text(l10n.noCronJobsHint),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: job.enabled ? Colors.green : Colors.grey,
                          child: Icon(
                            Icons.schedule,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(job.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l10n.schedule}: ${job.schedule}'),
                            if (job.nextRun != null)
                              Text('${l10n.nextRun}: ${job.nextRun}'),
                            if (job.lastRun != null)
                              Text('${l10n.lastRun}: ${job.lastRun}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: job.enabled,
                              onChanged: (value) {
                                // TODO: Toggle enabled
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(l10n.comingSoon)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                // TODO: Edit/Delete/Run now
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(l10n.comingSoon)),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: Edit job
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(l10n.comingSoon)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
