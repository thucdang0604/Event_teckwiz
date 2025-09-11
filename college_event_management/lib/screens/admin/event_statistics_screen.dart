import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/event_statistics_model.dart';
import '../../constants/app_colors.dart';

class EventStatisticsScreen extends StatefulWidget {
  const EventStatisticsScreen({super.key});

  @override
  State<EventStatisticsScreen> createState() => _EventStatisticsScreenState();
}

class _EventStatisticsScreenState extends State<EventStatisticsScreen> {
  String _selectedLocation = 'all';
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadEventStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê sự kiện'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin-dashboard'),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<EventStatisticsModel> filteredStats = _filterStatistics(
            adminProvider.eventStatistics,
          );

          return Column(
            children: [
              _buildFilters(),
              Expanded(
                child: filteredStats.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có dữ liệu thống kê',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredStats.length,
                        itemBuilder: (context, index) {
                          final stat = filteredStats[index];
                          return _buildStatCard(stat);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Vị trí: '),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Text('Thời gian: '),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'week', child: Text('Tuần')),
                    DropdownMenuItem(value: 'month', child: Text('Tháng')),
                    DropdownMenuItem(value: 'year', child: Text('Năm')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(EventStatisticsModel stat) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.eventTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vị trí: ${stat.location}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Ngày: ${_formatDate(stat.eventDate)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Đăng ký',
                    '${stat.totalRegistrations}',
                    Icons.person_add,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tham dự dự kiến',
                    '${stat.expectedAttendees}',
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tham dự thực tế',
                    '${stat.actualAttendees}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Tỷ lệ tham dự',
                    '${stat.attendanceRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Chênh lệch',
                    '${stat.expectedAttendees - stat.actualAttendees}',
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stat.attendanceRate / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                stat.attendanceRate >= 80
                    ? Colors.green
                    : stat.attendanceRate >= 60
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<EventStatisticsModel> _filterStatistics(
    List<EventStatisticsModel> stats,
  ) {
    return stats.where((stat) {
      bool matchesLocation =
          _selectedLocation == 'all' || stat.location == _selectedLocation;

      DateTime now = DateTime.now();
      bool matchesPeriod = true;

      switch (_selectedPeriod) {
        case 'week':
          matchesPeriod = stat.eventDate.isAfter(
            now.subtract(const Duration(days: 7)),
          );
          break;
        case 'month':
          matchesPeriod = stat.eventDate.isAfter(
            now.subtract(const Duration(days: 30)),
          );
          break;
        case 'year':
          matchesPeriod = stat.eventDate.isAfter(
            now.subtract(const Duration(days: 365)),
          );
          break;
      }

      return matchesLocation && matchesPeriod;
    }).toList();
  }
}
