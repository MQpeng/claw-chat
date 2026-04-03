
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';

// Fixed base58 encoder
const String _base58Alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

String base58EncodeFixed(List<int> bytes) {
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

// Old implementation
String base58EncodeOld(List<int> bytes) {
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

  print('=== Compare base58 implementations ===');

  final algorithm = Ed25519();
  final appSalt = utf8.encode('claw-chat-openclaw-control-ui');
  final seedInput = List<int>.from(appSalt);
  seedInput.addAll(utf8.encode(deviceUniqueId));
  final seed = await Sha256().hash(seedInput);

  final keyPair = await algorithm.newKeyPairFromSeed(seed.bytes);
  final publicKey = await keyPair.extractPublicKey();
  final publicKeyBytes = publicKey.bytes;

  print('publicKey hex: ${hex.encode(publicKeyBytes)}');
  print('');
  print('Old implementation: ${base58EncodeOld(publicKeyBytes)}');
  print('New fixed implementation: ${base58EncodeFixed(publicKeyBytes)}');
  print('');
  print('Are they equal? ${base58EncodeOld(publicKeyBytes) == base58EncodeFixed(publicKeyBytes)}');
}
