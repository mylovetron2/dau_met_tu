import 'dart:async';

import 'package:flutter/material.dart';

import 'models/curve_config.dart';
import 'models/display_info.dart';
import 'services/data_service.dart';
import 'widgets/connection_settings_widget.dart';
import 'widgets/gauge_widgets.dart';
import 'widgets/realtime_curve_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFT Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MFTMonitorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MFTMonitorPage extends StatefulWidget {
  const MFTMonitorPage({super.key});

  @override
  State<MFTMonitorPage> createState() => _MFTMonitorPageState();
}

class _MFTMonitorPageState extends State<MFTMonitorPage> {
  final DataService _dataService = DataService();
  late List<CurveConfig> _curves;
  Duration _timeWindow = const Duration(minutes: 5);
  DisplayInfo? _currentDisplayInfo;
  StreamSubscription? _frameSubscription;

  // Depth tracking for speed calculation
  double _prevDepth = 0.0;
  DateTime _prevTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _curves = DefaultCurves.defaults;
    _listenToFrames();
  }

  void _listenToFrames() {
    _frameSubscription = _dataService.frameStream.listen((frame) {
      setState(() {
        _currentDisplayInfo = DataProcessor.processFrame(frame);

        // Calculate speed (depth change per minute)
        final now = DateTime.now();
        final timeDiff = now.difference(_prevTime).inMilliseconds;
        if (timeDiff >= 2000) {
          // Update every 2 seconds
          final depthDiff = (_currentDisplayInfo!.depth - _prevDepth).abs();
          final speed = (depthDiff * 60000.0) / timeDiff; // m/min
          _currentDisplayInfo = _currentDisplayInfo!.copyWith(speed: speed);
          _prevDepth = _currentDisplayInfo!.depth;
          _prevTime = now;
        }
      });
    });
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _dataService.dispose();
    super.dispose();
  }

  void _showCurveSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cài đặt đường cong'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: ListView.builder(
            itemCount: _curves.length,
            itemBuilder: (context, index) {
              final curve = _curves[index];
              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: curve.isActive,
                    onChanged: (value) {
                      setState(() {
                        _curves[index] = curve.copyWith(isActive: value);
                      });
                    },
                  ),
                  title: Text('${curve.name} (${curve.mnemonic})'),
                  subtitle: Text(
                    '${curve.unit} - Channel ${curve.channelIndex}',
                  ),
                  trailing: Container(
                    width: 40,
                    height: 20,
                    color: curve.color,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showTimeWindowSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cài đặt cửa sổ thời gian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Duration>(
              title: const Text('30 giây'),
              value: const Duration(seconds: 30),
              groupValue: _timeWindow,
              onChanged: (value) {
                setState(() {
                  _timeWindow = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<Duration>(
              title: const Text('1 phút'),
              value: const Duration(minutes: 1),
              groupValue: _timeWindow,
              onChanged: (value) {
                setState(() {
                  _timeWindow = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<Duration>(
              title: const Text('5 phút'),
              value: const Duration(minutes: 5),
              groupValue: _timeWindow,
              onChanged: (value) {
                setState(() {
                  _timeWindow = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<Duration>(
              title: const Text('10 phút'),
              value: const Duration(minutes: 10),
              groupValue: _timeWindow,
              onChanged: (value) {
                setState(() {
                  _timeWindow = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<Duration>(
              title: const Text('30 phút'),
              value: const Duration(minutes: 30),
              groupValue: _timeWindow,
              onChanged: (value) {
                setState(() {
                  _timeWindow = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('MFT Monitor - Flutter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: 'Cài đặt đường cong',
            onPressed: _showCurveSettings,
          ),
          IconButton(
            icon: const Icon(Icons.access_time),
            tooltip: 'Cài đặt thời gian',
            onPressed: _showTimeWindowSettings,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Xóa dữ liệu',
            onPressed: () {
              setState(() {
                _dataService.clearAllBuffers();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Phần cài đặt kết nối
          ConnectionSettingsWidget(
            dataService: _dataService,
            onConnectionChanged: () {
              setState(() {});
            },
          ),

          const SizedBox(height: 8),

          // Phần chính: Panel bên trái + Chart bên phải
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel bên trái - Hiển thị thông tin
                  SizedBox(
                    width: 350,
                    child: SingleChildScrollView(child: _buildInfoPanel()),
                  ),

                  const SizedBox(width: 8),

                  // Chart bên phải
                  Expanded(
                    child: RealtimeCurveChart(
                      dataService: _dataService,
                      curves: _curves,
                      timeWindow: _timeWindow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    if (_currentDisplayInfo == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: Text('Chờ dữ liệu...', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    final info = _currentDisplayInfo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Depth & Speed
        DepthSpeedDisplay(depth: info.depth, speed: info.speed),

        const SizedBox(height: 8),

        // Tension & Magnetometer (từ PIC ADC[0-1])
        DualGauge(
          title: 'Tension & Mag',
          tempLabel: 'Tension',
          tempValue: info.hydraulicPress, // ADC[0] - Sức căng
          tempMin: 0,
          tempMax: 1024,
          tempUnit: 'kg',
          pressLabel: 'Magnetometer',
          pressValue: info.quartzPress, // ADC[1] - Từ trường
          pressMin: 0,
          pressMax: 1024,
          pressUnit: 'ADC',
        ),

        const SizedBox(height: 8),

        // AC Power (từ PIC ADC[3-4])
        DualGauge(
          title: 'AC Power',
          tempLabel: 'Voltage AC',
          tempValue: info.hydraulicTemp, // ADC[3] - N-VAC
          tempMin: 0,
          tempMax: 1024,
          tempUnit: 'ADC',
          pressLabel: 'Current AC',
          pressValue: info.sampleTemp, // ADC[4] - N-IAC
          pressMin: 0,
          pressMax: 1024,
          pressUnit: 'ADC',
        ),

        const SizedBox(height: 8),

        // DC Power (từ PIC ADC[6-7])
        DualGauge(
          title: 'DC Power',
          tempLabel: 'Voltage DC',
          tempValue: info.samplePress, // ADC[6] - N-VDC
          tempMin: 0,
          tempMax: 1024,
          tempUnit: 'ADC',
          pressLabel: 'Current DC',
          pressValue: info.quartzTemp, // ADC[7] - N-IDC
          pressMin: 0,
          pressMax: 1024,
          pressUnit: 'ADC',
        ),
      ],
    );
  }
}
