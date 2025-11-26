import 'package:flutter/material.dart';

/// Cấu hình cho một đường cong
class CurveConfig {
  final String mnemonic; // Tên viết tắt
  final String name; // Tên đầy đủ
  final String unit; // Đơn vị
  final int channelIndex; // Index của kênh dữ liệu (0-14)
  final bool isActive; // Hiển thị hay không
  final double leftScale; // Giá trị min
  final double rightScale; // Giá trị max
  final Color color; // Màu đường cong
  final double width; // Độ rộng đường

  CurveConfig({
    required this.mnemonic,
    required this.name,
    required this.unit,
    required this.channelIndex,
    this.isActive = true,
    required this.leftScale,
    required this.rightScale,
    required this.color,
    this.width = 2.0,
  });

  CurveConfig copyWith({
    String? mnemonic,
    String? name,
    String? unit,
    int? channelIndex,
    bool? isActive,
    double? leftScale,
    double? rightScale,
    Color? color,
    double? width,
  }) {
    return CurveConfig(
      mnemonic: mnemonic ?? this.mnemonic,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      channelIndex: channelIndex ?? this.channelIndex,
      isActive: isActive ?? this.isActive,
      leftScale: leftScale ?? this.leftScale,
      rightScale: rightScale ?? this.rightScale,
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mnemonic': mnemonic,
      'name': name,
      'unit': unit,
      'channelIndex': channelIndex,
      'isActive': isActive,
      'leftScale': leftScale,
      'rightScale': rightScale,
      'color': color.value,
      'width': width,
    };
  }

  factory CurveConfig.fromJson(Map<String, dynamic> json) {
    return CurveConfig(
      mnemonic: json['mnemonic'],
      name: json['name'],
      unit: json['unit'],
      channelIndex: json['channelIndex'],
      isActive: json['isActive'] ?? true,
      leftScale: json['leftScale'].toDouble(),
      rightScale: json['rightScale'].toDouble(),
      color: Color(json['color']),
      width: json['width']?.toDouble() ?? 2.0,
    );
  }
}

/// Danh sách curve mặc định cho PIC 50-byte frame
class DefaultCurves {
  static List<CurveConfig> get defaults => [
    // ADC[0] Tension (bytes 20-21)
    CurveConfig(
      mnemonic: 'TENS',
      name: 'Tension',
      unit: 'kg',
      channelIndex: 0,
      leftScale: 0,
      rightScale: 1024,
      color: Colors.red,
    ),
    // ADC[1] Magnetometer (bytes 22-23)
    CurveConfig(
      mnemonic: 'MAG',
      name: 'Magnetometer',
      unit: 'ADC',
      channelIndex: 1,
      leftScale: 0,
      rightScale: 1024,
      color: Colors.purple,
    ),
    // ADC[3] N-VAC (bytes 26-27)
    CurveConfig(
      mnemonic: 'VAC',
      name: 'Voltage AC',
      unit: 'V',
      channelIndex: 3,
      leftScale: 0,
      rightScale: 1024,
      color: Colors.blue,
    ),
    // ADC[4] N-IAC (bytes 28-29)
    CurveConfig(
      mnemonic: 'IAC',
      name: 'Current AC',
      unit: 'A',
      channelIndex: 4,
      leftScale: 0,
      rightScale: 1024,
      color: Colors.cyan,
    ),
    // ADC[6] N-VDC (bytes 32-33)
    CurveConfig(
      mnemonic: 'VDC',
      name: 'Voltage DC',
      unit: 'V',
      channelIndex: 6,
      leftScale: 0,
      rightScale: 1024,
      color: Colors.green,
    ),
    // ADC[7] N-IDC (bytes 34-35)
    CurveConfig(
      mnemonic: 'IDC',
      name: 'Current DC',
      unit: 'A',
      channelIndex: 7,
      leftScale: 0,
      rightScale: 1024,
      color: Colors.lime,
    ),
    // Raw depth (bytes 16-19)
    CurveConfig(
      mnemonic: 'RDEP',
      name: 'Raw Depth',
      unit: 'm',
      channelIndex: 8,
      leftScale: 0,
      rightScale: 5000,
      color: Colors.orange,
    ),
    // Encoder depth from PIC12F675 (bytes 36-39)
    CurveConfig(
      mnemonic: 'EDEP',
      name: 'Encoder Depth',
      unit: 'm',
      channelIndex: 9,
      leftScale: 0,
      rightScale: 5000,
      color: Colors.brown,
    ),
    // Delta time (bytes 40-41)
    CurveConfig(
      mnemonic: 'DTIME',
      name: 'Delta Time',
      unit: 'ms',
      channelIndex: 10,
      leftScale: 0,
      rightScale: 10000,
      color: Colors.pink,
      isActive: false, // Mặc định tắt
    ),
  ];
}
