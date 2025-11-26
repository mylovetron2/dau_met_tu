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

/// Danh sách curve mặc định
class DefaultCurves {
  static List<CurveConfig> get defaults => [
    CurveConfig(
      mnemonic: 'HPRS',
      name: 'Hydraulic Pressure',
      unit: 'PSI',
      channelIndex: 0,
      leftScale: 0,
      rightScale: 5000,
      color: Colors.red,
    ),
    CurveConfig(
      mnemonic: 'HTEM',
      name: 'Hydraulic Temperature',
      unit: '°C',
      channelIndex: 1,
      leftScale: 0,
      rightScale: 100,
      color: Colors.orange,
    ),
    CurveConfig(
      mnemonic: 'SPRS',
      name: 'Sample Pressure',
      unit: 'PSI',
      channelIndex: 2,
      leftScale: 0,
      rightScale: 5000,
      color: Colors.blue,
    ),
    CurveConfig(
      mnemonic: 'STEM',
      name: 'Sample Temperature',
      unit: '°C',
      channelIndex: 3,
      leftScale: 0,
      rightScale: 100,
      color: Colors.cyan,
    ),
    CurveConfig(
      mnemonic: 'MVOL',
      name: 'Motor Voltage',
      unit: 'V',
      channelIndex: 4,
      leftScale: 0,
      rightScale: 24,
      color: Colors.green,
    ),
  ];
}
