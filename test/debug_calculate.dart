
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';

// Simple base58 encoder (same alphabet as bitcoin/base58)
const String _base58Alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

String base58Encode(List<int> bytes) {
  if (bytes.isEmpty) return '';

  // Count leading zeros
  int zeros = 0;
  while (zeros < bytes.length && bytes[zeros] == 0) {
    zeros++;
  }

  // Convert bytes to big integer
  BigInt number = BigInt.zero;
  for (int i = zeros; i < bytes.length; i++) {
    number = number * BigInt.from(256) + BigInt.from(bytes[i]);
  }

  final buffer = StringBuffer();
  while (number > BigInt.zero) {
    final remainder = number % BigInt.from(58);
    number = number ~/ BigInt.from(58);
    buffer.write(_base58Alphabet[remainder.toInt()]);
  }

  // Add leading 1 for zero bytes
  final result = String.fromCharCodes(
    Iterable.generate(zeros, (_) => _base58Alphabet.codeUnitAt(0))
  ) + buffer.toString().split('').reversed.join('');

  return result;
}

void main() async {
  const deviceUniqueId = 'test-android-id';

  print('=== Calculate device identity ===');
  print('deviceUniqueId: $deviceUniqueId');

  final algorithm = Ed25519();
  final appSalt = utf8.encode('claw-chat-openclaw-control-ui');
  final seedInput = List<int>.from(appSalt);
  seedInput.addAll(utf8.encode(deviceUniqueId));
  final seed = await Sha256().hash(seedInput);

  print('seed: ${hex.encode(seed.bytes)} (${seed.bytes.length} bytes)');

  final keyPair = await algorithm.newKeyPairFromSeed(seed.bytes);
  final keyPairData = await keyPair.extract();
  final publicKey = keyPairData.publicKey;
  final publicKeyBytes = publicKey.bytes;
  final hash = await Sha256().hash(publicKeyBytes);
  final deviceId = hex.encode(hash.bytes);
  final publicKeyBase58 = base58Encode(publicKeyBytes);

  print('');
  print('publicKey bytes length: ${publicKeyBytes.length}');
  print('publicKey hex: ${hex.encode(publicKeyBytes)}');
  print('publicKey base58: $publicKeyBase58');
  print('');
  print('deviceId (sha256(publicKey)): $deviceId');
  print('deviceId length: ${deviceId.length}');
}
