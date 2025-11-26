/// Enum loại giao tiếp
enum ConnectionType { usb, socket }

/// Abstract class cho data source
abstract class DataSource {
  /// Kết nối
  Future<bool> connect();

  /// Ngắt kết nối
  Future<void> disconnect();

  /// Stream nhận data frame
  Stream<List<int>> get dataStream;

  /// Kiểm tra đang kết nối
  bool get isConnected;

  /// Gửi dữ liệu
  Future<void> send(List<int> data);
}
