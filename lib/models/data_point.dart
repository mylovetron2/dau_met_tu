/// Điểm dữ liệu cho đường cong
class DataPoint {
  final DateTime timestamp;
  final double value;

  DataPoint({required this.timestamp, required this.value});

  @override
  String toString() {
    return 'DataPoint(timestamp: $timestamp, value: $value)';
  }
}

/// Buffer dữ liệu cho một đường cong
class CurveDataBuffer {
  final int maxPoints; // Số điểm tối đa lưu trữ
  final List<DataPoint> _points = [];

  CurveDataBuffer({this.maxPoints = 1000});

  /// Thêm điểm dữ liệu mới
  void addPoint(DataPoint point) {
    _points.add(point);

    // Giữ số điểm không vượt quá maxPoints
    if (_points.length > maxPoints) {
      _points.removeAt(0);
    }
  }

  /// Lấy tất cả các điểm
  List<DataPoint> get points => List.unmodifiable(_points);

  /// Lấy các điểm trong khoảng thời gian
  List<DataPoint> getPointsInRange(DateTime start, DateTime end) {
    return _points.where((point) {
      return point.timestamp.isAfter(start) && point.timestamp.isBefore(end);
    }).toList();
  }

  /// Xóa tất cả điểm
  void clear() {
    _points.clear();
  }

  /// Số điểm hiện tại
  int get length => _points.length;

  /// Điểm mới nhất
  DataPoint? get latest => _points.isNotEmpty ? _points.last : null;
}
