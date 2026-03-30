import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_config.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/file_item.dart';

typedef OnChunkCallback = void Function(String chunk);
typedef OnDoneCallback = void Function();
typedef OnErrorCallback = void Function(String error);

class OpenClawClient {
  AppConfig? _config;
  WebSocketChannel? _channel;
  bool _connected = false;

  bool get isConnected => _connected;

  void setConfig(AppConfig config) {
    _config = config;
  }

  Future<bool> testConnection() async {
    if (_config == null) return false;

    try {
      final uri = Uri.parse(_config!.gatewayUrl);
      final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final wsUri = uri.replace(scheme: wsScheme, path: 'ws');

      final wsUriWithHeaders = wsUri.replace(
        queryParameters: {'authorization': 'Bearer ${_config!.token}'},
      );
      _channel = WebSocketChannel.connect(wsUriWithHeaders);

      // WebSocketChannel.connect 会立即完成连接，只要DNS解析和TCP握手成功即可
      // OpenClaw 服务器不会主动发送欢迎消息，所以不需要等待第一条消息
      _connected = true;
      return true;
    } catch (e) {
      _connected = false;
      return false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _connected = false;
    _channel = null;
  }

  void sendMessage(
    String sessionId,
    ChatMessage message, {
    required OnChunkCallback onChunk,
    required OnDoneCallback onDone,
    required OnErrorCallback onError,
  }) {
    if (_channel == null || !_connected) {
      onError('Not connected');
      return;
    }

    final request = {
      'type': 'chat',
      'id': message.id,
      'sessionId': sessionId,
      'content': message.content,
      if (message.attachments != null)
        'attachments': message.attachments!.map((a) => a.toJson()).toList(),
    };

    _channel!.sink.add(json.encode(request));

    // Listen for response
    _channel!.stream.listen(
      (data) {
        final event = json.decode(data as String);
        final type = event['type'] as String;
        final messageId = event['id'] as String;

        if (messageId != message.id) return;

        switch (type) {
          case 'chunk':
            final chunk = event['chunk'] as String;
            onChunk(chunk);
            break;
          case 'done':
            onDone();
            break;
          case 'error':
            final errorMsg = event['message'] as String;
            onError(errorMsg);
            break;
        }
      },
      onError: (error) {
        onError(error.toString());
        _connected = false;
      },
      onDone: () {
        _connected = false;
      },
    );
  }

  Future<String?> uploadFile(String filePath, String fileName) async {
    if (_config == null) return null;

    try {
      final dio = Dio();
      final uri = Uri.parse(_config!.gatewayUrl).replace(path: '/upload');
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await dio.postUri(
        uri,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer ${_config!.token}'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['url'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
