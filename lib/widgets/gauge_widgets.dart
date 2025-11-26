import 'package:flutter/material.dart';

/// Widget hiển thị gauge đơn giản
class SimpleGauge extends StatelessWidget {
  final String label;
  final double value;
  final double minValue;
  final double maxValue;
  final String unit;
  final Color color;

  const SimpleGauge({
    Key? key,
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    this.color = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = ((value - minValue) / (maxValue - minValue)).clamp(
      0.0,
      1.0,
    );

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Bar gauge
          Container(
            height: 30,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Value text
                Center(
                  child: Text(
                    '${value.toStringAsFixed(1)} $unit',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Scale
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minValue.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                maxValue.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị đồng hồ đo kép (Temperature + Pressure)
class DualGauge extends StatelessWidget {
  final String title;
  final String tempLabel;
  final double tempValue;
  final double tempMin;
  final double tempMax;
  final String tempUnit;
  final String pressLabel;
  final double pressValue;
  final double pressMin;
  final double pressMax;
  final String pressUnit;

  const DualGauge({
    Key? key,
    required this.title,
    this.tempLabel = 'Temperature',
    required this.tempValue,
    required this.tempMin,
    required this.tempMax,
    this.tempUnit = '°C',
    this.pressLabel = 'Pressure',
    required this.pressValue,
    required this.pressMin,
    required this.pressMax,
    this.pressUnit = 'PSI',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Divider(),

          // Temperature gauge
          SimpleGauge(
            label: tempLabel,
            value: tempValue,
            minValue: tempMin,
            maxValue: tempMax,
            unit: tempUnit,
            color: Colors.orange,
          ),

          const SizedBox(height: 8),

          // Pressure gauge
          SimpleGauge(
            label: pressLabel,
            value: pressValue,
            minValue: pressMin,
            maxValue: pressMax,
            unit: pressUnit,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị depth và speed
class DepthSpeedDisplay extends StatelessWidget {
  final double depth;
  final double speed;
  final String depthUnit;
  final String speedUnit;

  const DepthSpeedDisplay({
    Key? key,
    required this.depth,
    required this.speed,
    this.depthUnit = 'm',
    this.speedUnit = 'm/min',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue[50],
      ),
      child: Column(
        children: [
          // Depth
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Depth:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${depth.toStringAsFixed(1)} $depthUnit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const Divider(),
          // Speed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Speed:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${speed.toStringAsFixed(2)} $speedUnit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị position và valve status
class PositionDisplay extends StatelessWidget {
  final double position;
  final bool valve1Open;
  final bool valve2Open;
  final double motorVoltage;

  const PositionDisplay({
    Key? key,
    required this.position,
    required this.valve1Open,
    required this.valve2Open,
    required this.motorVoltage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Position & Control',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Divider(),

          // Position bar
          SimpleGauge(
            label: 'Piston Position',
            value: position,
            minValue: 0,
            maxValue: 100,
            unit: '%',
            color: Colors.green,
          ),

          const SizedBox(height: 12),

          // Valves status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildValveIndicator('Valve 1', valve1Open),
              _buildValveIndicator('Valve 2', valve2Open),
            ],
          ),

          const SizedBox(height: 12),

          // Motor voltage
          SimpleGauge(
            label: 'Motor Voltage',
            value: motorVoltage,
            minValue: 0,
            maxValue: 24,
            unit: 'V',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildValveIndicator(String label, bool isOpen) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOpen ? Colors.green : Colors.red,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Icon(
            isOpen ? Icons.check : Icons.close,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isOpen ? 'OPEN' : 'CLOSED',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isOpen ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
