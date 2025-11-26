import '../models/data_frame.dart';

/// Processor chuyển đổi DataFrame thành các giá trị hiển thị
class DataProcessor {
  // Channel mapping cho PIC 50-byte frame
  static const int ADC_TENSION = 0; // ADC[0] - Sức căng
  static const int ADC_MAGNETOMETER = 1; // ADC[1] - Từ trường
  static const int ADC_RESERVED = 2; // ADC[2] - Reserved
  static const int ADC_NVAC = 3; // ADC[3] - Điện áp AC
  static const int ADC_NIAC = 4; // ADC[4] - Dòng AC
  static const int ADC_5 = 5; // ADC[5]
  static const int ADC_NVDC = 6; // ADC[6] - Điện áp DC
  static const int ADC_NIDC = 7; // ADC[7] - Dòng DC
  static const int RAW_DEPTH = 8; // bytes 16-19: sdepth (32-bit)
  static const int ENCODER_DEPTH = 9; // bytes 36-39: depth từ PIC12F675
  static const int DELTA_TIME = 10; // bytes 40-41: delta time

  // Tracking cho speed calculation
  static int _prevEncoderDepth = 0;
  static DateTime _prevTime = DateTime.now();

  /// Tính toán thông tin hiển thị từ DataFrame
  static DisplayInfo processFrame(DataFrame frame) {
    final channels = frame.channels;

    // Tension từ ADC[0] (bytes 20-21)
    final tensionRaw = channels.length > ADC_TENSION
        ? channels[ADC_TENSION].toDouble()
        : 0.0;
    // PIC code: ftens = tens * atens / 1000 + btens
    // Giả sử atens=1000, btens=0 → tension = tensionRaw
    final tension = tensionRaw;

    // Magnetometer từ ADC[1]
    final magnetometer = channels.length > ADC_MAGNETOMETER
        ? channels[ADC_MAGNETOMETER].toDouble()
        : 0.0;

    // Điện áp/dòng AC/DC
    final nvac = channels.length > ADC_NVAC
        ? channels[ADC_NVAC].toDouble()
        : 0.0;
    final niac = channels.length > ADC_NIAC
        ? channels[ADC_NIAC].toDouble()
        : 0.0;
    final nvdc = channels.length > ADC_NVDC
        ? channels[ADC_NVDC].toDouble()
        : 0.0;
    final nidc = channels.length > ADC_NIDC
        ? channels[ADC_NIDC].toDouble()
        : 0.0;

    // Raw depth từ PIC (sdepth - bytes 16-19)
    final rawDepth = channels.length > RAW_DEPTH
        ? channels[RAW_DEPTH].toDouble()
        : 0.0;

    // Encoder depth từ PIC12F675 (bytes 36-39)
    final encoderDepth = channels.length > ENCODER_DEPTH
        ? channels[ENCODER_DEPTH]
        : 0;

    // Delta time (bytes 40-41) - đơn vị: 100ms
    final deltaTime = channels.length > DELTA_TIME ? channels[DELTA_TIME] : 0;

    // Tính depth (m) từ encoder
    // PIC code: fdepth = abs(sdepth) * 100 / coef_encoder
    // Giả sử coef_encoder = 19690
    final depth = rawDepth.abs() * 100.0 / 19690.0;

    // Tính speed (m/min)
    final now = DateTime.now();
    final timeDiff = now.difference(_prevTime).inMilliseconds;
    double speed = 0.0;

    if (timeDiff > 0) {
      final depthDiff = (encoderDepth - _prevEncoderDepth).abs();
      // PIC code: fspeed = lspeed * 1000 / coef_encoder (m/min)
      speed = depthDiff * 1000.0 / 19690.0;
      speed = speed * 60000.0 / timeDiff; // convert to m/min
    }

    _prevEncoderDepth = encoderDepth;
    _prevTime = now;

    // Valve status - PIC không có POSITION channel riêng
    // Giả định: từ magnetometer hoặc reserved channel
    bool valve1Open = false;
    bool valve2Open = false;

    // Tạm thời đặt mặc định
    if (magnetometer > 512) {
      valve1Open = true;
    } else {
      valve2Open = true;
    }

    return DisplayInfo(
      timestamp: frame.timestamp,
      depth: depth,
      speed: speed,
      hydraulicTemp: nvac, // Hiển thị N-VAC như temp
      hydraulicPress: tension, // Hiển thị tension như pressure
      sampleTemp: niac, // N-IAC
      samplePress: nvdc, // N-VDC
      quartzTemp: nidc, // N-IDC
      quartzPress: magnetometer, // Magnetometer
      pistonPos: rawDepth.abs() / 100.0, // Position từ depth (%)
      motorVoltage: deltaTime.toDouble() / 10.0, // Delta time như voltage
      valve1Open: valve1Open,
      valve2Open: valve2Open,
      temperatureFreq: frame.temperatureFreq,
      pressureFreq: frame.pressureFreq,
    );
  }
}

/// Model chứa thông tin để hiển thị
class DisplayInfo {
  final DateTime timestamp;
  final double depth;
  final double speed;
  final double hydraulicTemp;
  final double hydraulicPress;
  final double sampleTemp;
  final double samplePress;
  final double quartzTemp;
  final double quartzPress;
  final double pistonPos;
  final double motorVoltage;
  final bool valve1Open;
  final bool valve2Open;
  final double temperatureFreq;
  final double pressureFreq;

  DisplayInfo({
    required this.timestamp,
    required this.depth,
    required this.speed,
    required this.hydraulicTemp,
    required this.hydraulicPress,
    required this.sampleTemp,
    required this.samplePress,
    required this.quartzTemp,
    required this.quartzPress,
    required this.pistonPos,
    required this.motorVoltage,
    required this.valve1Open,
    required this.valve2Open,
    required this.temperatureFreq,
    required this.pressureFreq,
  });

  DisplayInfo copyWith({
    DateTime? timestamp,
    double? depth,
    double? speed,
    double? hydraulicTemp,
    double? hydraulicPress,
    double? sampleTemp,
    double? samplePress,
    double? quartzTemp,
    double? quartzPress,
    double? pistonPos,
    double? motorVoltage,
    bool? valve1Open,
    bool? valve2Open,
    double? temperatureFreq,
    double? pressureFreq,
  }) {
    return DisplayInfo(
      timestamp: timestamp ?? this.timestamp,
      depth: depth ?? this.depth,
      speed: speed ?? this.speed,
      hydraulicTemp: hydraulicTemp ?? this.hydraulicTemp,
      hydraulicPress: hydraulicPress ?? this.hydraulicPress,
      sampleTemp: sampleTemp ?? this.sampleTemp,
      samplePress: samplePress ?? this.samplePress,
      quartzTemp: quartzTemp ?? this.quartzTemp,
      quartzPress: quartzPress ?? this.quartzPress,
      pistonPos: pistonPos ?? this.pistonPos,
      motorVoltage: motorVoltage ?? this.motorVoltage,
      valve1Open: valve1Open ?? this.valve1Open,
      valve2Open: valve2Open ?? this.valve2Open,
      temperatureFreq: temperatureFreq ?? this.temperatureFreq,
      pressureFreq: pressureFreq ?? this.pressureFreq,
    );
  }

  @override
  String toString() {
    return 'DisplayInfo(depth: $depth, speed: $speed, hTemp: $hydraulicTemp, hPress: $hydraulicPress)';
  }
}
