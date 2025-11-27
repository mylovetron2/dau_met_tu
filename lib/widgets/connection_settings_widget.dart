import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../services/data_source.dart';
import '../services/socket_data_source.dart';
import '../services/usb_data_source.dart';

/// Widget cấu hình kết nối
class ConnectionSettingsWidget extends StatefulWidget {
  final DataService dataService;
  final VoidCallback? onConnectionChanged;

  const ConnectionSettingsWidget({
    Key? key,
    required this.dataService,
    this.onConnectionChanged,
  }) : super(key: key);

  @override
  State<ConnectionSettingsWidget> createState() =>
      _ConnectionSettingsWidgetState();
}

class _ConnectionSettingsWidgetState extends State<ConnectionSettingsWidget> {
  ConnectionType _selectedType = ConnectionType.usb;
  bool _isConnected = false;

  // USB settings
  final TextEditingController _baudRateController = TextEditingController(
    text: '19200',
  );

  // Socket settings
  final TextEditingController _hostController = TextEditingController(
    text: '192.168.1.100',
  );
  final TextEditingController _portController = TextEditingController(
    text: '8080',
  );

  @override
  void dispose() {
    _baudRateController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    DataSource? dataSource;

    if (_selectedType == ConnectionType.usb) {
      final baudRate = int.tryParse(_baudRateController.text) ?? 19200;
      dataSource = UsbDataSource(baudRate: baudRate);
    } else {
      final host = _hostController.text;
      final port = int.tryParse(_portController.text) ?? 8080;
      dataSource = SocketDataSource(host: host, port: port);
    }

    final success = await widget.dataService.connect(dataSource);

    setState(() {
      _isConnected = success;
    });

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kết nối thành công')));
      widget.onConnectionChanged?.call();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kết nối thất bại')));
    }
  }

  Future<void> _disconnect() async {
    await widget.dataService.disconnect();
    setState(() {
      _isConnected = false;
    });
    widget.onConnectionChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header với trạng thái
            Row(
              children: [
                const Text(
                  'Kết nối',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isConnected) ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _selectedType == ConnectionType.usb
                        ? 'USB'
                        : '${_hostController.text}:${_portController.text}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton.icon(
                  onPressed: _isConnected ? _disconnect : _connect,
                  icon: Icon(
                    _isConnected ? Icons.stop : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(_isConnected ? 'Ngắt' : 'Kết nối'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),

            // Chỉ hiển thị settings khi chưa kết nối
            if (!_isConnected) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Chọn loại kết nối
              Row(
                children: [
                  const Text('Loại: '),
                  const SizedBox(width: 16),
                  SegmentedButton<ConnectionType>(
                    segments: const [
                      ButtonSegment(
                        value: ConnectionType.usb,
                        label: Text('USB'),
                        icon: Icon(Icons.usb),
                      ),
                      ButtonSegment(
                        value: ConnectionType.socket,
                        label: Text('Socket'),
                        icon: Icon(Icons.wifi),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (Set<ConnectionType> newSelection) {
                      setState(() {
                        _selectedType = newSelection.first;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cài đặt theo loại
              if (_selectedType == ConnectionType.usb)
                _buildUsbSettings()
              else
                _buildSocketSettings(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsbSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cài đặt USB:'),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Baud Rate: '),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _baudRateController,
                enabled: !_isConnected,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('(Data: 8, Stop: 1, Parity: None)'),
          ],
        ),
      ],
    );
  }

  Widget _buildSocketSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cài đặt Socket:'),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Host: '),
            const SizedBox(width: 8),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _hostController,
                enabled: !_isConnected,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '192.168.1.100',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('Port: '),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _portController,
                enabled: !_isConnected,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '8080',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
