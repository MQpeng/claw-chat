import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:dio/dio.dart';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';
import '../../../core/constants/app_config.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/file_item.dart';

typedef OnChunkCallback = void Function(String chunk);
typedef OnDoneCallback = void Function();
typedef OnErrorCallback = void Function(String error);

class ConnectionResult {
  final bool success;
  final String? error;
  ConnectionResult(this.success, this.error);
}

class OpenClawClient {
  AppConfig? _config;
  WebSocketChannel? _channel;
  bool _connected = false;
  bool _authenticated = false;
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  // Device identity - Ed25519 key pair stored locally
  SimpleKeyPair? _deviceKeyPair;
  String? _deviceId; // fingerprint = sha256(publicKey)

  bool get isConnected => _connected && _authenticated;

  void setConfig(AppConfig config) {
    _config = config;
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<ConnectionResult> testConnection() async {
    if (_config == null) return ConnectionResult(false, 'No configuration');

    try {
      disconnect();

      final uri = Uri.parse(_config!.gatewayUrl);
      final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
      var wsUri = uri.replace(scheme: wsScheme);

      // Ensure path ends with / if empty
      if (wsUri.path.isEmpty) {
        wsUri = wsUri.replace(path: '/');
      }

      // Set Origin header to match the gateway host
      // OpenClaw Gateway requires origin to be from the allowed host
      final httpUri = uri.replace(scheme: uri.scheme == 'wss' ? 'https' : 'http');
      final origin = httpUri.toString();

      // Use IOWebSocketChannel to support custom headers
      final socket = await WebSocket.connect(
        wsUri.toString(),
        headers: {
          'Origin': origin,
        },
      );
      _channel = IOWebSocketChannel(socket);
      _connected = true;
      _authenticated = false;

      // Load or generate device key pair (persisted to local storage)
      await _loadOrGenerateDeviceKey();

      // Wait for connect challenge and complete authentication
      final completer = Completer<ConnectionResult>();

      _channel!.stream.listen(
        (data) {
          _handleMessage(data as String, completer);
        },
        onError: (error) {
          _connected = false;
          _authenticated = false;
          if (!completer.isCompleted) {
            completer.complete(ConnectionResult(false, error.toString()));
          }
        },
        onDone: () {
          _connected = false;
          _authenticated = false;
          if (!completer.isCompleted) {
            completer.complete(ConnectionResult(false, 'Connection closed by server'));
          }
        },
      );

      // Wait for authentication to complete with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => ConnectionResult(false, 'Connection timeout after 10 seconds'),
      );
      return result;
    } catch (e) {
      _connected = false;
      _authenticated = false;
      return ConnectionResult(false, e.toString());
    }
  }

  Future<void> _loadOrGenerateDeviceKey() async {
    // Load existing key from shared_preferences or generate new
    if (_deviceKeyPair != null) return;

    // Try load from storage
    const storageKey = 'openclaw_device_identity';
    final prefs = await SharedPreferences.getInstance();
    final savedKeyPair = prefs.getString('${storageKey}_privateKey');
    final savedDeviceId = prefs.getString('${storageKey}_deviceId');

    if (savedKeyPair != null && savedDeviceId != null) {
      // Restore existing key pair
      final privateKeyBytes = base64.decode(savedKeyPair);
      _deviceKeyPair = await Ed25519().newKeyPairFromSeed(privateKeyBytes);
      _deviceId = savedDeviceId;
      return;
    }

    // Get device unique identifier (Android ID)
    // This stays the same across reinstalls unless device is factory reset
    String deviceUniqueId = '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      deviceUniqueId = androidInfo.id ?? '';
    }

    // Generate seed: HMAC(deviceUniqueId, app-specific-salt)
    // This ensures same device gets same seed even after reinstall
    final appSalt = utf8.encode('claw-chat-openclaw-control-ui');
    final List<int> seedInput = List<int>.from(appSalt);
    if (deviceUniqueId.isNotEmpty) {
      seedInput.addAll(utf8.encode(deviceUniqueId));
    }
    final seed = await Sha256().hash(seedInput);

    // Generate key pair from deterministic seed
    final algorithm = Ed25519();
    _deviceKeyPair = await algorithm.newKeyPairFromSeed(seed.bytes);
    final keyPairData = await _deviceKeyPair!.extract();
    final secretKey = seed.bytes; // we already have it as seed
    final publicKey = keyPairData.publicKey;

    // Generate device ID from public key fingerprint (sha256)
    final hash = await Sha256().hash(publicKey.bytes);
    _deviceId = hex.encode(hash.bytes);

    // Save to shared_preferences
    await prefs.setString('${storageKey}_privateKey', base64.encode(secretKey));
    await prefs.setString('${storageKey}_deviceId', _deviceId!);
  }

  Future<String> _signChallenge(String nonce, int timestamp) async {
    // Sign the challenge according to OpenClaw protocol v3
    // Signed payload includes: deviceId, clientId, clientMode, role, scopes, token, nonce, signedAt
    final payload = json.encode({
      'deviceId': _deviceId,
      'client': {
        'id': 'openclaw-control-ui',
        'version': '1.0.0',
        'platform': 'flutter-mobile',
        'mode': 'ui',
      },
      'role': 'operator',
      'scopes': [
        'operator.admin',
        'operator.read',
        'operator.write',
        'operator.approvals',
        'operator.pairing',
      ],
      'token': _config!.token,
      'nonce': nonce,
      'signedAt': timestamp,
    });

    final algorithm = Ed25519();
    final signature = await algorithm.sign(
      utf8.encode(payload),
      keyPair: _deviceKeyPair!,
    );
    return base64.encode(signature.bytes);
  }

  void _handleMessage(String raw, Completer<ConnectionResult> authCompleter) async {
    final parsed = json.decode(raw);
    final frame = parsed as Map<String, dynamic>;

    if (frame['type'] == 'event') {
      final event = frame['event'] as String?;
      if (event == 'connect.challenge') {
        final payload = frame['payload'] as Map<String, dynamic>;
        final nonce = payload['nonce'] as String;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final signature = await _signChallenge(nonce, timestamp);

        // Get public key bytes
        final publicKey = await _deviceKeyPair!.extractPublicKey();

        // Build connect request according to OpenClaw protocol
        // This is Control UI (mobile app), so role: operator, client.mode: ui
        final request = {
          'type': 'req',
          'id': 'connect-auth',
          'method': 'connect',
          'params': {
            'minProtocol': 3,
            'maxProtocol': 3,
            'client': {
              'id': 'openclaw-control-ui',
              'version': '1.0.0',
              'platform': 'flutter-mobile',
              'mode': 'ui',
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
            'locale': Platform.localeName,
            'userAgent': 'claw-chat/1.0.0',
            'device': {
              'id': _deviceId,
              'publicKey': hex.encode(publicKey.bytes),
              'signature': signature,
              'signedAt': timestamp,
              'nonce': nonce,
            },
          },
        };

        _channel!.sink.add(json.encode(request));
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
            authCompleter.complete(ConnectionResult(true, null));
          }
        } else {
          _authenticated = false;
          _connected = false;
          final errorMsg = frame['error'] != null
              ? frame['error']['message'] ?? 'Authentication failed'
              : 'Authentication failed';
          if (!authCompleter.isCompleted) {
            authCompleter.complete(ConnectionResult(false, errorMsg));
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
