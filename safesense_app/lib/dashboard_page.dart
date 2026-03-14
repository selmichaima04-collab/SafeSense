import 'package:flutter/material.dart';
import 'data/firebase_service.dart';
import 'models/sensor_data.dart';
import 'widgets/sensor_card.dart';
import 'notifications/notification_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  
  List<FlSpot> heartRateSpots = [];
  List<FlSpot> tempSpots = [];
  int _timeCounter = 0;
  DateTime? _lastUpdateTime;
  SensorData? _lastData;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
  }

  void _updateCharts(SensorData data) {
    if (_lastData == data) return;
    
    if (mounted) {
      setState(() {
        _lastData = data;
        _timeCounter++;
        _lastUpdateTime = DateTime.now();
        heartRateSpots.add(FlSpot(_timeCounter.toDouble(), data.heartRate.toDouble()));
        tempSpots.add(FlSpot(_timeCounter.toDouble(), data.temperature));

        if (heartRateSpots.length > 20) heartRateSpots.removeAt(0);
        if (tempSpots.length > 20) tempSpots.removeAt(0);
      });
    }

    if (data.fall) {
      _notificationService.showNotification("⚠️ FALL DETECTED", "A fall has been detected! Please check.");
    }
    if (data.heartRate > 120) {
      _notificationService.showNotification("⚠️ High Heart Rate", "Heart rate is abnormally high: ${data.heartRate} BPM.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('SafeSense', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: StreamBuilder<SensorData>(
        stream: _firebaseService.getSensorDataStream(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? _lastData;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: data == null
                ? const Center(
                    key: ValueKey('loading_state'),
                    child: CircularProgressIndicator(),
                  )
                : _buildDashboardContent(data),
          );
        },
      ),
    );
  }

  Widget _buildDashboardContent(SensorData data) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCharts(data));

    return SingleChildScrollView(
      key: const ValueKey('dashboard_content'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          
          if (data.fall || data.heartRate > 120)
            _buildAlertBanner(data),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              SensorCard(
                title: "Heart Rate",
                value: "${data.heartRate} BPM",
                icon: Icons.favorite,
                color: Colors.redAccent,
              ),
              SensorCard(
                title: "SpO2",
                value: "${data.spo2} %",
                icon: Icons.air,
                color: Colors.blueAccent,
              ),
              SensorCard(
                title: "Temperature",
                value: "${data.temperature.toStringAsFixed(1)} °C",
                icon: Icons.thermostat,
                color: Colors.orangeAccent,
              ),
              SensorCard(
                title: "Humidity",
                value: "${data.humidity.toStringAsFixed(1)} %",
                icon: Icons.water_drop,
                color: Colors.cyan,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader("Live Monitoring", Icons.analytics),
          const SizedBox(height: 16),
          _buildChartCard("Heart Rate History", heartRateSpots, Colors.redAccent),
          const SizedBox(height: 16),
          _buildChartCard("Temperature History", tempSpots, Colors.orangeAccent),

          const SizedBox(height: 32),
          _buildSectionHeader("Movement Data", Icons.directions_walk),
          const SizedBox(height: 16),
          _buildAccelerationCard(data),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Health Overview",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
            ),
            if (_lastUpdateTime != null)
              Text(
                "Last updated: ${DateFormat('HH:mm:ss').format(_lastUpdateTime!)}",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text("Live", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildAlertBanner(SensorData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.fall)
                  const Text("FALL DETECTED!", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                if (data.heartRate > 120)
                  Text("High Heart Rate: ${data.heartRate} BPM", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
      ],
    );
  }

  Widget _buildChartCard(String title, List<FlSpot> spots, Color color) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 20),
          Expanded(
            child: spots.length < 2
                ? Center(
                    child: Text(
                      "Collecting data...",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  )
                : LineChart(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.linear,
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.1),
                          ),
                        ),
                      ],
                      titlesData: const FlTitlesData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[100]!, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      // Add min/max to ensure stable bounds during initialization
                      minX: spots.first.x,
                      maxX: spots.last.x,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccelerationCard(SensorData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAxisData("X-Axis", data.accX, Colors.purple),
          _buildAxisData("Y-Axis", data.accY, Colors.indigo),
          _buildAxisData("Z-Axis", data.accZ, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildAxisData(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
