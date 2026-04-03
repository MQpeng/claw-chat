
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';
import 'package:bs58/bs58.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

void main() async {
  const gatewayUrl = 'wss://claw.pengly.cn';
  const token = 'c0e9029711de3916aae1bd08311c9179004d7e3230f1e81091ed9ae79f3291bf';
  const deviceUniqueId = 'test-android-id';

  print('=== Testing OpenClaw connection with bs58 package (pub.dev) ===');
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
  print('publicKey base58 (via bs58 package): ${base58.encode(Uint8List.fromList(publicKeyBytes))}');
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
        _signAndSend(channel, deviceId, publicKeyBytes, base58.encode(Uint8List.fromList(publicKeyBytes)), challengeNonce, token, keyPair);
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
  String publicKeyBase58,
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
        'publicKey': publicKeyBase58,
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
