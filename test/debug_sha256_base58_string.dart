
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';
import 'package:bs58/bs58.dart';

void main() async {
  const deviceUniqueId = 'test-android-id';

  print('=== Check two versions of device-id calculation ===');

  final algorithm = Ed25519();
  final appSalt = utf8.encode('claw-chat-openclaw-control-ui');
  final seedInput = List<int>.from(appSalt);
  seedInput.addAll(utf8.encode(deviceUniqueId));
  final seed = await Sha256().hash(seedInput);

  final keyPair = await algorithm.newKeyPairFromSeed(seed.bytes);
  final publicKey = await keyPair.extractPublicKey();
  final publicKeyBytes = publicKey.bytes;
  final publicKeyBase58 = base58.encode(Uint8List.fromList(publicKeyBytes));

  // Version 1: what we are doing now - device-id = sha256(publicKey-bytes)
  final deviceIdVersion1 = hex.encode((await Sha256().hash(publicKeyBytes)).bytes);
  print('Version 1 (sha256(publicKey-bytes)): $deviceIdVersion1');

  // Version 2: what if it's sha256(publicKey-base58-utf8-bytes)
  final deviceIdVersion2 = hex.encode((await Sha256().hash(utf8.encode(publicKeyBase58))).bytes);
  print('Version 2 (sha256(base58-utf8-bytes)): $deviceIdVersion2');

  print('');
  print('Which one matches what you see in Gateway pending pairing?');
}
