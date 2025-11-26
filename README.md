# MFT Monitor Flutter

Ứng dụng Flutter để giám sát dữ liệu realtime từ thiết bị MFT qua USB hoặc Socket (ESP32).

## Tính năng

- **Giao tiếp đa dạng**: Hỗ trợ cả USB Serial (UART) và Socket TCP/IP
- **Nhận dữ liệu realtime**: Parse frame data 68 bytes với header 0xAA, tailer 0x55
- **Hiển thị đường cong**: Vẽ nhiều đường cong với trục Y là thời gian (từ trên xuống), trục X là giá trị
- **Cấu hình linh hoạt**: 
  - Chọn loại kết nối (USB/Socket)
  - Bật/tắt các đường cong
  - Điều chỉnh cửa sổ thời gian hiển thị

## Kiến trúc

### Models
- **DataFrame**: Parse frame data 68 bytes
  - 15 kênh đo (channels MA[0-14])
  - Tần số nhiệt độ và áp suất
  - Timestamp
  
- **CurveConfig**: Cấu hình đường cong
  - Tên, đơn vị, màu sắc
  - Scale min/max
  - Channel index
  
- **DataPoint**: Điểm dữ liệu (timestamp, value)

### Services
- **DataSource**: Interface cho các nguồn dữ liệu
- **UsbDataSource**: Giao tiếp USB Serial
  - Baudrate: 19200
  - Data bits: 8
  - Stop bits: 1
  - Parity: None
  
- **SocketDataSource**: Giao tiếp TCP Socket
  - Nhận từ ESP32
  - Cấu hình host và port
  
- **DataService**: Quản lý nhận và parse dữ liệu
  - Buffer ghép frame
  - Stream DataFrame
  - Quản lý data buffer cho các curve

### Widgets
- **CurveChartPainter**: CustomPainter vẽ đường cong
  - Grid
  - Multiple curves với màu sắc khác nhau
  - Trục thời gian dọc (Y)
  - Trục giá trị ngang (X)
  
- **RealtimeCurveChart**: Widget hiển thị chart realtime
  - Auto update
  - Legend với giá trị latest
  - Time window configurable
  
- **ConnectionSettingsWidget**: Cấu hình kết nối
  - Chọn USB/Socket
  - Cài đặt tham số
  - Nút kết nối/ngắt

## Format Frame Data

Frame data: 68 bytes
```
[Header][Channel0-14][TempFreq][PressFreq][Tailer]
0xAA    1-60 bytes   61-62      63-65      0x55
```

- **Header**: 0xAA (byte 0)
- **Channels**: 15 kênh x 4 bytes (bytes 1-60)
- **Temperature Frequency**: bytes 61-62
- **Pressure Frequency**: bytes 63-65
- **Tailer**: 0x55 (byte 67)

## Cài đặt

```bash
# Clone project
cd mft_monitor_flutter

# Cài đặt dependencies
flutter pub get

# Chạy trên Windows
flutter run -d windows

# Chạy trên Android (cần bật USB debugging)
flutter run -d android
```

## Cấu hình Curves mặc định

1. **HPRS** - Hydraulic Pressure (PSI) - Red
2. **HTEM** - Hydraulic Temperature (°C) - Orange
3. **SPRS** - Sample Pressure (PSI) - Blue
4. **STEM** - Sample Temperature (°C) - Cyan
5. **MVOL** - Motor Voltage (V) - Green

## Yêu cầu

- Flutter SDK >= 3.8.1
- Dart SDK >= 3.8.1

## Dependencies

- `usb_serial: ^0.5.3` - USB Serial communication

## USB Permissions (Android)

Thêm vào `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-feature android:name="android.hardware.usb.host" />
<uses-permission android:name="android.permission.USB_PERMISSION" />
```

## Sử dụng

1. **Kết nối thiết bị**:
   - Chọn loại kết nối (USB hoặc Socket)
   - USB: Cắm thiết bị và nhấn "Kết nối"
   - Socket: Nhập IP và Port của ESP32, nhấn "Kết nối"

2. **Xem dữ liệu**:
   - Các đường cong sẽ tự động hiển thị khi có dữ liệu
   - Trục Y: Thời gian từ trên xuống
   - Trục X: Giá trị theo scale của từng curve

3. **Cấu hình**:
   - Icon timeline: Bật/tắt các curve
   - Icon clock: Chọn cửa sổ thời gian (30s, 1m, 5m, 10m, 30m)
   - Icon clear: Xóa tất cả dữ liệu

## Tham khảo

Project này được xây dựng dựa trên phân tích từ MFT3 C++ project.
