import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lokasync/presentation/widgets/bottom_navbar.dart';
import 'dart:math';

// Models
class SensorData {
  final String id;
  final String name;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;

  SensorData({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
}

class MonitoringNode {
  final String id;
  final String name;
  final List<SensorData> sensors;

  MonitoringNode({
    required this.id,
    required this.name,
    required this.sensors,
  });
}

// DataSource Interface - Untuk memudahkan implementasi API nanti
abstract class MonitoringDataSource {
  Future<List<MonitoringNode>> getNodes();
  Future<SensorData> getSensorLatestData(String nodeId, String sensorId);
}

// Mock Implementation dari DataSource untuk contoh
class MockMonitoringDataSource implements MonitoringDataSource {
  @override
  Future<List<MonitoringNode>> getNodes() async {
    // Simulasi fetch data dari API
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      MonitoringNode(
        id: 'node1',
        name: 'Node 1',
        sensors: [
          SensorData(
            id: 'temp',
            name: 'Suhu',
            value: 28.5,
            unit: '°C',
            icon: Icons.thermostat,
            color: const Color(0xFF2E7D32),
          ),
          SensorData(
            id: 'humidity',
            name: 'Kelembaban',
            value: 75.8,
            unit: '%',
            icon: Icons.water_drop,
            color: const Color(0xFF1976D2),
          ),
        ],
      ),
      MonitoringNode(
        id: 'node2',
        name: 'Node 2',
        sensors: [
          SensorData(
            id: 'tds',
            name: 'TDS',
            value: 130.5,
            unit: 'PPM',
            icon: Icons.opacity,
            color: const Color(0xFF7B1FA2),
          ),
        ],
      ),
    ];
  }

  @override
  Future<SensorData> getSensorLatestData(String nodeId, String sensorId) async {
    // Simulasi fetch data dari API
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Data dummy
    if (nodeId == 'node1' && sensorId == 'temp') {
      return SensorData(
        id: 'temp',
        name: 'Suhu',
        value: 28.5,
        unit: '°C',
        icon: Icons.thermostat,
        color: const Color(0xFF2E7D32),
      );
    } else if (nodeId == 'node1' && sensorId == 'humidity') {
      return SensorData(
        id: 'humidity',
        name: 'Kelembaban',
        value: 75.8,
        unit: '%',
        icon: Icons.water_drop,
        color: const Color(0xFF1976D2),
      );
    } else {
      return SensorData(
        id: 'tds',
        name: 'TDS',
        value: 130.5,
        unit: 'PPM',
        icon: Icons.opacity,
        color: const Color(0xFF7B1FA2),
      );
    }
  }
}

// Repository - Abstraksi untuk akses data
class MonitoringRepository {
  final MonitoringDataSource dataSource;

  MonitoringRepository({required this.dataSource});

  Future<List<MonitoringNode>> getNodes() async {
    return await dataSource.getNodes();
  }

  Future<SensorData> getSensorLatestData(String nodeId, String sensorId) async {
    return await dataSource.getSensorLatestData(nodeId, sensorId);
  }
}

// View-Model - Untuk komunikasi antara UI dan data
class MonitoringViewModel {
  final MonitoringRepository repository;
  
  MonitoringViewModel({required this.repository});
  
  Future<List<MonitoringNode>> getNodes() async {
    return await repository.getNodes();
  }
  
  Future<SensorData> getSensorLatestData(String nodeId, String sensorId) async {
    return await repository.getSensorLatestData(nodeId, sensorId);
  }
}

// Main Page
class Monitoring extends StatefulWidget {
  const Monitoring({super.key});

  @override
  State<Monitoring> createState() => _MonitoringState();
}

class _MonitoringState extends State<Monitoring> {
  // Dependency Injection
  final MonitoringViewModel _viewModel = MonitoringViewModel(
    repository: MonitoringRepository(
      dataSource: MockMonitoringDataSource(),
    ),
  );

  // Selected state
  String? _selectedNodeId;
  String? _selectedSensorId;
  
  // Data
  List<MonitoringNode> _nodes = [];
  bool _isLoading = true;
  
  // Current index untuk bottom navbar
  final int _currentIndex = 1; // 1 karena Monitoring ada di indeks 1

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _nodes = await _viewModel.getNodes();
      
      if (_nodes.isNotEmpty) {
        _selectedNodeId = _nodes.first.id;
        
        if (_nodes.first.sensors.isNotEmpty) {
          _selectedSensorId = _nodes.first.sensors.first.id;
        }
      }
    } catch (e) {
      // TODO: Handle error with a proper error state
      debugPrint('Error loading monitoring data: ${e.toString()}.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Mendapatkan node yang sedang dipilih
  MonitoringNode? get _selectedNode {
    if (_selectedNodeId == null) return null;
    return _nodes.firstWhere(
      (node) => node.id == _selectedNodeId,
      orElse: () => _nodes.first,
    );
  }
  
  // Mendapatkan sensor yang sedang dipilih
  SensorData? get _selectedSensor {
    final node = _selectedNode;
    if (node == null || _selectedSensorId == null) return null;
    
    try {
      return node.sensors.firstWhere(
        (sensor) => sensor.id == _selectedSensorId,
      );
    } catch (e) {
      return node.sensors.isNotEmpty ? node.sensors.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF014331)))
            : _buildContent(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/profile');
            }
          }
        },
      ),
    );
  }
  
  Widget _buildContent() {
    final node = _selectedNode;
    final sensors = node?.sensors ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Mengatur ukuran minimal untuk menghindari overflow
        children: [
          // Header with back button and node selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF014331)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildNodeDropdown()),
              ],
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Monitoring ${node?.name ?? ""}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF014331),
              ),
            ),
          ),
          
          // Sensor cards - scrollable horizontally
          SizedBox(
            height: 110,
            child: sensors.isEmpty
                ? const Center(
                    child: Text('Tidak ada sensor tersedia untuk node ini'),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sensors.length,
                    itemBuilder: (context, index) {
                      final sensor = sensors[index];
                      return _buildSensorCard(sensor);
                    },
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Visualisasi sensor
          if (_selectedSensor != null)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0), // Tambahkan padding bottom untuk menghindari overflow
                  child: _buildSensorVisualization(_selectedSensor!),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Widget untuk dropdown pemilihan node
  Widget _buildNodeDropdown() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNodeId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF014331)),
          elevation: 0,
          style: GoogleFonts.poppins(
            color: const Color(0xFF014331),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedNodeId) {
              setState(() {
                _selectedNodeId = newValue;
                
                // Reset selected sensor
                final sensors = _nodes
                    .firstWhere((node) => node.id == newValue)
                    .sensors;
                    
                if (sensors.isNotEmpty) {
                  _selectedSensorId = sensors.first.id;
                } else {
                  _selectedSensorId = null;
                }
              });
            }
          },
          items: _nodes.map<DropdownMenuItem<String>>((node) {
            return DropdownMenuItem<String>(
              value: node.id,
              child: Text(node.name),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  // Widget untuk card sensor
  Widget _buildSensorCard(SensorData sensor) {
    final bool isSelected = _selectedSensorId == sensor.id;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSensorId = sensor.id);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [sensor.color, sensor.color.withAlpha(179)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? sensor.color.withAlpha(77)
                  : Colors.grey.shade200,
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sensor.icon,
              color: isSelected ? Colors.white : sensor.color,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              sensor.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF014331),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${sensor.value} ${sensor.unit}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget untuk visualisasi sensor
  Widget _buildSensorVisualization(SensorData sensor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nilai ${sensor.name} Saat Ini',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF014331),
            ),
          ),
          const SizedBox(height: 24),
          
          // Visualisasi sesuai jenis sensor
          if (sensor.name == 'Suhu')
            _buildTemperatureVisualization(sensor)
          else if (sensor.name == 'Kelembaban' || sensor.name == 'TDS')
            _buildCircularVisualization(sensor)
          else
            Text(
              '${sensor.value} ${sensor.unit}',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: sensor.color,
              ),
            ),
        ],
      ),
    );
  }
  
  // Widget visualisasi suhu berbentuk persegi panjang dengan fill dari bawah
  Widget _buildTemperatureVisualization(SensorData sensor) {
    // Nilai suhu dibatasi antara 0-100 derajat Celcius
    final double fillPercentage = (sensor.value / 100).clamp(0.0, 1.0);
    
    return Container(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Container luar (background) dengan border lebih tebal dan gelap
          Container(
            width: 70,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade600, width: 2),
            ),
          ),
          
          // Fill suhu (dari bawah ke atas) - pastikan height tidak melebihi container luar
          Positioned(
            bottom: 25, // Adjusted to be inside the container
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(6),
                bottomRight: const Radius.circular(6),
                topLeft: fillPercentage == 1.0 ? const Radius.circular(6) : Radius.zero,
                topRight: fillPercentage == 1.0 ? const Radius.circular(6) : Radius.zero,
              ),
              child: Container(
                width: 66, // Slightly smaller than outer container
                height: min(150 * fillPercentage, 150), // Ensure it stays within bounds
                color: sensor.color.withOpacity(0.7),
                // Nilai suhu sebagai teks putih di tengah fill area
                child: Center(
                  child: Text(
                    "${(fillPercentage * 100).toInt()}%",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget visualisasi lingkaran untuk kelembaban dan TDS
  Widget _buildCircularVisualization(SensorData sensor) {
    // Tentukan nilai maksimum berdasarkan jenis sensor
    final double maxValue = sensor.name == 'Kelembaban' ? 100.0 : 1000.0;
    final double fillPercentage = (sensor.value / maxValue).clamp(0.0, 1.0);
    
    return SizedBox(
      height: 220,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress background
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sensor.color.withAlpha(30),
            ),
          ),
          
          // Progress indicator
          CustomPaint(
            size: const Size(200, 200),
            painter: CircularProgressPainter(
              progress: fillPercentage,
              progressColor: sensor.color,
              strokeWidth: 15.0,
            ),
          ),
          
          // Value in center
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sensor.value.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: sensor.color,
                ),
              ),
              Text(
                sensor.unit,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          
          // Small indicator dot at top
          Positioned(
            top: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: sensor.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter untuk progress arc
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final double strokeWidth;
  
  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    this.strokeWidth = 8.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const startAngle = -90 * (3.14 / 180); // -90 degrees in radians
    final sweepAngle = 2 * 3.14 * progress;
    
    final paint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}