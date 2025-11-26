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
      if (_isPICMode) {
        // PIC mode: Tìm tailers 0xAA 0xAA (frame không có header)
        int tailerIndex = -1;
        for (int i = 0; i <= _buffer.length - 2; i++) {
          if (_buffer[i] == 0xAA && _buffer[i + 1] == 0xAA) {
            tailerIndex = i;
            break;
          }
        }

        if (tailerIndex == -1) {
          // Không tìm thấy tailers, giữ lại frameSize-2 bytes cuối
          if (_buffer.length > frameSize - 2) {
            int bytesToRemove = _buffer.length - (frameSize - 2);
            _buffer.removeRange(0, bytesToRemove);
            print(
              '⚠️  Chưa tìm thấy tailers AA AA, giữ lại ${_buffer.length} bytes',
            );
          }
          break;
        }

        // Frame phải có đủ 48 bytes data trước tailers
        if (tailerIndex < 48) {
          print('⚠️  Tailers ở vị trí $tailerIndex (cần >= 48), bỏ qua');
          _buffer.removeRange(0, tailerIndex + 2);
          continue;
        }

        // Frame starts at (tailerIndex - 48)
        int frameStart = tailerIndex - 48;
        if (frameStart > 0) {
          print('⚠️  Bỏ qua $frameStart bytes trước frame');
          _buffer.removeRange(0, frameStart);
          tailerIndex -= frameStart;
        }

        // Kiểm tra đủ 50 bytes
        if (_buffer.length < frameSize) {
          break;
        }

        print('✅ Tìm thấy PIC frame (tailers tại bytes 48-49)');

        // Parse PIC frame
        try {
          final frameBytes = _buffer.sublist(0, frameSize);
          print('🔍 Frame bytes: ${_bytesToHex(frameBytes)}');

          final frame = DataFrame.fromPIC(frameBytes);
          print('✅ PIC frame parsed! Channels: ${frame.channels.length}');

          // Emit frame
          _frameController.add(frame);

          // Xóa frame đã parse
          _buffer.removeRange(0, frameSize);
        } catch (e) {
          print('❌ Lỗi parse PIC frame: $e');
          // Xóa 2 bytes tailers và tìm frame tiếp theo
          _buffer.removeRange(0, 2);
        }
      } else {
        // MFT3 mode: Tìm header 0xAA
        int headerIndex = _buffer.indexOf(0xAA);

        if (headerIndex == -1) {
          print('❌ Không tìm thấy header 0xAA trong ${_buffer.length} bytes');
          _buffer.clear();
          break;
        }

        if (headerIndex > 0) {
          print('⚠️  Bỏ qua $headerIndex bytes trước header');
          _buffer.removeRange(0, headerIndex);
        }

        if (_buffer.length < frameSize) {
          break;
        }

        // Kiểm tra tailer 0x55
        if (_buffer[frameSize - 1] != 0x55) {
          print(
            '❌ MFT3 tailer không đúng: 0x${_buffer[frameSize - 1].toRadixString(16).padLeft(2, '0').toUpperCase()}',
          );
          _buffer.removeAt(0);
          continue;
        }

        print('✅ Tìm thấy MFT3 frame (Header: 0xAA, Tailer: 0x55)');

        // Parse MFT3 frame
        try {
          final frameBytes = _buffer.sublist(0, frameSize);
          print('🔍 Frame bytes: ${_bytesToHex(frameBytes)}');

          final frame = DataFrame.fromBytes(frameBytes);
          print(
            '✅ MFT3 frame parsed! Channels: ${frame.channels.length}, TempFreq: ${frame.temperatureFreq.toStringAsFixed(2)}, PressFreq: ${frame.pressureFreq.toStringAsFixed(2)}',
          );

          // Emit frame
          _frameController.add(frame);

          // Xóa frame đã parse
          _buffer.removeRange(0, frameSize);
        } catch (e) {
          print('❌ Lỗi parse MFT3 frame: $e');
          _buffer.removeAt(0);
        }
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
    // Luôn hiển thị đầy đủ cho PIC frame (50 bytes)
    if (_isPICMode && bytes.length <= 50) {
      return bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
    }

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
