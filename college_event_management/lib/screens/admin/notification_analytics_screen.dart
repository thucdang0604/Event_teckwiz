import 'package:flutter/material.dart';
import '../../services/unified_notification_service.dart';
import '../../constants/app_colors.dart';

class NotificationAnalyticsScreen extends StatefulWidget {
  const NotificationAnalyticsScreen({super.key});

  @override
  State<NotificationAnalyticsScreen> createState() =>
      _NotificationAnalyticsScreenState();
}

class _NotificationAnalyticsScreenState
    extends State<NotificationAnalyticsScreen> {
  final UnifiedNotificationService _notificationService =
      UnifiedNotificationService();

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _notificationService.getNotificationStats(
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      print('Error loading stats: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê thông báo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeSelector(),
                  const SizedBox(height: 24),
                  _buildOverviewCards(),
                  const SizedBox(height: 24),
                  _buildSuccessRateChart(),
                  const SizedBox(height: 24),
                  _buildTypeStatsChart(),
                  const SizedBox(height: 24),
                  _buildChannelStatsChart(),
                  const SizedBox(height: 24),
                  _buildRecentNotifications(),
                ],
              ),
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Khoảng thời gian',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _selectDateRange,
              child: const Text('Thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalSent = _stats['totalSent'] ?? 0;
    final successCount = _stats['successCount'] ?? 0;
    final failCount = _stats['failCount'] ?? 0;
    final successRate = _stats['successRate'] ?? '0.00';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tổng gửi',
            totalSent.toString(),
            Icons.send,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Thành công',
            successCount.toString(),
            Icons.check_circle,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Thất bại',
            failCount.toString(),
            Icons.error,
            AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tỷ lệ thành công',
            '$successRate%',
            Icons.trending_up,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateChart() {
    final successCount = _stats['successCount'] ?? 0;
    final failCount = _stats['failCount'] ?? 0;
    final total = successCount + failCount;

    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Không có dữ liệu')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tỷ lệ thành công',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            successCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Thành công'),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            failCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Thất bại'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeStatsChart() {
    final typeStats = _stats['typeStats'] as Map<String, int>? ?? {};

    if (typeStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Không có dữ liệu')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê theo loại',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...typeStats.entries.map((entry) {
              final type = _getTypeDisplayName(entry.key);
              final count = entry.value;
              final total = typeStats.values.reduce((a, b) => a + b);
              final percentage = (count / total * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(type)),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: count / total,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTypeColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$count ($percentage%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelStatsChart() {
    final channelStats = _stats['channelStats'] as Map<String, int>? ?? {};

    if (channelStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Không có dữ liệu')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê theo kênh',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: channelStats.length,
                itemBuilder: (context, index) {
                  final entry = channelStats.entries.elementAt(index);
                  final maxValue = channelStats.values.reduce(
                    (a, b) => a > b ? a : b,
                  );
                  final height = (entry.value / maxValue) * 150;

                  return Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height,
                          width: 40,
                          decoration: BoxDecoration(
                            color: _getChannelColor(entry.key),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getChannelDisplayName(entry.key),
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotifications() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông báo gần đây',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tính năng này sẽ hiển thị danh sách thông báo gần đây',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'eventCreated':
        return 'Sự kiện mới';
      case 'eventUpdated':
        return 'Cập nhật sự kiện';
      case 'eventCancelled':
        return 'Hủy sự kiện';
      case 'registrationConfirmed':
        return 'Xác nhận đăng ký';
      case 'registrationCancelled':
        return 'Hủy đăng ký';
      case 'eventReminder':
        return 'Nhắc nhở sự kiện';
      case 'systemAnnouncement':
        return 'Thông báo hệ thống';
      case 'chatMessage':
        return 'Tin nhắn chat';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'eventCreated':
        return AppColors.primary;
      case 'eventUpdated':
        return AppColors.warning;
      case 'eventCancelled':
        return AppColors.error;
      case 'registrationConfirmed':
        return AppColors.success;
      case 'registrationCancelled':
        return AppColors.error;
      case 'eventReminder':
        return Colors.orange;
      case 'systemAnnouncement':
        return Colors.purple;
      case 'chatMessage':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getChannelDisplayName(String channel) {
    switch (channel) {
      case 'push':
        return 'Push';
      case 'email':
        return 'Email';
      case 'email_scheduled':
        return 'Email (Lên lịch)';
      default:
        return channel;
    }
  }

  Color _getChannelColor(String channel) {
    switch (channel) {
      case 'push':
        return AppColors.primary;
      case 'email':
        return AppColors.success;
      case 'email_scheduled':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }
}
