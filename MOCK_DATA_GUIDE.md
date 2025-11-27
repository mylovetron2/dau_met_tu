# Hướng dẫn sử dụng Mock Data (Dữ liệu giả)

## Tính năng

Mock Data Source cho phép test ứng dụng mà không cần kết nối với thiết bị thật (ESP32/PIC). Tính năng này hữu ích khi:

- Test giao diện và xử lý dữ liệu
- Phát triển offline không có thiết bị
- Demo ứng dụng
- Debug logic mà không phụ thuộc phần cứng

## Cách sử dụng

### 1. Bật chế độ Mock Data

1. Mở ứng dụng
2. Trong phần **Kết nối**, tìm toggle switch **"Dữ liệu giả (Mock)"**
3. Bật switch lên **BẬT**
4. Nhấn nút **Kết nối**

### 2. Chức năng Mock Data

Khi bật Mock Data:

- ✅ **Tự động tạo frame PIC 50 bytes** mỗi 300ms
- ✅ **Các giá trị ADC dao động ngẫu nhiên** để mô phỏng tín hiệu thật
- ✅ **Không cần ESP32 hay thiết bị thật**
- ✅ **Log rõ ràng** với emoji 🎭 để nhận diện

### 3. Dữ liệu được tạo

Mock Data Source tạo các giá trị sau:

| Channel | Tên | Giá trị trung bình | Dao động |
|---------|-----|-------------------|----------|
| ADC0 | Tension | 512 | ±50 |
| ADC1 | Magnetometer | 400 | ±40 |
| ADC3 | VAC | 300 | ±30 |
| ADC4 | IAC | 250 | ±25 |
| ADC6 | VDC | 350 | ±35 |
| ADC7 | IDC | 200 | ±20 |

**Các giá trị khác:**
- Raw Depth: Tăng dần từ 0 → 10000
- Encoder Depth: Tăng chậm từ 0 → 8000
- Delta Time: Random 1-50ms

### 4. Log Console

Khi sử dụng Mock Data, console sẽ hiển thị:

```
🎭 Mock Data Source: Đang kết nối...
✅ Mock Data Source: Kết nối thành công
📥 Nhận 50 bytes: 01 02 01 02 01 04 00 05 03 04 07 06...
✅ Tìm thấy PIC frame (tailers tại bytes 48-49)
✅ PIC frame parsed! Channels: 15
```

### 5. Tắt Mock Data

1. Ngắt kết nối nếu đang connected
2. Tắt switch **"Dữ liệu giả (Mock)"**
3. Chọn USB hoặc Socket như bình thường
4. Kết nối với thiết bị thật

## Code Implementation

### File mới: `mock_data_source.dart`

```dart
class MockDataSource implements DataSource {
  // Tạo dữ liệu giả theo chu kỳ 300ms
  // Mô phỏng PIC frame 50 bytes
}
```

### Thay đổi: `connection_settings_widget.dart`

- Thêm toggle switch cho Mock Data
- Hiển thị icon 🎭 khi dùng Mock
- Ẩn cài đặt USB/Socket khi Mock mode bật

## Lợi ích

✅ **Test nhanh** - Không cần setup phần cứng  
✅ **Phát triển offline** - Code mọi lúc mọi nơi  
✅ **Debug dễ dàng** - Giá trị có thể kiểm soát  
✅ **Demo chuyên nghiệp** - Không lo thiết bị hỏng  

## Note

⚠️ Mock Data chỉ dùng cho mục đích test/demo  
⚠️ Giá trị không chính xác như thiết bị thật  
⚠️ Nhớ tắt Mock khi test với phần cứng thật  
