import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/config_service.dart';
import '../services/signalr_service.dart';
import '../widgets/connection_status.dart';

class ReceiverPage extends StatefulWidget {
  const ReceiverPage({super.key});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  final _signalR = SignalRService();
  String? _currentQrContent;
  DateTime? _lastReceivedTime;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Timer? _reconnectTimer;
  StreamSubscription<ConnectionStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _connect();
    _listenToStatus();
    _signalR.qrContentStream.listen((content) {
      if (mounted) {
        setState(() {
          _currentQrContent = content;
          _lastReceivedTime = DateTime.now();
          _elapsedSeconds = 0;
        });
        _startTimer();
      }
    });
  }

  void _listenToStatus() {
    _statusSubscription = _signalR.statusStream.listen((status) {
      if (status == ConnectionStatus.disconnected ||
          status == ConnectionStatus.error) {
        _scheduleReconnect();
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

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _lastReceivedTime != null) {
        setState(() {
          _elapsedSeconds = DateTime.now().difference(_lastReceivedTime!).inSeconds;
        });
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

  @override
  void dispose() {
    _timer?.cancel();
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
        title: const Text('接收模式'),
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
            child: Center(
              child: _currentQrContent == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code,
                          size: 80,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '等待',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.outline,
                              ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: QrImageView(
                                data: _currentQrContent!,
                                version: QrVersions.auto,
                                size: 280,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '距离上次接收已过去 $_elapsedSeconds 秒',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
