/// Model cho data frame nhận từ thiết bị
/// Frame data: 68 bytes với header 0xAA, tailer 0x55
class DataFrame {
  final int header;
  final int tailer;
  final List<int> channels; // 15 kênh đo MA[15]
  final double temperatureFreq; // Tần số nhiệt độ
  final double pressureFreq; // Tần số áp suất
  final DateTime timestamp;

  DataFrame({
    required this.header,
    required this.tailer,
    required this.channels,
    required this.temperatureFreq,
    required this.pressureFreq,
    required this.timestamp,
  });

  /// Parse frame data từ byte array (68 bytes - MFT3 format)
  /// Có cơ chế frame recovery giống MFT3 - tìm và xoay vòng buffer nếu header/tailer sai vị trí
  factory DataFrame.fromBytes(List<int> bytes) {
    if (bytes.length != 68) {
      throw ArgumentError('Frame phải có 68 bytes');
    }

    List<int> bufData = List<int>.filled(68, 0);

    // Kiểm tra header và tailer đúng vị trí
    if (bytes[0] == 0xAA && bytes[67] == 0x55) {
      // Frame đúng, copy toàn bộ
      for (int i = 0; i < 68; i++) {
        bufData[i] = bytes[i];
      }
    } else {
      // Frame lỗi vị trí, tìm header trong buffer và sắp xếp lại (Frame Recovery)
      int foundPos = -1;
      for (int i = 0; i < 68; i++) {
        if (bytes[(i + 1) % 68] == 0xAA && bytes[i] == 0x55) {
          foundPos = i;
          break;
        }
      }

      if (foundPos == -1) {
        throw ArgumentError(
          'Không tìm thấy Header 0xAA và Tailer 0x55 trong frame',
        );
      }

      // Xoay vòng buffer để đúng vị trí
      for (int j = 0; j < 68; j++) {
        if (j < 67 - foundPos) {
          bufData[j] = bytes[foundPos + j + 1];
        } else {
          bufData[j] = bytes[j + foundPos - 67];
        }
      }
    }

    // Parse 15 kênh đo (mỗi kênh 4 bytes, bắt đầu từ byte 1)
    List<int> channels = [];
    for (int i = 0; i < 15; i++) {
      int value = bufData[4 * i + 1];
      value <<= 8;
      value |= bufData[i * 4 + 2];
      value &= 0x3FFF;

      // Chuyển đổi giá trị signed
      if (value > 0x1FFF) {
        value -= 0x3FFF;
      }
      channels.add(value);
    }

    // Parse temperature frequency (bytes 61-62)
    int tempRaw = bufData[61] & 0x7F;
    int aa = tempRaw >> 3;
    int bb = _reverseBits(aa) >> 1;
    tempRaw &= 0x07;
    tempRaw |= bb;
    tempRaw <<= 5;
    int temp2 = bufData[62];
    temp2 >>= 3;
    tempRaw |= temp2;
    double tempFreq = tempRaw * 1000000.0 / 61440.0;

    // Parse pressure frequency (bytes 63-65)
    int pressRaw = bufData[63] & 0x3F;
    pressRaw <<= 13;
    temp2 = bufData[64];
    temp2 <<= 5;
    pressRaw |= temp2;
    temp2 = bufData[65] >> 3;
    pressRaw |= temp2;
    double pressFreq = 1000000.0 / (pressRaw / 4088.6);

    return DataFrame(
      header: bufData[0],
      tailer: bufData[67],
      channels: channels,
      temperatureFreq: tempFreq,
      pressureFreq: pressFreq,
      timestamp: DateTime.now(),
    );
  }

  /// Parse PIC16F877A frame (50 bytes: 48 data + 0xAA 0xAA)
  factory DataFrame.fromPIC(List<int> bytes) {
    if (bytes.length != 50) {
      throw ArgumentError('PIC frame phải có 50 bytes');
    }

    // Kiểm tra tailers 0xAA 0xAA
    if (bytes[48] != 0xAA || bytes[49] != 0xAA) {
      throw ArgumentError('PIC frame tailers không đúng (cần 0xAA 0xAA)');
    }

    // Parse raw depth từ bytes 16-19 (32-bit signed)
    int rawDepth =
        bytes[16] | (bytes[17] << 8) | (bytes[18] << 16) | (bytes[19] << 24);
    if (rawDepth > 0x7FFFFFFF) rawDepth -= 0x100000000;

    // Parse ADC channels (bytes 20-35: 8 channels × 2 bytes)
    List<int> channels = [];
    for (int i = 0; i < 8; i++) {
      int value = bytes[20 + i * 2] | (bytes[21 + i * 2] << 8);
      channels.add(value);
    }

    // Thêm raw depth vào channel 8
    channels.add(rawDepth);

    // Parse encoder depth từ bytes 36-39 (từ PIC12F675)
    int encoderDepth =
        bytes[36] | (bytes[37] << 8) | (bytes[38] << 16) | (bytes[39] << 24);
    if (encoderDepth > 0x7FFFFFFF) encoderDepth -= 0x100000000;
    channels.add(encoderDepth);

    // Parse delta time (bytes 40-41)
    int deltaTime = bytes[40] | (bytes[41] << 8);
    channels.add(deltaTime);

    // Pad thêm channels để đủ 15 channels
    while (channels.length < 15) {
      channels.add(0);
    }

    return DataFrame(
      header: 0xAA,
      tailer: 0xAA,
      channels: channels.sublist(0, 15),
      temperatureFreq: 0.0, // PIC không có temp freq
      pressureFreq: 0.0, // PIC không có press freq
      timestamp: DateTime.now(),
    );
  }

  static int _reverseBits(int value) {
    int result = 0;
    for (int i = 0; i < 8; i++) {
      result <<= 1;
      result |= (value & 1);
      value >>= 1;
    }
    return result;
  }

  @override
  String toString() {
    return 'DataFrame(timestamp: $timestamp, channels: ${channels.length}, tempFreq: $temperatureFreq, pressFreq: $pressureFreq)';
  }
}
