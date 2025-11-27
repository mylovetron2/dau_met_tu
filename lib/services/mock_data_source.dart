import 'dart:async';
import 'dart:math';

import 'data_source.dart';

/// Mock data source tạo dữ liệu giả để test
class MockDataSource implements DataSource {
  Timer? _timer;
  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();
  bool _isConnected = false;
  final Random _random = Random();

  // Giá trị mô phỏng cho các channel (ADC values 0-1023)
  int _adc0 = 512; // Tension
  int _adc1 = 400; // Magnetometer
  int _adc3 = 300; // VAC
  int _adc4 = 250; // IAC
  int _adc6 = 350; // VDC
  int _adc7 = 200; // IDC
  int _rawDepth = 0;
  int _encoderDepth = 0;
  int _deltaTime = 0;

  @override
  Stream<List<int>> get dataStream => _dataController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> connect() async {
    if (_isConnected) return true;

    print('🎭 Mock Data Source: Đang kết nối...');

    // Giả lập delay kết nối
    await Future.delayed(Duration(milliseconds: 500));

    _isConnected = true;
    _startGeneratingData();

    print('✅ Mock Data Source: Kết nối thành công');
    return true;
  }

  @override
  Future<void> disconnect() async {
    if (!_isConnected) return;

    print('🎭 Mock Data Source: Đang ngắt kết nối...');

    _timer?.cancel();
    _timer = null;
    _isConnected = false;

    print('✅ Mock Data Source: Đã ngắt kết nối');
  }

  @override
  Future<void> send(List<int> data) async {
    // Mock data source không xử lý command
    // Chỉ tự động tạo data
    print(
      '📤 Mock: Nhận command ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(' ')}',
    );
  }

  /// Bắt đầu tạo data giả theo chu kỳ
  void _startGeneratingData() {
    // Tạo frame mới mỗi 300ms (giống PIC mode)
    _timer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      if (_isConnected) {
        _generateAndSendFrame();
      }
    });
  }

  /// Tạo và gửi 1 PIC frame 50 bytes
  void _generateAndSendFrame() {
    // Mô phỏng dao động của các giá trị
    _updateMockValues();

    // Tạo frame 50 bytes
    final frame = _buildPICFrame();

    // Gửi qua stream
    _dataController.add(frame);
  }

  /// Cập nhật các giá trị mock theo thời gian
  void _updateMockValues() {
    // ADC0 - Tension: dao động nhẹ quanh 512
    _adc0 = 512 + _random.nextInt(100) - 50;
    _adc0 = _adc0.clamp(0, 1023);

    // ADC1 - Magnetometer: dao động quanh 400
    _adc1 = 400 + _random.nextInt(80) - 40;
    _adc1 = _adc1.clamp(0, 1023);

    // ADC3 - VAC: dao động quanh 300
    _adc3 = 300 + _random.nextInt(60) - 30;
    _adc3 = _adc3.clamp(0, 1023);

    // ADC4 - IAC: dao động quanh 250
    _adc4 = 250 + _random.nextInt(50) - 25;
    _adc4 = _adc4.clamp(0, 1023);

    // ADC6 - VDC: dao động quanh 350
    _adc6 = 350 + _random.nextInt(70) - 35;
    _adc6 = _adc6.clamp(0, 1023);

    // ADC7 - IDC: dao động quanh 200
    _adc7 = 200 + _random.nextInt(40) - 20;
    _adc7 = _adc7.clamp(0, 1023);

    // Raw depth: tăng dần
    _rawDepth += _random.nextInt(10);
    if (_rawDepth > 10000) _rawDepth = 0;

    // Encoder depth: tăng chậm hơn
    _encoderDepth += _random.nextInt(5);
    if (_encoderDepth > 8000) _encoderDepth = 0;

    // Delta time: dao động 1-50ms
    _deltaTime = 1 + _random.nextInt(50);
  }

  /// Xây dựng PIC frame 50 bytes
  List<int> _buildPICFrame() {
    final frame = <int>[];

    // Byte 0: Sign bit (random)
    frame.add(_random.nextInt(2));

    // Bytes 1-6: DEPTH BCD (random)
    for (int i = 0; i < 6; i++) {
      frame.add(_random.nextInt(10));
    }

    // Bytes 7-11: TENSION BCD (random)
    for (int i = 0; i < 5; i++) {
      frame.add(_random.nextInt(10));
    }

    // Bytes 12-15: SPEED BCD (random)
    for (int i = 0; i < 4; i++) {
      frame.add(_random.nextInt(10));
    }

    // Bytes 16-19: Raw depth (32-bit signed)
    frame.add(_rawDepth & 0xFF);
    frame.add((_rawDepth >> 8) & 0xFF);
    frame.add((_rawDepth >> 16) & 0xFF);
    frame.add((_rawDepth >> 24) & 0xFF);

    // Bytes 20-21: ADC[0] - Tension
    frame.add(_adc0 & 0xFF);
    frame.add((_adc0 >> 8) & 0xFF);

    // Bytes 22-23: ADC[1] - Magnetometer
    frame.add(_adc1 & 0xFF);
    frame.add((_adc1 >> 8) & 0xFF);

    // Bytes 24-25: ADC[2] (unused, set to 0)
    frame.add(0);
    frame.add(0);

    // Bytes 26-27: ADC[3] - VAC
    frame.add(_adc3 & 0xFF);
    frame.add((_adc3 >> 8) & 0xFF);

    // Bytes 28-29: ADC[4] - IAC
    frame.add(_adc4 & 0xFF);
    frame.add((_adc4 >> 8) & 0xFF);

    // Bytes 30-31: ADC[5] (unused, set to 0)
    frame.add(0);
    frame.add(0);

    // Bytes 32-33: ADC[6] - VDC
    frame.add(_adc6 & 0xFF);
    frame.add((_adc6 >> 8) & 0xFF);

    // Bytes 34-35: ADC[7] - IDC
    frame.add(_adc7 & 0xFF);
    frame.add((_adc7 >> 8) & 0xFF);

    // Bytes 36-39: Encoder depth (32-bit signed)
    frame.add(_encoderDepth & 0xFF);
    frame.add((_encoderDepth >> 8) & 0xFF);
    frame.add((_encoderDepth >> 16) & 0xFF);
    frame.add((_encoderDepth >> 24) & 0xFF);

    // Bytes 40-41: Delta time (16-bit)
    frame.add(_deltaTime & 0xFF);
    frame.add((_deltaTime >> 8) & 0xFF);

    // Bytes 42-47: Reserved (set to 0x7F 0x41 0x7F 0xD7 0x7F 0xD1)
    frame.addAll([0x7F, 0x41, 0x7F, 0xD7, 0x7F, 0xD1]);

    // Bytes 48-49: Tailers 0xAA 0xAA
    frame.add(0xAA);
    frame.add(0xAA);

    return frame;
  }

  void dispose() {
    _timer?.cancel();
    _dataController.close();
  }
}
