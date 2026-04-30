import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/config_service.dart';
import '../services/signalr_service.dart';
import '../widgets/connection_status.dart';

class SenderPage extends StatefulWidget {
  const SenderPage({super.key});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> {
  final _signalR = SignalRService();
  String? _lastQrContent;
  bool _isInitialized = false;
  Timer? _reconnectTimer;
  StreamSubscription<ConnectionStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _connect();
    _listenToStatus();
  }

  void _listenToStatus() {
    _statusSubscription = _signalR.statusStream.listen((status) {
      if (status == ConnectionStatus.disconnected ||
          status == ConnectionStatus.error) {
        _scheduleReconnect();
      } else if (status == ConnectionStatus.connected) {
        setState(() => _isInitialized = true);
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _connect();
      }
    });
  }

  Future<void> _connect() async {
    final config = ConfigService().getConfig();
    if (config.serverUrl.isEmpty || config.channel.isEmpty) {
      _scheduleReconnect();
      return;
    }

    try {
      await _signalR.connect(config.serverUrl, config.channel);
    } catch (e) {
      _scheduleReconnect();
    }
  }

  Future<void> _onQrCodeDetected(String qrContent) async {
    if (qrContent == _lastQrContent) return;

    setState(() => _lastQrContent = qrContent);

    try {
      await _signalR.sendQrCode(qrContent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已发送'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    }
  }

  void _clearLastContent() {
    setState(() => _lastQrContent = null);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _statusSubscription?.cancel();
    _signalR.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = ConfigService().getConfig();

    return Scaffold(
      appBar: AppBar(
        title: const Text('发送模式'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          ConnectionStatusWidget(
            statusStream: _signalR.statusStream,
            channel: config.channel,
          ),
          Expanded(
            child: _isInitialized
                ? MobileScanner(
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final rawValue = barcode.rawValue;
                        if (rawValue != null) {
                          _onQrCodeDetected(rawValue);
                          break;
                        }
                      }
                    },
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          if (_lastQrContent != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '最后发送',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _clearLastContent,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastQrContent!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
