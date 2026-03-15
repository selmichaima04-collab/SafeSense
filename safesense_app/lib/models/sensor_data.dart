class SensorData {
  final double temperature;
  final double humidity;
  final int heartRate;
  final int spo2;
  final double accX;
  final double accY;
  final double accZ;
  final bool fall;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.heartRate,
    required this.spo2,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.fall,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    // Helper to extract double from various formats
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return SensorData(
      temperature: toDouble(map['temperature'] ?? map['temp']),
      humidity: toDouble(map['humidity'] ?? map['hum']),
      heartRate: map['heartRate'] ?? map['hr'] ?? map['bpm'] ?? 0,
      spo2: map['spo2'] ?? map['ox'] ?? 0,
      accX: toDouble(map['accX'] ?? map['ax'] ?? map['x']),
      accY: toDouble(map['accY'] ?? map['ay'] ?? map['y']),
      accZ: toDouble(map['accZ'] ?? map['az'] ?? map['z']),
      fall: map['fall'] ?? map['isFall'] ?? false,
    );
  }
}
