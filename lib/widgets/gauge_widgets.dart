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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            // Depth section
            Expanded(
              child: _buildMetricCard(
                icon: Icons.straighten,
                label: 'DEPTH',
                value: depth.toStringAsFixed(1),
                unit: depthUnit,
                valueColor: Colors.white,
              ),
            ),
            Container(
              width: 1.5,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            // Speed section
            Expanded(
              child: _buildMetricCard(
                icon: Icons.speed,
                label: 'SPEED',
                value: speed.toStringAsFixed(2),
                unit: speedUnit,
                valueColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 12),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget hiển thị AC hoặc DC Power (Voltage & Current)
class PowerDisplay extends StatelessWidget {
  final String title; // 'AC Power' hoặc 'DC Power'
  final double voltage;
  final double current;
  final String voltageUnit;
  final String currentUnit;
  final Color? backgroundColor;

  const PowerDisplay({
    Key? key,
    required this.title,
    required this.voltage,
    required this.current,
    this.voltageUnit = 'ADC',
    this.currentUnit = 'ADC',
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Chọn màu gradient dựa trên title
    final isAC = title.contains('AC');
    final gradientColors = isAC
        ? [Colors.amber[700]!, Colors.amber[500]!]
        : [Colors.purple[700]!, Colors.purple[500]!];
    final shadowColor = isAC ? Colors.amber : Colors.purple;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Title with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAC ? Icons.flash_on : Icons.battery_charging_full,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Voltage & Current in row
            Row(
              children: [
                // Voltage
                Expanded(
                  child: _buildPowerMetric(
                    icon: Icons.electrical_services,
                    label: 'VOLTAGE',
                    value: voltage.toStringAsFixed(0),
                    unit: voltageUnit,
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 35,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                // Current
                Expanded(
                  child: _buildPowerMetric(
                    icon: Icons.power,
                    label: 'CURRENT',
                    value: current.toStringAsFixed(0),
                    unit: currentUnit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerMetric({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 11),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
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
