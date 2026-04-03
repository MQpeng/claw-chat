
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

  print('=== Debug publicKey.bytes from cryptography ===');
  final algorithm = Ed25519();
  final appSalt = utf8.encode('claw-chat-openclaw-control-ui');
  final seedInput = List<int>.from(appSalt);
  seedInput.addAll(utf8.encode(deviceUniqueId));
  final seed = await Sha256().hash(seedInput);

  print('seed: ${hex.encode(seed.bytes)}');

  final keyPair = await algorithm.newKeyPairFromSeed(seed.bytes);
  final publicKey = await keyPair.extractPublicKey();

  print('publicKey.bytes length: ${publicKey.bytes.length}');
  print('publicKey.bytes hex: ${hex.encode(publicKey.bytes)}');

  // Check if it's exactly 32 bytes
  if (publicKey.bytes.length != 32) {
    print('❌ publicKey.bytes length is NOT 32! This is the problem!');
  } else {
    print('✅ publicKey.bytes length is 32 bytes (correct)');
  }

  final hash = await Sha256().hash(publicKey.bytes);
  final deviceId = hex.encode(hash.bytes);
  print('');
  print('deviceId from sha256(publicKey.bytes): $deviceId');
}
