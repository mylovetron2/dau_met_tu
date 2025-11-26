# Tài liệu Hệ thống MFT Monitor Flutter

## Tổng quan Hệ thống

Ứng dụng MFT Monitor Flutter được phát triển dựa trên phân tích từ project MFT3 C++. Hệ thống giám sát dữ liệu realtime từ thiết bị đo qua giao tiếp USB UART hoặc Socket TCP/IP.

## Kiến trúc Tổng thể

```
┌─────────────────────────────────────────────────────────┐
│                    MFT Monitor App                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────┐         ┌─────────────────┐        │
│  │ Connection UI  │◄───────►│  DataService    │        │
│  └────────────────┘         └────────┬────────┘        │
│                                      │                  │
│  ┌────────────────┐                 │                  │
│  │ Chart Widget   │◄────────────────┘                  │
│  └────────────────┘                                     │
│         ▲                                               │
│         │                                               │
│    ┌────┴────┐                                         │
│    │ Painter │                                         │
│    └─────────┘                                         │
└─────────────────────────────────────────────────────────┘
         ▲                    ▲
         │                    │
    ┌────┴──────┐      ┌─────┴──────┐
    │ USB UART  │      │   Socket   │
    │  Device   │      │   ESP32    │
    └───────────┘      └────────────┘
```

## Các Lớp Chính

### 1. Data Models

#### DataFrame
```dart
class DataFrame {
  final int header;              // 0xAA
  final int tailer;              // 0x55
  final List<int> channels;      // 15 kênh đo
  final double temperatureFreq;  // Tần số nhiệt độ
  final double pressureFreq;     // Tần số áp suất
  final DateTime timestamp;      // Thời điểm nhận
}
```

**Chức năng**:
- Parse 68 bytes từ thiết bị
- Validate header/tailer
- Chuyển đổi raw bytes sang giá trị

**Frame Format**:
```
Byte 0:       Header (0xAA)
Byte 1-60:    15 channels × 4 bytes
Byte 61-62:   Temperature frequency
Byte 63-65:   Pressure frequency  
Byte 67:      Tailer (0x55)
```

#### CurveConfig
```dart
class CurveConfig {
  final String mnemonic;     // Tên viết tắt (VD: HPRS)
  final String name;         // Tên đầy đủ
  final String unit;         // Đơn vị (PSI, °C)
  final int channelIndex;    // Kênh data (0-14)
  final bool isActive;       // Hiển thị hay không
  final double leftScale;    // Giá trị min
  final double rightScale;   // Giá trị max
  final Color color;         // Màu đường cong
  final double width;        // Độ rộng
}
```

**Chức năng**:
- Cấu hình hiển thị cho mỗi curve
- Mapping channel đến curve
- Scale giá trị

#### DataPoint
```dart
class DataPoint {
  final DateTime timestamp;
  final double value;
}
```

### 2. Data Services

#### DataSource (Abstract)
Interface cho các nguồn dữ liệu:
```dart
abstract class DataSource {
  Future<bool> connect();
  Future<void> disconnect();
  Stream<List<int>> get dataStream;
  bool get isConnected;
  Future<void> send(List<int> data);
}
```

#### UsbDataSource
Giao tiếp USB Serial UART:
- Baudrate: 19200
- Data bits: 8
- Stop bits: 1
- Parity: None

**Workflow**:
1. Tìm thiết bị USB
2. Mở port với config
3. Stream bytes từ thiết bị
4. Gửi lệnh nếu cần

#### SocketDataSource
Giao tiếp TCP Socket (nhận từ ESP32):
- Host: IP address (VD: 192.168.1.100)
- Port: Port number (VD: 8080)

**Workflow**:
1. Connect socket tới host:port
2. Stream bytes từ socket
3. Gửi lệnh nếu cần

#### DataService
Service trung tâm quản lý data:

**Chức năng chính**:
1. **Frame Parsing**: Ghép bytes thành frame 68 bytes
2. **Validation**: Kiểm tra header/tailer
3. **Stream Management**: Emit DataFrame
4. **Buffer Management**: Lưu trữ data points

**Flow nhận dữ liệu**:
```
Raw Bytes → Buffer → Find Header → Validate → Parse → DataFrame
```

### 3. UI Widgets

#### ConnectionSettingsWidget
Widget cấu hình kết nối:

**Features**:
- Toggle USB/Socket
- USB settings: Baudrate
- Socket settings: Host, Port
- Connect/Disconnect button
- Status indicator

#### RealtimeCurveChart
Widget hiển thị chart realtime:

**Features**:
- Auto update với interval 100ms
- Time window (30s, 1m, 5m, 10m, 30m)
- Legend với giá trị latest
- Multiple curves

**Update Strategy**:
- Lắng nghe frameStream
- Thêm data points
- Auto remove old points
- Trigger repaint

#### CurveChartPainter
CustomPainter vẽ đường cong:

**Vẽ các thành phần**:
1. Background
2. Grid (vertical & horizontal)
3. Curves (path cho mỗi curve)
4. Axes

**Coordinate System**:
- Trục X (ngang): Giá trị (left → right)
- Trục Y (dọc): Thời gian (top → bottom)

**Công thức chuyển đổi**:
```dart
// Value → X coordinate
x = (value - minValue) / (maxValue - minValue) * width

// Time → Y coordinate
y = (time - startTime) / (endTime - startTime) * height
```

## Data Flow

### 1. Kết nối thiết bị
```
User → ConnectionSettings → DataService → DataSource → Device
                                            ↓
                                      Connect OK
                                            ↓
                                    Start streaming
```

### 2. Nhận và xử lý dữ liệu
```
Device → Bytes → DataSource.dataStream
                      ↓
               DataService._onDataReceived
                      ↓
               Buffer accumulation
                      ↓
               Find frame (Header 0xAA)
                      ↓
               Validate (Tailer 0x55)
                      ↓
               DataFrame.fromBytes
                      ↓
               frameStream.add
                      ↓
          RealtimeCurveChart (listener)
                      ↓
          Extract channel values
                      ↓
          Add DataPoints
                      ↓
          setState → Repaint
```

### 3. Vẽ chart
```
RealtimeCurveChart.build
         ↓
   CustomPaint
         ↓
CurveChartPainter.paint
         ↓
   For each curve:
     - Convert data points to screen coordinates
     - Draw path
     - Apply color/width
         ↓
   Draw grid
   Draw axes
```

## Cấu hình Curves Mặc định (PIC 50-byte Frame)

```dart
DefaultCurves.defaults = [
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
  // Encoder depth (bytes 36-39)
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
]
```

### Channel Mapping

| Channel | Bytes   | Description              | Curve    | Unit |
|---------|---------|--------------------------|----------|------|
| 0       | 20-21   | ADC[0] Tension           | TENS     | kg   |
| 1       | 22-23   | ADC[1] Magnetometer      | MAG      | ADC  |
| 2       | 24-25   | ADC[2] Reserved          | -        | -    |
| 3       | 26-27   | ADC[3] N-VAC             | VAC      | V    |
| 4       | 28-29   | ADC[4] N-IAC             | IAC      | A    |
| 5       | 30-31   | ADC[5] Unused            | -        | -    |
| 6       | 32-33   | ADC[6] N-VDC             | VDC      | V    |
| 7       | 34-35   | ADC[7] N-IDC             | IDC      | A    |
| 8       | 16-19   | Raw sdepth (32-bit)      | RDEP     | m    |
| 9       | 36-39   | Encoder depth (32-bit)   | EDEP     | m    |
| 10      | 40-41   | Delta time (16-bit)      | DTIME    | ms   |

**Note**: BCD fields (bytes 1-15 for Depth, Tension, Speed) are not displayed in curves but available in the frame structure.

## Performance Optimization

1. **Buffer Management**:
   - Giới hạn maxPoints = 1000
   - Auto remove old points

2. **Update Interval**:
   - Default: 100ms
   - Balance giữa realtime và performance

3. **Repaint Strategy**:
   - shouldRepaint = true (có data mới)
   - Chỉ vẽ curves active

## Mở rộng

### Thêm curve mới
```dart
// 1. Thêm vào DefaultCurves
CurveConfig(
  mnemonic: 'NEWC',
  name: 'New Curve',
  unit: 'Unit',
  channelIndex: 5,
  leftScale: 0,
  rightScale: 100,
  color: Colors.purple,
)
```

### Thêm loại kết nối mới
```dart
// 1. Implement DataSource
class BluetoothDataSource implements DataSource {
  // Implement các methods
}

// 2. Thêm enum
enum ConnectionType {
  usb,
  socket,
  bluetooth,  // Thêm mới
}
```

### Thêm tính năng save/load
```dart
// 1. Serialize DataFrame
String toJson() { /* ... */ }

// 2. Lưu vào file
await File('data.json').writeAsString(json);

// 3. Load từ file
final data = await File('data.json').readAsString();
```

## Testing

### Unit Test
```dart
test('DataFrame.fromBytes parse correctly', () {
  final bytes = List<int>.filled(68, 0);
  bytes[0] = 0xAA;
  bytes[67] = 0x55;
  
  final frame = DataFrame.fromBytes(bytes);
  expect(frame.header, 0xAA);
  expect(frame.tailer, 0x55);
});
```

### Integration Test
```dart
testWidgets('Connect and display data', (tester) async {
  // Mock DataService
  final service = MockDataService();
  
  // Build widget
  await tester.pumpWidget(
    MaterialApp(
      home: RealtimeCurveChart(
        dataService: service,
        curves: DefaultCurves.defaults,
      ),
    ),
  );
  
  // Verify
  expect(find.byType(CustomPaint), findsOneWidget);
});
```

## Troubleshooting

### USB không kết nối được
- Kiểm tra permissions (Android)
- Kiểm tra driver (Windows)
- Thử baudrate khác

### Socket timeout
- Kiểm tra IP/Port
- Kiểm tra firewall
- Ping ESP32

### Chart không hiển thị
- Kiểm tra isActive của curves
- Kiểm tra scale (min/max)
- Kiểm tra data có nhận được không

## References

- Flutter Documentation: https://flutter.dev
- USB Serial Plugin: https://pub.dev/packages/usb_serial
- MFT3 C++ Project: Tại thư mục `d:\MFT3\MFT3\`



void update_data() {
   data[0] = sign bit (0/1)
   data[1-6] = Depth BCD (donvi, chuc, tram, nghin, chucnghin, tramnghin)
   data[7-11] = Tension BCD
   data[12-15] = Speed BCD
   data[16-19] = Raw sdepth (32-bit signed)
   data[20-21] = ADC[0] Tension (16-bit)
   data[22-23] = ADC[1] Magnetometer
   data[24-25] = ADC[2] Reserved
   data[26-27] = ADC[3] N-VAC
   data[28-29] = ADC[4] N-IAC
   data[30-31] = ADC[5]
   data[32-33] = ADC[6] N-VDC
   data[34-35] = ADC[7] N-IDC
   data[36-39] = Raw depth from PIC12F675
   data[40-41] = Delta time (timer*100ms)
   // data[42-47] unused
}