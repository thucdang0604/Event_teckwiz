import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/coorganizer_invitation_model.dart';
import '../../services/coorganizer_invitation_service.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class EventCoOrganizersScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventCoOrganizersScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventCoOrganizersScreen> createState() =>
      _EventCoOrganizersScreenState();
}

class _EventCoOrganizersScreenState extends State<EventCoOrganizersScreen> {
  final CoOrganizerInvitationService _invitationService =
      CoOrganizerInvitationService();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();

  List<CoOrganizerInvitationModel> _invitations = [];
  bool _isLoading = true;
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) return;

      // Load invitations sent by this organizer for this event
      final sentInvitations = await _invitationService
          .getOrganizerInvitationsStream(currentUser.id)
          .first;

      final eventInvitations = sentInvitations
          .where((inv) => inv.eventId == widget.eventId)
          .toList();

      setState(() {
        _invitations = eventInvitations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading invitations: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendInvitation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isInviting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) return;

      // Check if user exists
      final user = await _authService.getUserByEmail(email);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found with this email'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Check if already invited
      final existingInvitation = _invitations.firstWhere(
        (inv) => inv.invitedUserEmail == email && inv.status != 'rejected',
        orElse: () => CoOrganizerInvitationModel(
          id: '',
          eventId: '',
          eventTitle: '',
          organizerId: '',
          organizerName: '',
          invitedUserId: '',
          invitedUserEmail: '',
          invitedUserName: '',
          status: '',
          invitedAt: DateTime.now(),
        ),
      );

      if (existingInvitation.id.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This user has already been invited'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Send invitation
      await _invitationService.sendInvitation(
        eventId: widget.eventId,
        eventTitle: widget.eventTitle,
        organizerId: currentUser.id,
        organizerName: currentUser.fullName,
        invitedUserId: user.id,
        invitedUserEmail: user.email,
        invitedUserName: user.fullName,
      );

      _emailController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      await _loadInvitations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending invitation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }

  Future<void> _cancelInvitation(String invitationId) async {
    try {
      await _invitationService.cancelInvitation(invitationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation cancelled'),
            backgroundColor: AppColors.warning,
          ),
        );
      }

      await _loadInvitations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling invitation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Co-Organizers - ${widget.eventTitle}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Invite new co-organizer section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite Co-Organizer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Enter email address',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isInviting ? null : _sendInvitation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: _isInviting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Invite'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Invitations list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _invitations.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_add_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No invitations sent yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Invite co-organizers to help manage this event',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invitations.length,
                    itemBuilder: (context, index) {
                      return _buildInvitationCard(_invitations[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(CoOrganizerInvitationModel invitation) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (invitation.status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_top;
        statusText = 'Pending';
        break;
      case 'accepted':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Accepted';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                        invitation.invitedUserName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        invitation.invitedUserEmail,
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
                        statusText,
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
            if (invitation.responseMessage != null &&
                invitation.responseMessage!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Message: ${invitation.responseMessage}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (invitation.isPending) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancelInvitation(invitation.id),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancel Invitation'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
