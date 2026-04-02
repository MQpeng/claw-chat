
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

void main() async {
  const url = 'wss://claw.pengly.cn';
  const token = 'c0e9029711de3916aae1bd08311c9179004d7e3230f1e81091ed9ae79f3291bf';
  
  print('Connecting to $url...');
  
  final uri = Uri.parse(url);
  final channel = IOWebSocketChannel.connect(uri);
  
  print('Connected, waiting for messages...');
  
  final completer = Completer<String>();
  Timer? timeout = Timer(const Duration(seconds: 15), () {
    if (!completer.isCompleted) {
      completer.completeError('Timeout after 15s');
    }
  });
  
  channel.stream.listen(
    (data) {
      print('\n>>> Received: $data');
      final parsed = json.decode(data as String);
      final frame = parsed as Map<String, dynamic>;
      
      print('  Type: ${frame['type']}');
      if (frame['type'] == 'event' && frame['event'] == 'connect.challenge') {
        print('<<< Got connect.challenge, sending connect...');
        final request = {
          'type': 'req',
          'id': 'connect-auth',
          'method': 'connect',
          'params': {
            'minProtocol': 3,
            'maxProtocol': 3,
            'client': {
              'id': 'claw-chat-test',
              'version': '1.0.0',
              'platform': 'dart-test',
              'mode': 'mobile',
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
          },
        };
        channel.sink.add(json.encode(request));
        print('<<< Connect request sent');
        return;
      }
      
      if (frame['type'] == 'res' && frame['id'] == 'connect-auth') {
        timeout.cancel();
        print('=== Got authentication response ===');
        print('ok: ${frame['ok']}');
        if (!frame['ok'] && frame['error'] != null) {
          print('error: ${frame['error']}');
          if (frame['error'] is Map && frame['error']['message'] != null) {
            print('error message: ${frame['error']['message']}');
            completer.complete(frame['error']['message']);
          } else {
            completer.complete(frame['error'].toString());
          }
        } else {
          completer.complete('success');
        }
      }
    },
    onError: (error) {
      print('Error: $error');
      timeout.cancel();
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    },
    onDone: () {
      print('Connection closed');
      timeout.cancel();
      if (!completer.isCompleted) {
        completer.completeError('Connection closed prematurely');
      }
    },
  );
  
  try {
    final result = await completer.future;
    print('\n=== Final Result ===');
    print('Result: $result');
    if (result == 'pairing required') {
      print('\n✅ SUCCESS: Got "pairing required" as expected!');
      print('The code correctly receives the error message from Gateway.');
    } else if (result == 'success') {
      print('\n✅ Already approved, connection success!');
    }
  } catch (e) {
    print('\n❌ Error: $e');
  } finally {
    await channel.sink.close();
  }
}
