import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/event_model.dart';
import '../../constants/app_colors.dart';
import '../../utils/navigation_helper.dart';

class EventApprovalScreen extends StatefulWidget {
  const EventApprovalScreen({super.key});

  @override
  State<EventApprovalScreen> createState() => _EventApprovalScreenState();
}

class _EventApprovalScreenState extends State<EventApprovalScreen> {
  int _currentIndex = 1;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'date_desc';
  String _timeFilter = 'all';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAllEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin-dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminProvider>().loadAllEvents();
            },
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredSorted = _filterAndSort(adminProvider.allEvents);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: filteredSorted.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildHeader(adminProvider);
              final event = filteredSorted[index - 1];
              return _buildEventCard(event, adminProvider);
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              context.go('/admin-dashboard');
              break;
            case 1:
              context.go('/admin/approvals');
              break;
            case 2:
              context.go('/admin/users');
              break;
            case 3:
              context.go('/admin/locations');
              break;
            case 4:
              context.go('/admin/statistics');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_outlined),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Locations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by title or organizer',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _timeFilter,
                decoration: const InputDecoration(
                  labelText: 'Thời gian',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(
                    value: 'upcoming',
                    child: Text('Sắp diễn ra'),
                  ),
                  DropdownMenuItem(
                    value: 'ongoing',
                    child: Text('Đang diễn ra'),
                  ),
                  DropdownMenuItem(value: 'past', child: Text('Đã qua')),
                  DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                ],
                onChanged: (v) => setState(() => _timeFilter = v ?? 'all'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'published', child: Text('Đã duyệt')),
                  DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                  DropdownMenuItem(value: 'rejected', child: Text('Từ chối')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Hủy bỏ')),
                  DropdownMenuItem(value: 'draft', child: Text('Bản nháp')),
                ],
                onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sắp xếp',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'date_desc',
                    child: Text('Ngày: Mới nhất'),
                  ),
                  DropdownMenuItem(
                    value: 'date_asc',
                    child: Text('Ngày: Cũ nhất'),
                  ),
                  DropdownMenuItem(
                    value: 'title_asc',
                    child: Text('Tiêu đề A-Z'),
                  ),
                  DropdownMenuItem(
                    value: 'title_desc',
                    child: Text('Tiêu đề Z-A'),
                  ),
                ],
                onChanged: (v) => setState(() => _sortBy = v ?? 'date_desc'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (adminProvider.allEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text('No events found', style: TextStyle(fontSize: 16)),
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard(EventModel event, AdminProvider adminProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.go('/event-detail/${event.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(event.status),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Organizer: ${event.organizerName}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Description: ${event.description}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(event.location),
                  const SizedBox(width: 16),
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${event.currentParticipants}/${event.maxParticipants}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(event.startDate)} - ${_formatDate(event.endDate)}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildActionButtons(event, adminProvider),
            ],
          ),
        ),
      ),
    );
  }

  void _approveEvent(EventModel event, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: Text('Approve event "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () =>
                safePop(context, fallbackRoute: '/admin-dashboard'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await adminProvider.approveEvent(event.id);
              if (mounted) {
                safePop(context, fallbackRoute: '/admin-dashboard');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Event approved')));
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(EventModel event, AdminProvider adminProvider) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Event: ${event.title}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                safePop(context, fallbackRoute: '/admin-dashboard'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                await adminProvider.rejectEvent(
                  event.id,
                  reasonController.text,
                );
                if (mounted) {
                  safePop(context, fallbackRoute: '/admin-dashboard');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event rejected')),
                  );
                }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(EventModel event, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event'),
        content: Text(
          'Are you sure you want to cancel event "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              await adminProvider.cancelEvent(event.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event cancelled')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(EventModel event, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to permanently delete event "${event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await adminProvider.deleteEvent(event.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Event deleted')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'draft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'published':
        return 'Published';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'draft':
        return 'Draft';
      default:
        return 'Unknown';
    }
  }

  Widget _buildActionButtons(EventModel event, AdminProvider adminProvider) {
    switch (event.status) {
      case 'pending':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showRejectDialog(event, adminProvider),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _approveEvent(event, adminProvider),
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      case 'published':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCancelDialog(event, adminProvider),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteDialog(event, adminProvider),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      case 'rejected':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _approveEvent(event, adminProvider),
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteDialog(event, adminProvider),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      case 'cancelled':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _approveEvent(event, adminProvider),
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteDialog(event, adminProvider),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteDialog(event, adminProvider),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
    }
  }

  List<EventModel> _filterAndSort(List<EventModel> events) {
    List<EventModel> filtered = events.where((e) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          (e.organizerName.toLowerCase().contains(q));

      final matchesStatus = _statusFilter == 'all' || e.status == _statusFilter;
      final matchesTime = _matchesTimeFilter(e);

      return matchesQuery && matchesStatus && matchesTime;
    }).toList();

    switch (_sortBy) {
      case 'date_asc':
        filtered.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case 'title_asc':
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case 'title_desc':
        filtered.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case 'date_desc':
      default:
        filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
    }

    return filtered;
  }

  bool _matchesTimeFilter(EventModel event) {
    if (_timeFilter == 'all') return true;

    final now = DateTime.now();
    final startDate = event.startDate;
    final endDate = event.endDate;

    switch (_timeFilter) {
      case 'upcoming':
        // Sắp diễn ra: sự kiện chưa bắt đầu
        return startDate.isAfter(now) && event.status == 'published';
      case 'ongoing':
        // Đang diễn ra: sự kiện đang trong thời gian diễn ra
        return startDate.isBefore(now) &&
            endDate.isAfter(now) &&
            event.status == 'published';
      case 'past':
        // Đã qua: sự kiện đã kết thúc
        return endDate.isBefore(now) && event.status == 'published';
      case 'pending':
        // Chờ duyệt: sự kiện có trạng thái pending
        return event.status == 'pending';
      default:
        return true;
    }
  }
}
