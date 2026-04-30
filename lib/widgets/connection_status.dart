import 'package:flutter/material.dart';
import '../services/signalr_service.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final Stream<ConnectionStatus> statusStream;
  final String channel;

  const ConnectionStatusWidget({
    super.key,
    required this.statusStream,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<ConnectionStatus>(
      stream: statusStream,
      initialData: ConnectionStatus.disconnected,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.disconnected;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                _StatusDot(status: status),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(status),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                Icon(
                  Icons.tag,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    channel.isEmpty ? '未设置' : channel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return '未连接';
      case ConnectionStatus.connecting:
        return '正在连接';
      case ConnectionStatus.connected:
        return '已连接';
      case ConnectionStatus.error:
        return '连接时发生错误';
    }
  }
}

class _StatusDot extends StatelessWidget {
  final ConnectionStatus status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color color;
    switch (status) {
      case ConnectionStatus.disconnected:
        color = colorScheme.outline;
        break;
      case ConnectionStatus.connecting:
        color = colorScheme.primary;
        break;
      case ConnectionStatus.connected:
        color = Colors.green;
        break;
      case ConnectionStatus.error:
        color = colorScheme.error;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
