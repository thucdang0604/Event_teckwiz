import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/support_registration_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/organizer_service.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class SupportRegistrationsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const SupportRegistrationsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<SupportRegistrationsScreen> createState() =>
      _SupportRegistrationsScreenState();
}

class _SupportRegistrationsScreenState
    extends State<SupportRegistrationsScreen> {
  final OrganizerService _organizerService = OrganizerService();
  List<SupportRegistrationModel> _registrations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'all';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
    _loadStats();
  }

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final registrations = await _organizerService
          .getEventSupportRegistrations(widget.eventId);
      setState(() {
        _registrations = registrations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        final msg = e.toString();
        if (msg.contains('permission-denied')) {
          _errorMessage =
              'Bạn không có quyền xem danh sách này. Vui lòng kiểm tra quyền Organizer/Admin hoặc liên hệ quản trị.';
        } else {
          _errorMessage = msg;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _organizerService.getSupportRegistrationStats(
        widget.eventId,
      );
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _approveRegistration(
    SupportRegistrationModel registration,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _organizerService.approveSupportRegistration(
        registration.id,
        authProvider.currentUser?.id ?? '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support registration approved successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      await _loadRegistrations();
      await _loadStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving registration: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectRegistration(
    SupportRegistrationModel registration,
  ) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Support Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject registration for ${registration.userName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await _organizerService.rejectSupportRegistration(
          registration.id,
          authProvider.currentUser?.id ?? '',
          reasonController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support registration rejected'),
            backgroundColor: AppColors.error,
          ),
        );

        await _loadRegistrations();
        await _loadStats();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting registration: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<SupportRegistrationModel> get _filteredRegistrations {
    var filtered = _registrations;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (reg) =>
                reg.userName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                reg.userEmail.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Filter by status
    if (_statusFilter != 'all') {
      filtered = filtered.where((reg) => reg.status == _statusFilter).toList();
    }

    return filtered;
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Registration Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                'Total',
                _stats['total'] ?? 0,
                AppColors.textPrimary,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Pending',
                _stats['pending'] ?? 0,
                AppColors.warning,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Approved',
                _stats['approved'] ?? 0,
                AppColors.success,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Rejected',
                _stats['rejected'] ?? 0,
                AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = selected ? value : 'all';
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildRegistrationCard(SupportRegistrationModel registration) {
    Color statusColor;
    IconData statusIcon;

    switch (registration.status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case 'cancelled':
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    registration.userName.isNotEmpty
                        ? registration.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        registration.userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        registration.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (registration.additionalInfo != null &&
                registration.additionalInfo!['note'] != null &&
                registration.additionalInfo!['note'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Notes:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registration.additionalInfo!['note'].toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Text(
              'Registered: ${DateFormat('dd/MM/yyyy HH:mm').format(registration.registeredAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),

            if (registration.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      onPressed: () => _approveRegistration(registration),
                      backgroundColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      onPressed: () => _rejectRegistration(registration),
                      backgroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support Registrations - ${widget.eventTitle}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildStatsCard(),

          // Search and filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cancelled', 'cancelled'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Registrations list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRegistrations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredRegistrations.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No support registrations found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredRegistrations.length,
                    itemBuilder: (context, index) {
                      return _buildRegistrationCard(
                        _filteredRegistrations[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
