
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';

void main() async {
  print('Testing Ed25519 key generation and device id...');
  
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final publicKey = await keyPair.extractPublicKey();
  
  print('Public key bytes length: ${publicKey.bytes.length}');
  print('Public key (hex): ${hex.encode(publicKey.bytes)}');
  
  final hash = await Sha256().hash(publicKey.bytes);
  final deviceId = hex.encode(hash.bytes);
  print('Device ID (sha256): $deviceId');
  print('Device ID length: ${deviceId.length}');
  
  // Verify that deviceId is sha256 of publicKey
  print('\nVerification:');
  print('sha256(${publicKey.bytes.length} bytes) = 32 bytes = 64 hex chars');
  print('Result: ${hash.bytes.length} bytes = ${deviceId.length} hex chars');
  
  if (hash.bytes.length == 32 && deviceId.length == 64) {
    print('✅ Correct!');
  } else {
    print('❌ Wrong length!');
  }
}
