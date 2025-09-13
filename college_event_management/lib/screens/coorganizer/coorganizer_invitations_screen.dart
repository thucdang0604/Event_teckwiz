import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../models/coorganizer_invitation_model.dart';
import '../../services/coorganizer_invitation_service.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class CoOrganizerInvitationsScreen extends StatefulWidget {
  const CoOrganizerInvitationsScreen({super.key});

  @override
  State<CoOrganizerInvitationsScreen> createState() =>
      _CoOrganizerInvitationsScreenState();
}

class _CoOrganizerInvitationsScreenState
    extends State<CoOrganizerInvitationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CoOrganizerInvitationService _invitationService =
      CoOrganizerInvitationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please login to view invitations'));
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        title: const Text('Co-Organizer Invitations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedInvitations(currentUser.id),
          _buildSentInvitations(currentUser.id),
        ],
      ),
    );
  }

  Widget _buildReceivedInvitations(String userId) {
    return StreamBuilder<List<CoOrganizerInvitationModel>>(
      stream: _invitationService.getUserInvitationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final invitations = snapshot.data ?? [];
        final pendingInvitations = invitations
            .where((inv) => inv.isPending)
            .toList();
        final respondedInvitations = invitations
            .where((inv) => !inv.isPending)
            .toList();

        if (invitations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'No invitations received',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pendingInvitations.isNotEmpty) ...[
                Text(
                  'Pending Invitations',
                  style: AppDesign.heading3.copyWith(
                    color: AppColors.adminPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...pendingInvitations.map(
                  (invitation) => _buildInvitationCard(invitation, true),
                ),
                const SizedBox(height: 24),
              ],
              if (respondedInvitations.isNotEmpty) ...[
                Text(
                  'Responded Invitations',
                  style: AppDesign.heading3.copyWith(
                    color: AppColors.adminPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...respondedInvitations.map(
                  (invitation) => _buildInvitationCard(invitation, false),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSentInvitations(String userId) {
    return StreamBuilder<List<CoOrganizerInvitationModel>>(
      stream: _invitationService.getOrganizerInvitationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final invitations = snapshot.data ?? [];

        if (invitations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'No invitations sent',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            return _buildInvitationCard(invitations[index], false);
          },
        );
      },
    );
  }

  Widget _buildInvitationCard(
    CoOrganizerInvitationModel invitation,
    bool canRespond,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        invitation.eventTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${invitation.organizerName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Invited: ${DateFormat('dd/MM/yyyy HH:mm').format(invitation.invitedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(invitation.status),
              ],
            ),
            if (invitation.respondedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Responded: ${DateFormat('dd/MM/yyyy HH:mm').format(invitation.respondedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (invitation.responseMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                'Message: ${invitation.responseMessage}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (canRespond && invitation.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptInvitation(invitation.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectInvitation(invitation.id),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'Pending';
        icon = Icons.hourglass_top;
        break;
      case 'accepted':
        color = AppColors.success;
        text = 'Accepted';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.textSecondary;
        text = 'Unknown';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppDesign.statusChipDecoration(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: AppDesign.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(String invitationId) async {
    try {
      await _invitationService.acceptInvitation(invitationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation accepted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectInvitation(String invitationId) async {
    try {
      await _invitationService.rejectInvitation(invitationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
