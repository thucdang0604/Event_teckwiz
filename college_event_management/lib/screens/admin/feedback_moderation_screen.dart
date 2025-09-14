import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../widgets/admin_bottom_navigation_bar.dart';

class FeedbackModerationScreen extends StatefulWidget {
  const FeedbackModerationScreen({super.key});

  @override
  State<FeedbackModerationScreen> createState() =>
      _FeedbackModerationScreenState();
}

class _FeedbackModerationScreenState extends State<FeedbackModerationScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feedback Moderation',
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
      ),
      body: Container(
        color: AppColors.surfaceVariant,
        child: Column(
          children: [
            _buildFilterSection(),
            Expanded(child: _buildFeedbackList()),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex:
            0, // Dashboard index (since feedback is accessed from dashboard)
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Feedback',
            style: AppDesign.heading3.copyWith(color: const Color(0xFF111827)),
          ),
          const SizedBox(height: AppDesign.spacing12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Container(
                  margin: const EdgeInsets.only(right: AppDesign.spacing12),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.adminPrimary.withOpacity(0.1),
                    checkmarkColor: AppColors.adminPrimary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.adminPrimary
                          : const Color(0xFF6B7280),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesign.radius20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.adminPrimary
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      itemCount: 10, // Mock data
      itemBuilder: (context, index) {
        return _buildFeedbackCard(index);
      },
    );
  }

  Widget _buildFeedbackCard(int index) {
    final feedbacks = [
      {
        'event': 'Tech Conference 2025',
        'user': 'Nguyen Van A',
        'rating': 4,
        'comment': 'Sự kiện rất hay, tổ chức tốt nhưng thời gian hơi ngắn.',
        'status': 'pending',
        'date': '2024-01-15',
      },
      {
        'event': 'Music Festival',
        'user': 'Tran Thi B',
        'rating': 2,
        'comment': 'Âm thanh không tốt, không như mong đợi.',
        'status': 'pending',
        'date': '2024-01-14',
      },
      {
        'event': 'Workshop AI',
        'user': 'Le Van C',
        'rating': 5,
        'comment': 'Tuyệt vời! Học được nhiều kiến thức mới.',
        'status': 'approved',
        'date': '2024-01-13',
      },
    ];

    final feedback = feedbacks[index % feedbacks.length];
    final status = feedback['status'] as String;
    final rating = feedback['rating'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing16),
      decoration: AppDesign.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback['event'] as String,
                        style: AppDesign.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: AppDesign.spacing4),
                      Text(
                        'by ${feedback['user']}',
                        style: AppDesign.bodySmall.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: AppDesign.spacing12),
            Row(
              children: List.generate(5, (starIndex) {
                return Icon(
                  starIndex < rating ? Icons.star : Icons.star_border,
                  color: AppColors.warning,
                  size: 16,
                );
              }),
            ),
            const SizedBox(height: AppDesign.spacing12),
            Text(
              feedback['comment'] as String,
              style: AppDesign.bodyMedium.copyWith(
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: AppDesign.spacing12),
            Row(
              children: [
                Text(
                  feedback['date'] as String,
                  style: AppDesign.labelSmall.copyWith(
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const Spacer(),
                if (status == 'pending') ...[
                  TextButton(
                    onPressed: () => _moderateFeedback(index, 'approved'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      textStyle: AppDesign.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: AppDesign.spacing8),
                  TextButton(
                    onPressed: () => _moderateFeedback(index, 'rejected'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      textStyle: AppDesign.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ] else ...[
                  Text(
                    status == 'approved' ? 'Approved' : 'Rejected',
                    style: AppDesign.labelMedium.copyWith(
                      color: status == 'approved'
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = AppColors.success;
        label = 'Approved';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Rejected';
        break;
      default:
        color = AppColors.statusPending;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing12,
        vertical: AppDesign.spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDesign.radius20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: AppDesign.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _moderateFeedback(int index, String action) {
    String message;
    if (action == 'approved') {
      message = 'Feedback approved successfully';
    } else {
      message = 'Feedback rejected successfully';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: action == 'approved'
            ? AppColors.success
            : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radius12),
        ),
      ),
    );

    // In real app, this would update the feedback status in backend
    setState(() {
      // Update local state
    });
  }
}
