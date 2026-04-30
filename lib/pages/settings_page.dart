import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/config_service.dart';
import '../models/app_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _serverUrlController = TextEditingController();
  final _channelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _serverUrlController.addListener(_autoSave);
    _channelController.addListener(_autoSave);
  }

  void _loadConfig() {
    final config = ConfigService().getConfig();
    _serverUrlController.text = config.serverUrl;
    _channelController.text = config.channel;
  }

  void _autoSave() {
    final config = AppConfig(
      serverUrl: _serverUrlController.text.trim(),
      channel: _channelController.text.trim(),
    );
    ConfigService().saveConfig(config);
  }

  Future<void> _copyChannel() async {
    final channel = _channelController.text.trim();
    if (channel.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: channel));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已复制')));
    }
  }

  Future<void> _generateRandomChannel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.shuffle),
        title: const Text('生成随机频道'),
        content: const Text('生成 UUID 作为频道。将覆盖当前频道设置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uuid = _generateUuid();
      _channelController.text = uuid;
    }
  }

  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  Future<void> _testConnection() async {
    final serverUrl = _serverUrlController.text.trim();
    if (serverUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未配置服务器地址')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('测试连接')));

    try {
      final uri = Uri.parse('$serverUrl/qrhub');
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(uri);
      final response = await request.close();

      client.close();

      if (mounted) {
        if (response.statusCode < 500) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('测试连接成功')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('服务器响应: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('测试连接失败: $e')));
      }
    }
  }

  @override
  void dispose() {
    _serverUrlController.removeListener(_autoSave);
    _channelController.removeListener(_autoSave);
    _serverUrlController.dispose();
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '服务器',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _serverUrlController,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              hintText: 'http://地址:端口',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: _testConnection,
              icon: const Icon(Icons.network_check, size: 18),
              label: const Text('测试连接'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '频道',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _channelController,
            decoration: const InputDecoration(
              labelText: '频道',
              hintText: '输入频道或生成随机 UUID',
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _copyChannel,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('复制'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _generateRandomChannel,
                icon: const Icon(Icons.shuffle, size: 18),
                label: const Text('随机'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
