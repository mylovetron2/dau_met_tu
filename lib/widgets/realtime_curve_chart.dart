import 'dart:async';

import 'package:flutter/material.dart';

import '../models/curve_config.dart';
import '../models/data_point.dart';
import '../services/data_service.dart';
import 'curve_chart_painter.dart';

/// Widget hiển thị các đường cong realtime
class RealtimeCurveChart extends StatefulWidget {
  final DataService dataService;
  final List<CurveConfig> curves;
  final Duration timeWindow;
  final Duration updateInterval;

  const RealtimeCurveChart({
    Key? key,
    required this.dataService,
    required this.curves,
    this.timeWindow = const Duration(minutes: 5),
    this.updateInterval = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<RealtimeCurveChart> createState() => _RealtimeCurveChartState();
}

class _RealtimeCurveChartState extends State<RealtimeCurveChart> {
  final Map<int, List<DataPoint>> _curveData = {};
  Timer? _updateTimer;
  StreamSubscription? _frameSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCurveData();
    _listenToFrames();
    _startUpdateTimer();
  }

  void _initializeCurveData() {
    for (var curve in widget.curves) {
      _curveData[curve.channelIndex] = [];
    }
  }

  void _listenToFrames() {
    _frameSubscription = widget.dataService.frameStream.listen((frame) {
      // Thêm data point cho từng curve
      for (var curve in widget.curves) {
        if (curve.channelIndex < frame.channels.length) {
          final value = frame.channels[curve.channelIndex].toDouble();
          final point = DataPoint(timestamp: frame.timestamp, value: value);

          // Thêm vào buffer service
          widget.dataService.addDataPoint(curve.channelIndex, point);

          // Thêm vào local data
          if (!_curveData.containsKey(curve.channelIndex)) {
            _curveData[curve.channelIndex] = [];
          }
          _curveData[curve.channelIndex]!.add(point);

          // Giới hạn số điểm
          if (_curveData[curve.channelIndex]!.length > 1000) {
            _curveData[curve.channelIndex]!.removeAt(0);
          }
        }
      }
    });
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(widget.updateInterval, (timer) {
      if (mounted) {
        setState(() {
          // Xóa các điểm cũ ngoài time window
          final now = DateTime.now();
          final startTime = now.subtract(widget.timeWindow);

          _curveData.forEach((key, points) {
            points.removeWhere((point) => point.timestamp.isBefore(startTime));
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _frameSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Header với thông tin
          _buildHeader(),

          // Chart
          Expanded(
            child: CustomPaint(
              painter: CurveChartPainter(
                curves: widget.curves,
                curveData: _curveData,
                timeWindow: widget.timeWindow,
                showGrid: true,
              ),
              child: Container(),
            ),
          ),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Realtime Curves',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Time Window: ${widget.timeWindow.inMinutes} min',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 8.0,
        children: widget.curves
            .where((curve) => curve.isActive)
            .map((curve) => _buildLegendItem(curve))
            .toList(),
      ),
    );
  }

  Widget _buildLegendItem(CurveConfig curve) {
    final latestValue = _curveData[curve.channelIndex]?.isNotEmpty == true
        ? _curveData[curve.channelIndex]!.last.value.toStringAsFixed(2)
        : '--';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 3, color: curve.color),
        const SizedBox(width: 4),
        Text(
          '${curve.mnemonic}: $latestValue ${curve.unit}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
