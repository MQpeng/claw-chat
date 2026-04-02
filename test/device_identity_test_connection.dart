
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';
import 'package:base58check/base58check.dart' show base58;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

// This is a local test script to verify device identity calculation
// DO NOT commit token/gateway url to git - these are example placeholders
void main() async {
  const gatewayUrl = 'wss://your-gateway.example.com';
  const token = 'your-gateway-admin-token-here';
  const deviceUniqueId = 'test-android-id';

  print('=== Testing OpenClaw connection with device identity ===');
  print('Gateway: $gatewayUrl');
  print('Token length: ${token.length}');

  // 1. Generate device identity the same way as the app does
  print('\n=== Step 1: Generate device identity ===');
  final algorithm = Ed25519();
  final appSalt = utf8.encode('claw-chat-openclaw-control-ui');
  final seedInput = List<int>.from(appSalt);
  seedInput.addAll(utf8.encode(deviceUniqueId));
  final seed = await Sha256().hash(seedInput);
  print('Seed: ${hex.encode(seed.bytes)} (${seed.bytes.length} bytes)');

  final keyPair = await algorithm.newKeyPairFromSeed(seed.bytes);
  final keyPairData = await keyPair.extract();
  final publicKey = keyPairData.publicKey;
  final publicKeyBytes = publicKey.bytes;
  final hash = await Sha256().hash(publicKeyBytes);
  final deviceId = hex.encode(hash.bytes);

  print('publicKey bytes length: ${publicKeyBytes.length}');
  print('publicKey hex: ${hex.encode(publicKeyBytes)}');
  print('publicKey base58: ${base58.encode(publicKeyBytes)}');
  print('deviceId (sha256(publicKey)): $deviceId');
  print('deviceId length: ${deviceId.length}');

  // 2. Connect
  print('\n=== Step 2: Connect to Gateway ===');
  final uri = Uri.parse(gatewayUrl);
  print('Parsed URI: scheme=${uri.scheme}, host=${uri.host}, port=${uri.port}');
  
  var wsUri = uri;
  if (wsUri.path.isEmpty) {
    wsUri = wsUri.replace(path: '/');
  }

  final httpUri = uri.replace(scheme: uri.scheme == 'wss' ? 'https' : 'http');
  final origin = httpUri.toString();
  print('Origin: $origin');

  final socket = await WebSocket.connect(
    wsUri.toString(),
    headers: {
      'Origin': origin,
    },
  );
  final channel = IOWebSocketChannel(socket);

  final completer = Completer<String>();
  String challengeNonce = '';

  channel.stream.listen(
    (data) {
      print('\n>>> Received: $data');
      final parsed = json.decode(data);
      final frame = parsed as Map<String, dynamic>;

      print('  Type: ${frame['type']}, event: ${frame['event']}');

      if (frame['type'] == 'event' && frame['event'] == 'connect.challenge') {
        final payload = frame['payload'] as Map<String, dynamic>;
        challengeNonce = payload['nonce'] as String;
        print('  Got connect.challenge, nonce: $challengeNonce');

        // Sign the challenge
        _signAndSend(channel, deviceId, publicKeyBytes, challengeNonce, token, keyPair);
        return;
      }

      if (frame['type'] == 'res' && frame['id'] == 'connect-auth') {
        final ok = frame['ok'] as bool;
        print('\n=== Got connect response ===');
        print('ok: $ok');
        if (!ok) {
          final errorValue = frame['error'];
          print('error: $errorValue');
          String msg = 'error';
          if (errorValue is Map && errorValue['message'] != null) {
            msg = errorValue['message'] as String;
            print('error message: $msg');
            if (msg == 'device identity mismatch') {
              print('\n❌ Got device identity mismatch');
              print('This means our device-id calculation is still wrong');
            } else if (msg == 'pairing required') {
              print('\n✅ Got "pairing required" - this is expected when device not approved yet');
              print('This means device identity calculation is CORRECT!');
              print('Now you just need to approve the device on Gateway:');
              print('  openclaw pairing approve');
            }
          }
          if (!completer.isCompleted) {
            completer.complete(msg);
          }
        } else {
          print('\n✅ SUCCESS! Authentication OK');
          if (!completer.isCompleted) {
            completer.complete('success');
          }
        }
      }
    },
    onError: (err) {
      print('\n❌ Error: $err');
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    },
    onDone: () {
      print('\n📪 Connection closed');
      if (!completer.isCompleted) {
        completer.completeError('Connection closed');
      }
    },
  );

  final result = await completer.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => 'timeout',
  );

  print('\n=== Final result: $result ===');
  await channel.sink.close();
  exit(0);
}

void _signAndSend(
  IOWebSocketChannel channel,
  String deviceId,
  List<int> publicKeyBytes,
  String nonce,
  String token,
  SimpleKeyPair keyPair,
) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  print('\n<<< Signing challenge and sending connect request...');

  // Sign the challenge according to OpenClaw protocol v3
  final payload = json.encode({
    'deviceId': deviceId,
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
    'token': token,
    'nonce': nonce,
    'signedAt': timestamp,
  });

  print('Signing payload:');
  print(payload);

  final algorithm = Ed25519();
  final signature = await algorithm.sign(
    utf8.encode(payload),
    keyPair: keyPair,
  );

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
        'token': token,
      },
      'locale': 'en-US',
      'userAgent': 'claw-chat/1.0.0',
      'device': {
        'id': deviceId,
        'publicKey': base58.encode(publicKeyBytes),
        'signature': base64.encode(signature.bytes),
        'signedAt': timestamp,
        'nonce': nonce,
      },
    },
  };

  print('\n<<< Send connect request:');
  print(json.encode(request));

  channel.sink.add(json.encode(request));
  print('✅ Connect request sent');
}
