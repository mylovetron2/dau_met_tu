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

    // Vẽ nhãn thời gian trên trục Y
    _drawTimeLabels(canvas, size);
  }

  void _drawTimeLabels(Canvas canvas, Size size) {
    final now = DateTime.now();
    final startTime = now.subtract(timeWindow);

    // Số lượng nhãn thời gian
    const labelCount = 6;

    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i <= labelCount; i++) {
      // Tính thời gian cho mỗi nhãn
      final progress = i / labelCount;
      final timeDuration = now.difference(startTime).inMicroseconds;
      final labelTime = startTime.add(
        Duration(microseconds: (timeDuration * progress).round()),
      );

      // Tính vị trí Y
      final y = size.height * progress;

      // Format thời gian (HH:mm:ss)
      final timeText =
          '${labelTime.hour.toString().padLeft(2, '0')}:'
          '${labelTime.minute.toString().padLeft(2, '0')}:'
          '${labelTime.second.toString().padLeft(2, '0')}';

      // Vẽ text với nền trắng để dễ đọc
      final textSpan = TextSpan(text: timeText, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Vẽ bên PHẢI trục Y (bên trong canvas)
      final xOffset = 5.0; // 5 pixel từ trục Y vào trong

      // Clamp yOffset để không bị cắt ở trên và dưới
      var yOffset = y - textPainter.height / 2;
      yOffset = yOffset.clamp(0.0, size.height - textPainter.height);

      // Vẽ nền trắng cho text để dễ đọc
      final bgRect = Rect.fromLTWH(
        xOffset - 2,
        yOffset - 1,
        textPainter.width + 4,
        textPainter.height + 2,
      );
      canvas.drawRect(bgRect, Paint()..color = Colors.white.withOpacity(0.8));

      textPainter.paint(canvas, Offset(xOffset, yOffset));

      // Vẽ tick mark
      final tickPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(0, y), Offset(3, y), tickPaint);
    }
  }

  @override
  bool shouldRepaint(CurveChartPainter oldDelegate) {
    return true; // Vẽ lại mỗi khi có dữ liệu mới
  }
}
