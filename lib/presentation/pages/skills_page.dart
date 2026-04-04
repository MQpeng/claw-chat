import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../providers/connection_provider.dart';

class SkillsPage extends ConsumerStatefulWidget {
  const SkillsPage({super.key});

  @override
  ConsumerState<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends ConsumerState<SkillsPage> {
  bool _loading = false;
  Map<String, dynamic>? _skillsStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSkillsStatus();
    });
  }

  Future<void> _loadSkillsStatus() async {
    final connection = ref.watch(connectionProvider);
    if (!connection.isConnected) {
      setState(() {
        _error = AppLocalizations.of(context)!.notConnected;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = connection.client;
      final result = await client.request('skills.status');
      setState(() {
        _skillsStatus = result as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connection = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.skills),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSkillsStatus,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSkillsStatus,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_skillsStatus == null) {
      return Center(child: Text(l10n.noData));
    }

    final skills = _skillsStatus!['skills'] as List<dynamic>? ?? [];

    if (skills.isEmpty) {
      return Center(
        child: Text(l10n.noData),
      );
    }

    return ListView.builder(
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index] as Map<String, dynamic>;
        final id = skill['id'] as String? ?? '';
        final name = skill['name'] as String? ?? id;
        final description = skill['description'] as String? ?? '';
        final enabled = skill['enabled'] as bool? ?? false;
        final version = skill['version'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(name),
            subtitle: description.isNotEmpty
                ? Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            leading: Icon(
              enabled ? Icons.check_circle : Icons.cancel,
              color: enabled ? Colors.green : Colors.grey,
            ),
            trailing: version.isNotEmpty
                ? Text(
                    version,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                  )
                : null,
            onTap: () {
              // TODO: Open skill detail page
            },
          ),
        );
      },
    );
  }
}
