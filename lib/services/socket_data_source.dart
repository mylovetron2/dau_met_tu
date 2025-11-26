import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'data_source.dart';

/// Socket TCP data source (nhận từ ESP32)
class SocketDataSource implements DataSource {
  Socket? _socket;
  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();
  StreamSubscription<Uint8List>? _subscription;
  bool _isConnected = false;

  final String host;
  final int port;

  SocketDataSource({required this.host, required this.port});

  @override
  Future<bool> connect() async {
    try {
      // Kết nối socket
      _socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );

      // Lắng nghe dữ liệu
      _subscription = _socket!.listen(
        (Uint8List data) {
          _dataController.add(data);
        },
        onError: (error) {
          print('Lỗi nhận dữ liệu Socket: $error');
          _isConnected = false;
        },
        onDone: () {
          print('Socket đã đóng');
          _isConnected = false;
        },
      );

      _isConnected = true;
      print('Đã kết nối Socket: $host:$port');
      return true;
    } catch (e) {
      print('Lỗi kết nối Socket: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _socket?.close();
      _socket = null;
      _isConnected = false;
      print('Đã ngắt kết nối Socket');
    } catch (e) {
      print('Lỗi ngắt kết nối Socket: $e');
    }
  }

  @override
  Stream<List<int>> get dataStream => _dataController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> send(List<int> data) async {
    if (_socket != null && _isConnected) {
      _socket!.add(data);
      await _socket!.flush();
    }
  }

  void dispose() {
    _dataController.close();
  }
}
