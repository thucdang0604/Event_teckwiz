import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/event_statistics_model.dart';
import '../../constants/app_colors.dart';
import '../../widgets/admin_bottom_navigation_bar.dart';

class EventStatisticsScreen extends StatefulWidget {
  const EventStatisticsScreen({super.key});

  @override
  State<EventStatisticsScreen> createState() => _EventStatisticsScreenState();
}

class _EventStatisticsScreenState extends State<EventStatisticsScreen> {
  String _selectedLocation = 'all';
  String _selectedPeriod = 'month';
  int _currentIndex = 4;
  String _selectedMetric = 'rate';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadEventStatistics();
      context.read<AdminProvider>().loadLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event statistics'),
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
              _buildFilters(adminProvider),
              Expanded(
                child: filteredStats.isEmpty
                    ? const Center(
                        child: Text(
                          'No statistics data',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildOverview(filteredStats),
                          const SizedBox(height: 8),
                          _buildTrendChart(filteredStats),
                          const SizedBox(height: 8),
                          ...filteredStats.map(_buildStatCard).toList(),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: _currentIndex,
      ),
    );
  }

  Widget _buildFilters(AdminProvider adminProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Location: '),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All')),
                    ...adminProvider.locations
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.name,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Text('Period: '),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'week', child: Text('Week')),
                    DropdownMenuItem(value: 'month', child: Text('Month')),
                    DropdownMenuItem(value: 'year', child: Text('Year')),
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Registrations'),
                  selected: _selectedMetric == 'registrations',
                  onSelected: (_) {
                    setState(() {
                      _selectedMetric = 'registrations';
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Attendees'),
                  selected: _selectedMetric == 'attendees',
                  onSelected: (_) {
                    setState(() {
                      _selectedMetric = 'attendees';
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Rate'),
                  selected: _selectedMetric == 'rate',
                  onSelected: (_) {
                    setState(() {
                      _selectedMetric = 'rate';
                    });
                  },
                ),
              ],
            ),
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
              'Location: ${stat.location}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(stat.eventDate)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Registrations',
                    '${stat.totalRegistrations}',
                    Icons.person_add,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Expected attendees',
                    '${stat.expectedAttendees}',
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Actual attendees',
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
                    'Attendance rate',
                    '${stat.attendanceRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Gap',
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

  Widget _buildOverview(List<EventStatisticsModel> stats) {
    final int totalEvents = stats.length;
    final int totalRegistrations = stats.fold(
      0,
      (p, e) => p + e.totalRegistrations,
    );
    final int totalAttendees = stats.fold(0, (p, e) => p + e.actualAttendees);
    final double avgRate = stats.isEmpty
        ? 0
        : stats.map((e) => e.attendanceRate).reduce((a, b) => a + b) /
              stats.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Events',
                    '$totalEvents',
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Registrations',
                    '$totalRegistrations',
                    Icons.person_add,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Attendees',
                    '$totalAttendees',
                    Icons.groups,
                    Colors.teal,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg. rate',
                    '${avgRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<EventStatisticsModel> stats) {
    final Map<DateTime, double> grouped = {};
    for (final s in stats) {
      final d = DateTime(s.eventDate.year, s.eventDate.month, s.eventDate.day);
      double v;
      if (_selectedMetric == 'registrations') {
        v = s.totalRegistrations.toDouble();
      } else if (_selectedMetric == 'attendees') {
        v = s.actualAttendees.toDouble();
      } else {
        v = s.attendanceRate;
      }
      grouped[d] = (grouped[d] ?? 0) + v;
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final double maxValue = _selectedMetric == 'rate'
        ? 100
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedMetric == 'registrations'
                  ? 'Registrations trend'
                  : _selectedMetric == 'attendees'
                  ? 'Attendees trend'
                  : 'Rate trend',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final e in entries) ...[
                      _buildBar(
                        label: '${e.key.day}/${e.key.month}',
                        value: e.value,
                        maxValue: maxValue <= 0 ? 1 : maxValue,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required double value,
    required double maxValue,
  }) {
    final double ratio = value / maxValue;
    final double height = 140 * (ratio.clamp(0, 1));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: height,
          width: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 32,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
