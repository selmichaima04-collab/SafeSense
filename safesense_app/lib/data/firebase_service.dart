import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  // Fixed: Removed '/SafeSense' from the base URL as it is specified in .ref()
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://safesense-df3ee-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref('SafeSense');

  Stream<SensorData> getSensorDataStream() {
    return _dbRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return SensorData(
          temperature: 0.0,
          humidity: 0.0,
          heartRate: 0,
          spo2: 0,
          accX: 0.0,
          accY: 0.0,
          accZ: 0.0,
          fall: false,
        );
      }
      return SensorData.fromMap(data);
    });
  }
}
