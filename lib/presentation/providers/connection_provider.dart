import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/constants/app_config.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import 'session_provider.dart';

final connectionProvider = NotifierProvider<ConnectionNotifier, ConnectionState>(ConnectionNotifier.new);

enum ConnectionStatus {
  loading,
  disconnected,
  connecting,
  connected,
  error,
}

class ConnectionState {
  final ConnectionStatus status;
  final String? errorMessage;
  final AppConfig? config;

  ConnectionState({
    required this.status,
    this.errorMessage,
    this.config,
  });

  bool get isConnected => status == ConnectionStatus.connected;

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? errorMessage,
    AppConfig? config,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      config: config ?? this.config,
    );
  }
}

class ConnectionNotifier extends Notifier<ConnectionState> {
  final OpenClawClient _client = OpenClawClient();

  @override
  ConnectionState build() {
    // Start with loading state while loading saved config
    // Load saved config async and update state when done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadSavedConfig();
    });
    return ConnectionState(
      status: ConnectionStatus.loading,
    );
  }

  Future<void> saveConfig(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_config', json.encode(config.toJson()));
    _client.setConfig(config);
    state = state.copyWith(config: config);
    await connect();
  }

  Future<void> loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('app_config');
    if (configJson != null) {
      try {
        final config = AppConfig.fromJson(json.decode(configJson));
        _client.setConfig(config);
        state = state.copyWith(
          config: config,
          status: ConnectionStatus.disconnected,
        );
        await connect();
      } catch (e) {
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: 'Invalid saved configuration',
        );
      }
    } else {
      // No config saved, stay disconnected
      state = state.copyWith(
        status: ConnectionStatus.disconnected,
      );
    }
  }

  Future<bool> connect() async {
    if (state.config == null) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: 'No configuration',
      );
      return false;
    }

    state = state.copyWith(status: ConnectionStatus.connecting);
    _client.setConfig(state.config!);

    try {
      final result = await _client.testConnection();
      if (result.success) {
        state = state.copyWith(status: ConnectionStatus.connected);
        // Refresh session list from gateway after successful connection
        final sessionNotifier = ref.read(sessionListProvider.notifier);
        sessionNotifier.refreshFromRemote().then((_) {
          // Auto-select first session if none selected
          // Need to read again after refresh because state may have changed
          final sessions = ref.read(sessionListProvider);
          final currentId = ref.read(currentSessionIdProvider);
          if (sessions.isNotEmpty && currentId == null) {
            // Select the first pinned or most recently updated session
            sessions.sort((a, b) {
              if (a.isPinned != b.isPinned) {
                return b.isPinned ? 1 : -1;
              }
              return b.updatedAt.compareTo(a.updatedAt);
            });
            ref.read(currentSessionIdProvider.notifier).state = sessions.first.id;
          } else if (sessions.isEmpty && currentId == null) {
            // No sessions from remote, create default session like OpenClaw Control UI
            sessionNotifier.createSession('default').then((session) {
              ref.read(currentSessionIdProvider.notifier).state = session.id;
            });
          }
        });
        return true;
      } else {
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: result.error ?? 'Connection failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void disconnect() {
    _client.disconnect();
    state = state.copyWith(status: ConnectionStatus.disconnected);
  }

  OpenClawClient get client => _client;
}
