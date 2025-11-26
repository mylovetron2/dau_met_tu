import 'dart:async';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import 'data_source.dart';

/// USB Serial data source
class UsbDataSource implements DataSource {
  UsbPort? _port;
  UsbDevice? _device;
  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();
  StreamSubscription<Uint8List>? _subscription;
  bool _isConnected = false;

  final int baudRate;
  final int dataBits;
  final int stopBits;
  final int parity;

  UsbDataSource({
    this.baudRate = 19200,
    this.dataBits = 8,
    this.stopBits = 1,
    this.parity = 0, // NONE
  });

  @override
  Future<bool> connect() async {
    try {
      // Lấy danh sách thiết bị USB
      List<UsbDevice> devices = await UsbSerial.listDevices();

      if (devices.isEmpty) {
        print('Không tìm thấy thiết bị USB');
        return false;
      }

      // Sử dụng thiết bị đầu tiên
      _device = devices.first;

      // Mở cổng USB
      _port = await _device!.create();

      if (_port == null) {
        print('Không thể mở cổng USB');
        return false;
      }

      // Cấu hình cổng
      await _port!.open();
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(baudRate, dataBits, stopBits, parity);

      // Lắng nghe dữ liệu
      _subscription = _port!.inputStream!.listen(
        (Uint8List data) {
          _dataController.add(data);
        },
        onError: (error) {
          print('Lỗi nhận dữ liệu USB: $error');
        },
      );

      _isConnected = true;
      print('Đã kết nối USB: ${_device!.productName}');
      return true;
    } catch (e) {
      print('Lỗi kết nối USB: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _port?.close();
      _port = null;
      _device = null;
      _isConnected = false;
      print('Đã ngắt kết nối USB');
    } catch (e) {
      print('Lỗi ngắt kết nối USB: $e');
    }
  }

  @override
  Stream<List<int>> get dataStream => _dataController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> send(List<int> data) async {
    if (_port != null && _isConnected) {
      await _port!.write(Uint8List.fromList(data));
    }
  }

  /// Lấy danh sách thiết bị USB
  static Future<List<UsbDevice>> getDevices() async {
    return await UsbSerial.listDevices();
  }

  void dispose() {
    _dataController.close();
  }
}
