import 'dart:async';
import 'package:signalr_core/signalr_core.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();

  factory SignalRService() => _instance;

  SignalRService._internal();

  HubConnection? _connection;
  String? _currentChannel;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _qrContentController = StreamController<String>.broadcast();

  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  Stream<String> get qrContentStream => _qrContentController.stream;

  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;

  ConnectionStatus get currentStatus => _currentStatus;

  Future<void> connect(String serverUrl, String channel) async {
    if (_connection != null) {
      await disconnect();
    }

    _currentChannel = channel;
    _updateStatus(ConnectionStatus.connecting);

    _connection = HubConnectionBuilder()
        .withUrl(
          '$serverUrl/qrhub',
          HttpConnectionOptions(
            logging: (level, message) => print('SignalR: $message'),
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.onreconnecting((error) {
      _updateStatus(ConnectionStatus.connecting);
    });

    _connection!.onreconnected((connectionId) {
      _updateStatus(ConnectionStatus.connected);
      _subscribeToChannel();
    });

    _connection!.onclose((error) {
      _updateStatus(ConnectionStatus.disconnected);
    });

    _connection!.on('ReceiveQrCode', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final qrContent = arguments[0] as String?;
        if (qrContent != null) {
          _qrContentController.add(qrContent);
        }
      }
    });

    try {
      await _connection!.start();
      _updateStatus(ConnectionStatus.connected);
      await _subscribeToChannel();
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      rethrow;
    }
  }

  Future<void> _subscribeToChannel() async {
    if (_connection != null &&
        _currentStatus == ConnectionStatus.connected &&
        _currentChannel != null) {
      await _connection!.invoke('Subscribe', args: [_currentChannel]);
    }
  }

  Future<void> sendQrCode(String qrContent) async {
    if (_connection == null || _currentStatus != ConnectionStatus.connected) {
      throw Exception('未连接到服务器');
    }

    if (_currentChannel == null) {
      throw Exception('未设置频道');
    }

    await _connection!.invoke(
      'SendQrCode',
      args: [_currentChannel, qrContent],
    );
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        if (_currentChannel != null) {
          await _connection!.invoke('Unsubscribe', args: [_currentChannel]);
        }
        await _connection!.stop();
      } catch (e) {
        // ignore
      } finally {
        _connection = null;
        _currentChannel = null;
        _updateStatus(ConnectionStatus.disconnected);
      }
    }
  }

  void _updateStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusController.close();
    _qrContentController.close();
  }
}
