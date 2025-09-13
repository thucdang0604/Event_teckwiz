import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/event_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Event Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
          ),
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin-dashboard'),
            tooltip: 'Back to Dashboard',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterBottomSheet(context),
              tooltip: 'Advanced Filters',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<AdminProvider>().loadAllEvents();
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Container(
          color: AppColors.surfaceVariant,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  if (adminProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1E40AF),
                        ),
                      ),
                    );
                  }

                  final filteredSorted = _filterAndSort(
                    adminProvider.allEvents,
                  );

                  return Column(
                    children: [
                      _buildHeader(adminProvider),
                      Expanded(
                        child: filteredSorted.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  adminProvider.loadAllEvents();
                                },
                                color: AppColors.adminPrimary,
                                child: ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    constraints.maxWidth > 600
                                        ? AppDesign.spacing24
                                        : AppDesign.spacing16,
                                    AppDesign.spacing16,
                                    constraints.maxWidth > 600
                                        ? AppDesign.spacing24
                                        : AppDesign.spacing16,
                                    AppDesign.spacing32,
                                  ),
                                  itemCount: filteredSorted.length,
                                  itemBuilder: (context, index) {
                                    final event = filteredSorted[index];
                                    return _buildEventCard(
                                      event,
                                      adminProvider,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.radius20),
            ),
            child: Icon(
              Icons.event_note_outlined,
              size: 40,
              color: AppColors.adminPrimary,
            ),
          ),
          const SizedBox(height: AppDesign.spacing20),
          Text(
            'No events found',
            style: AppDesign.heading3.copyWith(color: const Color(0xFF111827)),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            'Try adjusting your filters or refresh the list',
            style: AppDesign.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: AppDesign.spacing24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<AdminProvider>().loadAllEvents();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: AppDesign.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AdminProvider adminProvider) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            decoration: AppDesign.textFieldDecoration(
              hintText: 'Search by title or organizer',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),

          const SizedBox(height: AppDesign.spacing16),

          // Filter chips for status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', 'status'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Published', 'published', 'status'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Pending', 'pending', 'status'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Rejected', 'rejected', 'status'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Cancelled', 'cancelled', 'status'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Draft', 'draft', 'status'),
              ],
            ),
          ),

          const SizedBox(height: AppDesign.spacing12),

          // Filter chips for time
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Time', 'all', 'time'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Upcoming', 'upcoming', 'time'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Ongoing', 'ongoing', 'time'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Past', 'past', 'time'),
              ],
            ),
          ),

          const SizedBox(height: AppDesign.spacing12),

          // Sort chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Newest', 'date_desc', 'sort'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Oldest', 'date_asc', 'sort'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('A-Z', 'title_asc', 'sort'),
                const SizedBox(width: AppDesign.spacing8),
                _buildFilterChip('Z-A', 'title_desc', 'sort'),
              ],
            ),
          ),

          if (adminProvider.allEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text('No events found', style: TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String type) {
    bool isSelected = false;
    switch (type) {
      case 'status':
        isSelected = _statusFilter == value;
        break;
      case 'time':
        isSelected = _timeFilter == value;
        break;
      case 'sort':
        isSelected = _sortBy == value;
        break;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          switch (type) {
            case 'status':
              _statusFilter = value;
              break;
            case 'time':
              _timeFilter = value;
              break;
            case 'sort':
              _sortBy = value;
              break;
          }
        });
      },
      selectedColor: AppColors.adminPrimary.withOpacity(0.2),
      checkmarkColor: AppColors.adminPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.adminPrimary : AppColors.cardBorder,
        width: 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.adminPrimary : const Color(0xFF6B7280),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing12,
        vertical: AppDesign.spacing8,
      ),
    );
  }

  Widget _buildEventCard(EventModel event, AdminProvider adminProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
      decoration: AppDesign.cardDecoration,
      child: InkWell(
        onTap: () => context.go('/event-detail/${event.id}'),
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: AppDesign.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppDesign.spacing12),
                  _buildStatusChip(
                    _getStatusText(event.status),
                    _getStatusColor(event.status),
                  ),
                ],
              ),

              const SizedBox(height: AppDesign.spacing12),

              // Event details
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 400;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            event.category,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDesign.radius12,
                          ),
                        ),
                        child: Icon(
                          Icons.event,
                          color: _getCategoryColor(event.category),
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: AppDesign.spacing12),

                      // Event information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organizer: ${event.organizerName}',
                              style: AppDesign.bodyMedium.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDesign.spacing4),
                            Text(
                              event.description,
                              style: AppDesign.bodySmall.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                              maxLines: isWideScreen ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDesign.spacing8),

                            // Location and participants
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: AppDesign.spacing4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: AppDesign.bodySmall.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDesign.spacing4),

                            // Date and participants count
                            if (isWideScreen)
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: AppDesign.spacing4),
                                  Text(
                                    _formatDate(event.startDate),
                                    style: AppDesign.bodySmall.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(width: AppDesign.spacing16),
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: AppDesign.spacing4),
                                  Text(
                                    '${event.currentParticipants}/${event.maxParticipants}',
                                    style: AppDesign.bodySmall.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: AppDesign.spacing4),
                                      Text(
                                        _formatDate(event.startDate),
                                        style: AppDesign.bodySmall.copyWith(
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppDesign.spacing4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: AppDesign.spacing4),
                                      Text(
                                        '${event.currentParticipants}/${event.maxParticipants}',
                                        style: AppDesign.bodySmall.copyWith(
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // Action buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildActionButtons(event, adminProvider),
                          const SizedBox(height: AppDesign.spacing8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
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

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing8,
        vertical: AppDesign.spacing4,
      ),
      decoration: AppDesign.statusChipDecoration(color),
      child: Text(
        label,
        style: AppDesign.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'học thuật':
        return const Color(0xFF8b5cf6);
      case 'thể thao':
        return const Color(0xFF10b981);
      case 'văn hóa - nghệ thuật':
        return const Color(0xFFf59e0b);
      case 'tình nguyện':
        return const Color(0xFFef4444);
      case 'kỹ năng mềm':
        return const Color(0xFF3b82f6);
      case 'hội thảo':
        return const Color(0xFF06b6d4);
      case 'triển lãm':
        return const Color(0xFF8b5cf6);
      default:
        return const Color(0xFF6b7280);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.close,
              color: AppColors.statusRejected,
              onPressed: () => _showRejectDialog(event, adminProvider),
              tooltip: 'Reject Event',
            ),
            const SizedBox(width: AppDesign.spacing8),
            _buildActionButton(
              icon: Icons.check,
              color: AppColors.statusApproved,
              onPressed: () => _approveEvent(event, adminProvider),
              tooltip: 'Approve Event',
            ),
          ],
        );
      case 'published':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.cancel,
              color: AppColors.statusCancelled,
              onPressed: () => _showCancelDialog(event, adminProvider),
              tooltip: 'Cancel Event',
            ),
          ],
        );
      case 'rejected':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.check,
              color: AppColors.statusApproved,
              onPressed: () => _approveEvent(event, adminProvider),
              tooltip: 'Approve Event',
            ),
          ],
        );
      case 'cancelled':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.check,
              color: AppColors.statusApproved,
              onPressed: () => _approveEvent(event, adminProvider),
              tooltip: 'Approve Event',
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDesign.radius8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: color),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radius16),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppDesign.spacing20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Advanced Filters',
                    style: AppDesign.heading2.copyWith(
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spacing20),

              // Status filters
              Text(
                'Status',
                style: AppDesign.labelLarge.copyWith(
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: AppDesign.spacing12),
              Wrap(
                spacing: AppDesign.spacing8,
                runSpacing: AppDesign.spacing8,
                children: [
                  _buildBottomSheetFilterChip('All', 'all', 'status'),
                  _buildBottomSheetFilterChip(
                    'Published',
                    'published',
                    'status',
                  ),
                  _buildBottomSheetFilterChip('Pending', 'pending', 'status'),
                  _buildBottomSheetFilterChip('Rejected', 'rejected', 'status'),
                  _buildBottomSheetFilterChip(
                    'Cancelled',
                    'cancelled',
                    'status',
                  ),
                  _buildBottomSheetFilterChip('Draft', 'draft', 'status'),
                ],
              ),

              const SizedBox(height: AppDesign.spacing24),

              // Time filters
              Text(
                'Time Period',
                style: AppDesign.labelLarge.copyWith(
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: AppDesign.spacing12),
              Wrap(
                spacing: AppDesign.spacing8,
                runSpacing: AppDesign.spacing8,
                children: [
                  _buildBottomSheetFilterChip('All Time', 'all', 'time'),
                  _buildBottomSheetFilterChip('Upcoming', 'upcoming', 'time'),
                  _buildBottomSheetFilterChip('Ongoing', 'ongoing', 'time'),
                  _buildBottomSheetFilterChip('Past', 'past', 'time'),
                ],
              ),

              const SizedBox(height: AppDesign.spacing24),

              // Sort options
              Text(
                'Sort By',
                style: AppDesign.labelLarge.copyWith(
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: AppDesign.spacing12),
              Wrap(
                spacing: AppDesign.spacing8,
                runSpacing: AppDesign.spacing8,
                children: [
                  _buildBottomSheetFilterChip('Newest', 'date_desc', 'sort'),
                  _buildBottomSheetFilterChip('Oldest', 'date_asc', 'sort'),
                  _buildBottomSheetFilterChip('A-Z', 'title_asc', 'sort'),
                  _buildBottomSheetFilterChip('Z-A', 'title_desc', 'sort'),
                ],
              ),

              const SizedBox(height: AppDesign.spacing32),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: AppDesign.primaryButtonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(
                      AppColors.adminPrimary,
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetFilterChip(String label, String value, String type) {
    bool isSelected = false;
    switch (type) {
      case 'status':
        isSelected = _statusFilter == value;
        break;
      case 'time':
        isSelected = _timeFilter == value;
        break;
      case 'sort':
        isSelected = _sortBy == value;
        break;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          switch (type) {
            case 'status':
              _statusFilter = value;
              break;
            case 'time':
              _timeFilter = value;
              break;
            case 'sort':
              _sortBy = value;
              break;
          }
        });
      },
      selectedColor: AppColors.adminPrimary.withOpacity(0.2),
      checkmarkColor: AppColors.adminPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.adminPrimary : AppColors.cardBorder,
        width: 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.adminPrimary : const Color(0xFF6B7280),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing16,
        vertical: AppDesign.spacing12,
      ),
    );
  }
}
