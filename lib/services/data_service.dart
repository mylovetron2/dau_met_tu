import 'dart:async';

import '../models/data_frame.dart';
import '../models/data_point.dart';
import 'data_source.dart';

/// Service quản lý nhận và xử lý dữ liệu
class DataService {
  DataSource? _dataSource;
  final StreamController<DataFrame> _frameController =
      StreamController<DataFrame>.broadcast();
  StreamSubscription<List<int>>? _subscription;

  // Buffer để ghép các byte nhận được thành frame
  final List<int> _buffer = [];
  int frameSize = 68; // 68 bytes (MFT3) hoặc 50 bytes (PIC)
  bool _isPICMode = false;
  Timer? _requestTimer;

  // Map lưu trữ data buffer cho từng curve
  final Map<int, CurveDataBuffer> _curveBuffers = {};

  /// Stream các frame data đã parse
  Stream<DataFrame> get frameStream => _frameController.stream;

  /// Kết nối với data source
  Future<bool> connect(DataSource dataSource) async {
    if (_dataSource != null) {
      await disconnect();
    }

    _dataSource = dataSource;
    final success = await _dataSource!.connect();

    if (success) {
      // Lắng nghe data stream
      _subscription = _dataSource!.dataStream.listen(_onDataReceived);

      // Bắt đầu auto-request cho PIC mode (gửi 0xDE mỗi 300ms)
      _startAutoRequest();
    }

    return success;
  }

  /// Ngắt kết nối
  Future<void> disconnect() async {
    _requestTimer?.cancel();
    _requestTimer = null;
    await _subscription?.cancel();
    await _dataSource?.disconnect();
    _dataSource = null;
    _buffer.clear();
  }

  /// Xử lý dữ liệu nhận được
  void _onDataReceived(List<int> data) {
    // Debug: In ra bytes nhận được
    print('📥 Nhận ${data.length} bytes: ${_bytesToHex(data)}');
    _buffer.addAll(data);
    print('📦 Buffer size: ${_buffer.length} bytes');

    // Auto-detect frame type
    _detectFrameType();

    // Tìm và parse các frame trong buffer
    while (_buffer.length >= frameSize) {
      // Tìm header 0xAA
      int headerIndex = _buffer.indexOf(0xAA);

      if (headerIndex == -1) {
        // Không tìm thấy header, xóa buffer
        print('❌ Không tìm thấy header 0xAA trong ${_buffer.length} bytes');
        _buffer.clear();
        break;
      }

      if (headerIndex > 0) {
        print('⚠️  Bỏ qua $headerIndex bytes trước header');
      }

      // Xóa dữ liệu trước header
      if (headerIndex > 0) {
        _buffer.removeRange(0, headerIndex);
      }

      // Kiểm tra đủ dữ liệu cho frame
      if (_buffer.length < frameSize) {
        break;
      }

      // Kiểm tra tailer
      if (_buffer[frameSize - 1] != 0x55) {
        // Tailer không đúng, xóa header hiện tại và tìm tiếp
        print(
          '❌ Tailer không đúng: 0x${_buffer[frameSize - 1].toRadixString(16).padLeft(2, '0').toUpperCase()} (mong đợi 0x55)',
        );
        _buffer.removeAt(0);
        continue;
      }

      print('✅ Tìm thấy frame hợp lệ (Header: 0xAA, Tailer: 0x55)');

      // Parse frame
      try {
        final frameBytes = _buffer.sublist(0, frameSize);
        print('🔍 Frame bytes: ${_bytesToHex(frameBytes)}');

        final DataFrame frame;
        if (_isPICMode) {
          frame = DataFrame.fromPIC(frameBytes);
          print('✅ PIC frame parsed! Channels: ${frame.channels.length}');
        } else {
          frame = DataFrame.fromBytes(frameBytes);
          print(
            '✅ MFT3 frame parsed! Channels: ${frame.channels.length}, TempFreq: ${frame.temperatureFreq.toStringAsFixed(2)}, PressFreq: ${frame.pressureFreq.toStringAsFixed(2)}',
          );
        }

        // Emit frame
        _frameController.add(frame);

        // Xóa frame đã parse
        _buffer.removeRange(0, frameSize);
      } catch (e) {
        print('Lỗi parse frame: $e');
        // Xóa header và tìm frame tiếp theo
        _buffer.removeAt(0);
      }
    }
  }

  /// Thêm data point vào buffer của curve
  void addDataPoint(int channelIndex, DataPoint point) {
    if (!_curveBuffers.containsKey(channelIndex)) {
      _curveBuffers[channelIndex] = CurveDataBuffer(maxPoints: 1000);
    }
    _curveBuffers[channelIndex]!.addPoint(point);
  }

  /// Lấy buffer của curve
  CurveDataBuffer? getCurveBuffer(int channelIndex) {
    return _curveBuffers[channelIndex];
  }

  /// Xóa tất cả data buffer
  void clearAllBuffers() {
    _curveBuffers.forEach((key, buffer) {
      buffer.clear();
    });
  }

  /// Xóa buffer của một curve
  void clearCurveBuffer(int channelIndex) {
    _curveBuffers[channelIndex]?.clear();
  }

  /// Gửi dữ liệu
  Future<void> send(List<int> data) async {
    await _dataSource?.send(data);
  }

  /// Kiểm tra đang kết nối
  bool get isConnected => _dataSource?.isConnected ?? false;

  /// Bắt đầu auto-request cho PIC mode
  void _startAutoRequest() {
    _requestTimer = Timer.periodic(Duration(milliseconds: 300), (timer) async {
      if (_isPICMode && _dataSource != null) {
        // Gửi command 0xDE (8 bytes: 0xDE + 7 bytes padding)
        final command = [0xDE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        await send(command);
        print('📤 Gửi command 0xDE (request PIC data)');
      }
    });
  }

  /// Auto-detect frame type (MFT3 68-byte vs PIC 50-byte)
  void _detectFrameType() {
    if (_buffer.length >= 50) {
      // Kiểm tra PIC frame pattern: ... 0xAA 0xAA
      for (int i = 0; i < _buffer.length - 49; i++) {
        if (_buffer[i + 48] == 0xAA && _buffer[i + 49] == 0xAA) {
          // Có thể là PIC frame
          if (!_isPICMode) {
            _isPICMode = true;
            frameSize = 50;
            print('🔄 Chuyển sang PIC mode (50 bytes)');
          }
          return;
        }
      }
    }

    if (_buffer.length >= 68) {
      // Kiểm tra MFT3 frame pattern: 0xAA ... 0x55
      for (int i = 0; i < _buffer.length - 67; i++) {
        if (_buffer[i] == 0xAA && _buffer[i + 67] == 0x55) {
          // Có thể là MFT3 frame
          if (_isPICMode) {
            _isPICMode = false;
            frameSize = 68;
            print('🔄 Chuyển sang MFT3 mode (68 bytes)');
          }
          return;
        }
      }
    }
  }

  /// Chuyển bytes sang chuỗi hex để debug
  String _bytesToHex(List<int> bytes) {
    if (bytes.length > 20) {
      // Nếu quá dài, chỉ hiển thị 20 bytes đầu
      final preview = bytes.sublist(0, 20);
      return preview
              .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
              .join(' ') +
          '...';
    }
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  void dispose() {
    _requestTimer?.cancel();
    _subscription?.cancel();
    _frameController.close();
    _dataSource?.disconnect();
  }
}
