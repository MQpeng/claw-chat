import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/connection_provider.dart';

class ChannelInfo {
  final String key;
  final String label;
  final String type;
  final bool enabled;
  final Map<String, dynamic> config;

  ChannelInfo({
    required this.key,
    required this.label,
    required this.type,
    required this.enabled,
    required this.config,
  });

  factory ChannelInfo.fromJson(Map<dynamic, dynamic> json) {
    return ChannelInfo(
      key: json['key'] as String,
      label: json['label'] as String? ?? json['key'],
      type: json['type'] as String? ?? 'unknown',
      enabled: json['enabled'] as bool? ?? true,
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
    );
  }
}

final channelsProvider = FutureProvider<List<ChannelInfo>>((ref) async {
  final connection = ref.watch(connectionProvider);
  if (!connection.isConnected) {
    return [];
  }

  try {
    final client = ref.read(connectionProvider.notifier).client;
    final result = await client.request('channels.list', {});
    List channels = [];
    if (result is Map && result.containsKey('result')) {
      channels = result['result'] as List;
    } else if (result is List) {
      channels = result;
    }

    return channels
        .map((item) => ChannelInfo.fromJson(item as Map<dynamic, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

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
    final channelsAsync = ref.watch(channelsProvider);
    final connection = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.channels),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Scan QR code to add new channel
              final hasPermission = await _requestCameraPermission();
              if (!hasPermission) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                      content: Text(l10n.cameraPermissionDenied),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              if (context.mounted) {
                final qrData = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QrScannerPage(),
                  ),
                );
                if (qrData != null && qrData.isNotEmpty) {
                  _processQrData(qrData);
                }
              }
            },
            tooltip: l10n.addChannel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(channelsProvider);
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: !connection.isConnected
          ? Center(
              child: Text(l10n.notConnected),
            )
          : channelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('${l10n.error}: $error'),
              ),
              data: (channels) {
                if (channels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                         Text(l10n.noChannelsConfigured, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                         Text(l10n.addChannelHint),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final hasPermission = await _requestCameraPermission();
                            if (!hasPermission) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                    content: Text(l10n.cameraPermissionDenied),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }
                            if (context.mounted) {
                              final qrData = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const QrScannerPage(),
                                ),
                              );
                              if (qrData != null && qrData.isNotEmpty) {
                                _processQrData(qrData);
                              }
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(l10n.scanQrCode),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: channel.enabled
                              ? Colors.green
                              : Colors.grey,
                          child: Icon(
                            _getChannelIcon(channel.type),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(channel.label),
                        subtitle: Text('${channel.type} • ${channel.key}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: channel.enabled,
                              onChanged: (value) async {
                                await _toggleChannel(channel.key, value);
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  await _deleteChannel(channel.key);
                                } else if (value == 'edit') {
                                  // TODO: Edit channel
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(content: Text(l10n.comingSoon)),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(l10n.edit),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  textStyle: const TextStyle(color: Colors.red),
                                  child: Text(l10n.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: View channel details/test
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

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  void _processQrData(String data) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // QR format: openclaw://channel/{json}
      String jsonStr = data;
      if (data.startsWith('openclaw://channel/')) {
        jsonStr = data.substring('openclaw://channel/'.length);
      } else if (data.startsWith('oc://c/')) {
        jsonStr = data.substring('oc://c/'.length);
      }

      final configJson = jsonDecode(jsonStr) as Map<String, dynamic>;
      final client = ref.read(connectionProvider.notifier).client;
      
      final result = await client.request('channels.add', configJson);
      
      if (context.mounted) {
        if (result is Map && result.containsKey('result') && result['result']['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(l10n.channelAdded),
              backgroundColor: Colors.green,
            ),
          );
          ref.refresh(channelsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(l10n.channelAddFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('${l10n.channelAddFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleChannel(String key, bool enabled) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final client = ref.read(connectionProvider.notifier).client;
      final result = await client.request('channels.set', {
        'key': key,
        'enabled': enabled,
      });
      
      if (context.mounted) {
        if (result is Map && result.containsKey('result') && result['result']['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(l10n.channelUpdated),
              backgroundColor: Colors.green,
            ),
          );
          ref.refresh(channelsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(l10n.channelUpdateFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('${l10n.channelUpdateFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteChannel(String key) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteChannel),
        content: Text(l10n.deleteChannelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final client = ref.read(connectionProvider.notifier).client;
      final result = await client.request('channels.delete', {
        'key': key,
      });
      
      if (context.mounted) {
        if (result is Map && result.containsKey('result') && result['result']['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(l10n.channelDeleted),
              backgroundColor: Colors.green,
            ),
          );
          ref.refresh(channelsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(l10n.channelDeleteFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('${l10n.channelDeleteFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getChannelIcon(String type) {
    switch (type.toLowerCase()) {
      case 'discord':
        return Icons.discord;
      case 'telegram':
        return Icons.send;
      case 'signal':
        return Icons.chat_bubble;
      case 'slack':
        return Icons.workspaces;
      case 'webhook':
        return Icons.webhook;
      default:
        return Icons.message;
    }
  }
}

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanQrCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
              controller.stop();
              if (mounted) {
                Navigator.pop(context, barcode.rawValue);
              }
              break;
            }
          }
        },
      ),
    );
  }
}
