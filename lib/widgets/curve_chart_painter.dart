import 'package:flutter/material.dart';

import '../models/curve_config.dart';
import '../models/data_point.dart';

/// Custom painter vẽ các đường cong realtime
/// Trục Y: Thời gian (từ trên xuống)
/// Trục X: Giá trị
class CurveChartPainter extends CustomPainter {
  final List<CurveConfig> curves;
  final Map<int, List<DataPoint>> curveData;
  final Duration timeWindow; // Khoảng thời gian hiển thị
  final bool showGrid;
  final Color gridColor;
  final Color backgroundColor;

  CurveChartPainter({
    required this.curves,
    required this.curveData,
    this.timeWindow = const Duration(minutes: 5),
    this.showGrid = true,
    this.gridColor = Colors.grey,
    this.backgroundColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // Vẽ grid
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Vẽ từng đường cong
    for (var curve in curves) {
      if (curve.isActive && curveData.containsKey(curve.channelIndex)) {
        _drawCurve(canvas, size, curve, curveData[curve.channelIndex]!);
      }
    }

    // Vẽ trục và nhãn
    _drawAxes(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Vẽ lưới dọc (thời gian)
    const verticalLines = 10;
    for (int i = 0; i <= verticalLines; i++) {
      final y = size.height * i / verticalLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vẽ lưới ngang (giá trị)
    const horizontalLines = 10;
    for (int i = 0; i <= horizontalLines; i++) {
      final x = size.width * i / horizontalLines;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  void _drawCurve(
    Canvas canvas,
    Size size,
    CurveConfig curve,
    List<DataPoint> points,
  ) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = curve.color
      ..strokeWidth = curve.width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final now = DateTime.now();
    final startTime = now.subtract(timeWindow);

    bool isFirstPoint = true;

    for (var point in points) {
      // Bỏ qua điểm ngoài time window
      if (point.timestamp.isBefore(startTime)) continue;

      // Tính toán vị trí
      final x = _valueToX(
        point.value,
        curve.leftScale,
        curve.rightScale,
        size.width,
      );
      final y = _timeToY(point.timestamp, startTime, now, size.height);

      if (isFirstPoint) {
        path.moveTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  double _valueToX(
    double value,
    double minValue,
    double maxValue,
    double width,
  ) {
    // Chuyển đổi giá trị sang tọa độ X
    final normalized = (value - minValue) / (maxValue - minValue);
    return normalized.clamp(0.0, 1.0) * width;
  }

  double _timeToY(
    DateTime time,
    DateTime startTime,
    DateTime endTime,
    double height,
  ) {
    // Chuyển đổi thời gian sang tọa độ Y (từ trên xuống)
    final totalDuration = endTime.difference(startTime).inMicroseconds;
    final timeDuration = time.difference(startTime).inMicroseconds;
    final normalized = timeDuration / totalDuration;
    return normalized.clamp(0.0, 1.0) * height;
  }

  void _drawAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    // Vẽ trục Y (bên trái)
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), axisPaint);

    // Vẽ trục X (dưới cùng)
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(CurveChartPainter oldDelegate) {
    return true; // Vẽ lại mỗi khi có dữ liệu mới
  }
}
