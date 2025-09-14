import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../widgets/admin_bottom_navigation_bar.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Media Library',
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
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon'),
                ),
              );
            },
            tooltip: 'Search Media',
          ),
        ],
      ),
      body: Container(
        color: AppColors.surfaceVariant,
        child: Column(
          children: [
            _buildFilterSection(),
            Expanded(child: _buildMediaGrid()),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex:
            0, // Dashboard index (since media is accessed from dashboard)
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
            'Filter Media',
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

  Widget _buildMediaGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDesign.spacing16,
        mainAxisSpacing: AppDesign.spacing16,
        childAspectRatio: 1,
      ),
      itemCount: 12, // Mock data
      itemBuilder: (context, index) {
        return _buildMediaCard(index);
      },
    );
  }

  Widget _buildMediaCard(int index) {
    final mediaItems = [
      {
        'event': 'Tech Conference 2025',
        'uploader': 'Nguyen Van A',
        'type': 'image',
        'status': 'pending',
        'uploadDate': '2024-01-15',
      },
      {
        'event': 'Music Festival',
        'uploader': 'Tran Thi B',
        'type': 'image',
        'status': 'pending',
        'uploadDate': '2024-01-14',
      },
      {
        'event': 'Workshop AI',
        'uploader': 'Le Van C',
        'type': 'image',
        'status': 'approved',
        'uploadDate': '2024-01-13',
      },
      {
        'event': 'Sports Day',
        'uploader': 'Pham Van D',
        'type': 'image',
        'status': 'rejected',
        'uploadDate': '2024-01-12',
      },
    ];

    final media = mediaItems[index % mediaItems.length];
    final status = media['status'] as String;

    return GestureDetector(
      onTap: () => _showMediaDetail(context, media),
      child: Container(
        decoration: AppDesign.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDesign.radius12),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDesign.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media['event'] as String,
                    style: AppDesign.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDesign.spacing4),
                  Text(
                    'by ${media['uploader']}',
                    style: AppDesign.labelSmall.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDesign.spacing8),
                  Row(
                    children: [
                      _buildStatusChip(status),
                      const Spacer(),
                      Text(
                        media['uploadDate'] as String,
                        style: AppDesign.labelSmall.copyWith(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 10,
                        ),
                      ),
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = AppColors.success;
        label = '✓';
        break;
      case 'rejected':
        color = AppColors.error;
        label = '✗';
        break;
      default:
        color = AppColors.statusPending;
        label = '○';
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showMediaDetail(BuildContext context, Map<String, dynamic> media) {
    final status = media['status'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(AppDesign.spacing24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Media Review',
                    style: AppDesign.heading2.copyWith(
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spacing24),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(AppDesign.radius12),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              ),
              const SizedBox(height: AppDesign.spacing16),
              Text(
                media['event'] as String,
                style: AppDesign.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: AppDesign.spacing8),
              Text(
                'Uploaded by: ${media['uploader']}',
                style: AppDesign.bodyMedium.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                'Upload date: ${media['uploadDate']}',
                style: AppDesign.bodyMedium.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: AppDesign.spacing24),
              if (status == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _moderateMedia(media, 'approved');
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radius12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDesign.spacing16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _moderateMedia(media, 'rejected');
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radius12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(AppDesign.spacing16),
                  decoration: BoxDecoration(
                    color: status == 'approved'
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDesign.radius12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status == 'approved'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: status == 'approved'
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: AppDesign.spacing12),
                      Text(
                        status == 'approved' ? 'Approved' : 'Rejected',
                        style: TextStyle(
                          color: status == 'approved'
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _moderateMedia(Map<String, dynamic> media, String action) {
    String message;
    if (action == 'approved') {
      message = 'Media approved successfully';
    } else {
      message = 'Media rejected successfully';
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

    // In real app, this would update the media status in backend
    setState(() {
      // Update local state
    });
  }
}
