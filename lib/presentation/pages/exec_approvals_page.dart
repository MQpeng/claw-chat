import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../providers/connection_provider.dart';

class AllowRule {
  final String id;
  final String pattern;
  final bool allowed;
  final String? description;

  AllowRule({
    required this.id,
    required this.pattern,
    required this.allowed,
    this.description,
  });

  factory AllowRule.fromJson(Map json) {
    return AllowRule(
      id: json['id'] as String,
      pattern: json['pattern'] as String,
      allowed: json['allowed'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }
}

final execAllowlistProvider = FutureProvider<List<AllowRule>>((ref) async {
  final connection = ref.watch(connectionProvider);
  if (!connection.isConnected) {
    return [];
  }

  try {
    final client = ref.read(connectionProvider.notifier).client;
    final result = await client.request('exec.allowlist.list', {});
    List rules = [];
    if (result is Map && result.containsKey('result')) {
      rules = result['result'] as List;
    } else if (result is List) {
      rules = result;
    }

    return rules.map((item) => AllowRule.fromJson(item)).toList();
  } catch (e) {
    return [];
  }
});

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
    final rulesAsync = ref.watch(execAllowlistProvider);
    final connection = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exec),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new allow rule
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.comingSoon)),
              );
            },
            tooltip: l10n.addRule,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(execAllowlistProvider);
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: !connection.isConnected
          ? Center(
              child: Text(l10n.notConnected),
            )
          : rulesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('${l10n.error}: $error'),
              ),
              data: (rules) {
                if (rules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.terminal_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                         Text(l10n.noExecRules, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                         Text(l10n.noExecRulesHint),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: rules.length,
                  itemBuilder: (context, index) {
                    final rule = rules[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rule.allowed ? Colors.green : Colors.red,
                          child: Icon(
                            rule.allowed ? Icons.check : Icons.block,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(rule.pattern),
                        subtitle: rule.description != null
                            ? Text(rule.description!)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: rule.allowed,
                              onChanged: (value) {
                                // TODO: Toggle allowed
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(l10n.comingSoon)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                // TODO: Edit/Delete rule
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(l10n.comingSoon)),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: Edit rule
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
