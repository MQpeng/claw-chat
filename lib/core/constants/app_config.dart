class AppConfig {
  final String gatewayUrl;
  final String token;

  AppConfig({
    required this.gatewayUrl,
    required this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'gatewayUrl': gatewayUrl,
      'token': token,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      gatewayUrl: json['gatewayUrl'] as String,
      token: json['token'] as String,
    );
  }

  AppConfig copyWith({
    String? gatewayUrl,
    String? token,
  }) {
    return AppConfig(
      gatewayUrl: gatewayUrl ?? this.gatewayUrl,
      token: token ?? this.token,
    );
  }

  @override
  String toString() => 'AppConfig(gatewayUrl: $gatewayUrl, token: [REDACTED])';
}
