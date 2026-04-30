class AppConfig {
  final String serverUrl;
  final String channel;

  const AppConfig({
    this.serverUrl = '',
    this.channel = '',
  });

  AppConfig copyWith({
    String? serverUrl,
    String? channel,
  }) {
    return AppConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      channel: channel ?? this.channel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'channel': channel,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      serverUrl: json['serverUrl'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
    );
  }
}
