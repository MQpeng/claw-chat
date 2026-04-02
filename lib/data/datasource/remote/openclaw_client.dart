import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_config.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/file_item.dart';

typedef OnChunkCallback = void Function(String chunk);
typedef OnDoneCallback = void Function();
typedef OnErrorCallback = void Function(String error);

class OpenClawClient {
  AppConfig? _config;
  WebSocketChannel? _channel;
  bool _connected = false;
  bool _authenticated = false;
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  bool get isConnected => _connected && _authenticated;

  void setConfig(AppConfig config) {
    _config = config;
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<bool> testConnection() async {
    if (_config == null) return false;

    try {
      disconnect();

      final uri = Uri.parse(_config!.gatewayUrl);
      final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
      var wsUri = uri.replace(scheme: wsScheme);

      // Ensure path ends with / if empty
      if (wsUri.path.isEmpty) {
        wsUri = wsUri.replace(path: '/');
      }

      _channel = WebSocketChannel.connect(wsUri);
      _connected = true;
      _authenticated = false;

      // Wait for connect challenge and complete authentication
      final completer = Completer<bool>();

      _channel!.stream.listen(
        (data) {
          _handleMessage(data as String, completer);
        },
        onError: (error) {
          _connected = false;
          _authenticated = false;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
        onDone: () {
          _connected = false;
          _authenticated = false;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Wait for authentication to complete with timeout
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
    } catch (e) {
      _connected = false;
      _authenticated = false;
      return false;
    }
  }

  void _handleMessage(String raw, Completer<bool> authCompleter) {
    final parsed = json.decode(raw);
    final frame = parsed as Map<String, dynamic>;

    if (frame['type'] == 'event') {
      final event = frame['event'] as String?;
      if (event == 'connect.challenge') {
        _handleConnectChallenge();
        return;
      }
      return;
    }

    if (frame['type'] == 'res') {
      final id = frame['id'] as String;
      final ok = frame['ok'] as bool;
      final pending = _pendingRequests.remove(id);

      if (id == 'connect-auth') {
        if (ok) {
          _authenticated = true;
          if (!authCompleter.isCompleted) {
            authCompleter.complete(true);
          }
        } else {
          _authenticated = false;
          _connected = false;
          if (!authCompleter.isCompleted) {
            authCompleter.complete(false);
          }
        }
      }

      if (pending != null) {
        if (ok) {
          pending.complete(frame['payload']);
        } else {
          pending.completeError(
            Exception(frame['error']['message'] ?? 'Request failed'),
          );
        }
      }
      return;
    }
  }

  void _handleConnectChallenge() {
    if (_config == null) return;

    // Build connect request according to OpenClaw protocol
    final request = {
      'type': 'req',
      'id': 'connect-auth',
      'method': 'connect',
      'params': {
        'minProtocol': 3,
        'maxProtocol': 3,
        'client': {
          'id': 'claw-chat',
          'version': '1.0.0',
          'platform': 'flutter-mobile',
          'mode': 'mobile',
        },
        'role': 'operator',
        'scopes': [
          'operator.admin',
          'operator.read',
          'operator.write',
          'operator.approvals',
          'operator.pairing',
        ],
        'caps': ['tool-events', 'camera'],
        'auth': {
          'token': _config!.token,
        },
      },
    };

    _channel!.sink.add(json.encode(request));
  }

  void disconnect() {
    _channel?.sink.close();
    _connected = false;
    _authenticated = false;
    _channel = null;
    _pendingRequests.clear();
  }

  void sendMessage(
    String sessionId,
    ChatMessage message, {
    required OnChunkCallback onChunk,
    required OnDoneCallback onDone,
    required OnErrorCallback onError,
  }) {
    if (_channel == null || !isConnected) {
      onError('Not connected');
      return;
    }

    final request = {
      'type': 'req',
      'id': message.id,
      'method': 'chat.completion',
      'params': {
        'sessionId': sessionId,
        'content': message.content,
        if (message.attachments != null)
          'attachments': message.attachments!.map((a) => a.toJson()).toList(),
      },
    };

    _channel!.sink.add(json.encode(request));
  }

  // Call this once after connecting to setup the main stream listener
  void setupMainStreamListener({
    required Function(String chunk, String messageId, String state) onStreamEvent,
    required Function(String error) onStreamError,
    required VoidCallback onStreamDone,
  }) {
    _channel!.stream.listen(
      (data) {
        final event = json.decode(data as String);
        if (event['type'] != 'event') {
          // Handle request responses in _handleMessage
          return;
        }

        final eventName = event['event'] as String;
        if (eventName == 'chat.stream') {
          final payload = event['payload'] as Map<String, dynamic>;
          final id = payload['id'] as String;
          final state = payload['state'] as String;
          if (state == 'delta') {
            final delta = payload['message'] as String;
            onStreamEvent(delta, id, state);
          } else {
            onStreamEvent('', id, state);
          }
        }
      },
      onError: (error) {
        onStreamError(error.toString());
        _connected = false;
        _authenticated = false;
      },
      onDone: () {
        _connected = false;
        _authenticated = false;
        onStreamDone();
      },
    );
  }

  Future<String?> uploadFile(String filePath, String fileName) async {
    if (_config == null) return null;

    try {
      final dio = Dio();
      final uri = Uri.parse(_config!.gatewayUrl).replace(path: '/upload');
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await dio.postUri(
        uri,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer ${_config!.token}'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['url'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> request(String method, [Map<String, dynamic>? params]) {
    if (!isConnected) {
      return Future.error(Exception('Not connected'));
    }

    final id = _generateId();
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    final frame = {
      'type': 'req',
      'id': id,
      'method': method,
      'params': params,
    };

    _channel!.sink.add(json.encode(frame));
    return completer.future;
  }
}
