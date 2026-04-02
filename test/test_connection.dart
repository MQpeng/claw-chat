import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

void main() async {
  const url = 'wss://claw.pengly.cn';
  const token = 'c0e9029711de3916aae1bd08311c9179004d7e3230f1e81091ed9ae79f3291bf';
  
  print('Connecting to $url...');
  
  final uri = Uri.parse(url);
  final channel = IOWebSocketChannel.connect(uri);
  
  print('Connected, waiting for challenge...');
  
  final completer = Completer<bool>();
  Timer? timeout = Timer(const Duration(seconds: 15), () {
    if (!completer.isCompleted) {
      print('Timeout after 15s');
      completer.complete(false);
    }
  });
  
  channel.stream.listen(
    (data) {
      print('>>> Received: $data');
      final parsed = json.decode(data as String);
      final frame = parsed as Map<String, dynamic>;
      
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
        return;
      }
      
      if (frame['type'] == 'res' && frame['id'] == 'connect-auth') {
        final ok = frame['ok'] as bool;
        timeout.cancel();
        if (ok) {
          print('✅ Authentication SUCCESS');
          completer.complete(true);
        } else {
          final error = frame['error'] ?? 'Unknown error';
          print('❌ Authentication FAILED: $error');
          completer.complete(false);
        }
      }
    },
    onError: (error) {
      print('❌ Error: $error');
      timeout.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    },
    onDone: () {
      print('📪 Connection closed');
      timeout.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    },
  );
  
  final result = await completer.future;
  print('\n=== FINAL RESULT ===');
  print(result ? '✅ CONNECTION TEST PASSED' : '❌ CONNECTION TEST FAILED');
  
  if (result) {
    // Try list sessions
    print('\nTesting sessions.list...');
    final request = {
      'type': 'req',
      'id': 'list-sessions',
      'method': 'sessions.list',
      'params': {},
    };
    channel.sink.add(json.encode(request));
    await Future.delayed(const Duration(seconds: 3));
  }
  
  await channel.sink.close();
  exit(result ? 0 : 1);
}
