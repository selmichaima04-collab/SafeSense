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
    return SensorData(
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      heartRate: map['heartRate'] ?? 0,
      spo2: map['spo2'] ?? 0,
      accX: (map['accX'] ?? 0.0).toDouble(),
      accY: (map['accY'] ?? 0.0).toDouble(),
      accZ: (map['accZ'] ?? 0.0).toDouble(),
      fall: map['fall'] ?? false,
    );
  }
}
