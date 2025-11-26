# PIC 50-byte Frame - Curve Mapping

## Frame Structure
Total: 50 bytes (48 data + 2 tailers)

```
Byte Range | Description                      | Channel Index | Curve Name
-----------|----------------------------------|---------------|------------------
0          | Sign bit                         | -             | -
1-6        | Depth BCD                        | -             | (BCD parsed separately)
7-11       | Tension BCD                      | -             | (BCD parsed separately)
12-15      | Speed BCD                        | -             | (BCD parsed separately)
16-19      | Raw sdepth (32-bit signed)       | 8             | Raw Depth (RDEP)
20-21      | ADC[0] Tension (16-bit)          | 0             | Tension (TENS)
22-23      | ADC[1] Magnetometer              | 1             | Magnetometer (MAG)
24-25      | ADC[2] Reserved                  | 2             | -
26-27      | ADC[3] N-VAC                     | 3             | Voltage AC (VAC)
28-29      | ADC[4] N-IAC                     | 4             | Current AC (IAC)
30-31      | ADC[5] Unused                    | 5             | -
32-33      | ADC[6] N-VDC                     | 6             | Voltage DC (VDC)
34-35      | ADC[7] N-IDC                     | 7             | Current DC (IDC)
36-39      | Encoder depth PIC12F675 (32-bit) | 9             | Encoder Depth (EDEP)
40-41      | Delta time (timer×100ms)         | 10            | Delta Time (DTIME)
42-47      | Unused                           | -             | -
48-49      | Tailers (0xAA 0xAA)              | -             | -
```

## Active Curves (Default Configuration)

| Curve | Mnemonic | Name            | Unit | Channel | Color  | Scale    |
|-------|----------|-----------------|------|---------|--------|----------|
| 1     | TENS     | Tension         | kg   | 0       | Red    | 0-1024   |
| 2     | MAG      | Magnetometer    | ADC  | 1       | Purple | 0-1024   |
| 3     | VAC      | Voltage AC      | V    | 3       | Blue   | 0-1024   |
| 4     | IAC      | Current AC      | A    | 4       | Cyan   | 0-1024   |
| 5     | VDC      | Voltage DC      | V    | 6       | Green  | 0-1024   |
| 6     | IDC      | Current DC      | A    | 7       | Lime   | 0-1024   |
| 7     | RDEP     | Raw Depth       | m    | 8       | Orange | 0-5000   |
| 8     | EDEP     | Encoder Depth   | m    | 9       | Brown  | 0-5000   |
| 9     | DTIME    | Delta Time      | ms   | 10      | Pink   | 0-10000  |

## Gauge Panel Mapping

The left panel displays gauge widgets using the same channel data:

| Widget          | Left Gauge          | Right Gauge         |
|-----------------|---------------------|---------------------|
| Depth & Speed   | Encoder Depth (ch9) | Calculated Speed    |
| Tension & Mag   | Tension (ch0)       | Magnetometer (ch1)  |
| AC Power        | Voltage AC (ch3)    | Current AC (ch4)    |
| DC Power        | Voltage DC (ch6)    | Current DC (ch7)    |

## Data Flow

1. **Reception**: 50 bytes received via Socket/USB Serial
2. **Parsing**: `DataFrame.fromPIC()` extracts:
   - 8 ADC channels (ch0-7)
   - Raw sdepth (ch8)
   - Encoder depth (ch9)
   - Delta time (ch10)
3. **Processing**: `DataProcessor.processFrame()` calculates display values
4. **Display**:
   - Gauges: Show real-time values
   - Chart: Plots time-series data for selected curves
5. **Storage**: `CurveDataBuffer` stores up to 1000 points per channel

## Notes

- **BCD Fields** (bytes 1-15): Currently not displayed in curves, but available for future enhancement
- **Reserved/Unused Channels** (ch2, ch5, ch11-14): Padded with zeros, not displayed
- **Delta Time** (ch10): Disabled by default in curve settings
- **Auto-detection**: System automatically switches between MFT3 (68-byte) and PIC (50-byte) modes
