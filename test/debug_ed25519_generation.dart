
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';

void main() async {
  const deviceUniqueId = 'test-android-id';

  print('=== Debug Ed25519 key generation ===');
  final algorithm = Ed25519();
  final appSalt = utf8.encode('claw-chat-openclaw-control-ui');
  final seedInput = List<int>.from(appSalt);
  seedInput.addAll(utf8.encode(deviceUniqueId));
  final seedHash = await Sha256().hash(seedInput);
  final seedBytes = seedHash.bytes;

  print('seed (32 bytes): ${hex.encode(seedBytes)}');
  print('seed length: ${seedBytes.length}');

  // Generate key pair from seed
  final keyPair = await algorithm.newKeyPairFromSeed(seedBytes);
  final extracted = await keyPair.extract();
  final publicKey = extracted.publicKey;
  print('');
  print('publicKey length: ${publicKey.bytes.length} bytes');
  print('publicKey hex: ${hex.encode(publicKey.bytes)}');

  // Compute device-id
  final deviceIdHash = await Sha256().hash(publicKey.bytes);
  final deviceId = hex.encode(deviceIdHash.bytes);
  print('');
  print('device-id: $deviceId');
}
