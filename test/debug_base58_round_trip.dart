
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';

// Our base58 encode
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

  final List<int> result = [];
  while (number > BigInt.zero) {
    final remainder = (number % BigInt.from(58)).toInt();
    number = number ~/ BigInt.from(58);
    result.insert(0, _base58Alphabet.codeUnitAt(remainder));
  }

  // Add leading 1s for leading zero bytes
  final resultBytes = List<int>.filled(zeros, _base58Alphabet.codeUnitAt(0)) + result;
  return String.fromCharCodes(resultBytes);
}

// Base58 decode for verification
List<int> base58Decode(String input) {
  if (input.isEmpty) return [];

  BigInt number = BigInt.zero;

  for (int i = 0; i < input.length; i++) {
    final c = input[i];
    final digit = _base58Alphabet.indexOf(c);
    if (digit == -1) {
      throw ArgumentError('Invalid character in base58: $c');
    }
    number = number * BigInt.from(58) + BigInt.from(digit);
  }

  // Convert to bytes
  final bytes = <int>[];
  while (number > BigInt.zero) {
    bytes.insert(0, (number % BigInt.from(256)).toInt());
    number = number ~/ BigInt.from(256);
  }

  // Add leading zeros for leading 1s in input
  int leadingZeros = 0;
  while (leadingZeros < input.length && input[leadingZeros] == _base58Alphabet[0]) {
    leadingZeros++;
  }

  return List<int>.filled(leadingZeros, 0) + bytes;
}

void main() async {
  const deviceUniqueId = 'test-android-id';

  print('=== Base58 round trip test ===');

  final algorithm = Ed25519();
  final appSalt = utf8.encode('claw-chat-openclaw-control-ui');
  final seedInput = List<int>.from(appSalt);
  seedInput.addAll(utf8.encode(deviceUniqueId));
  final seed = await Sha256().hash(seedInput);

  final keyPair = await algorithm.newKeyPairFromSeed(seed.bytes);
  final publicKey = await keyPair.extractPublicKey();
  final originalBytes = publicKey.bytes;

  print('Original publicKey:');
  print('  length: ${originalBytes.length}');
  print('  hex: ${hex.encode(originalBytes)}');
  print('');

  final encoded = base58Encode(originalBytes);
  print('Encoded base58: $encoded');
  print('');

  final decoded = base58Decode(encoded);
  print('Decoded bytes:');
  print('  length: ${decoded.length}');
  print('  hex: ${hex.encode(decoded)}');
  print('');

  print('Original equals decoded: ${hex.encode(originalBytes) == hex.encode(decoded)}');
}
