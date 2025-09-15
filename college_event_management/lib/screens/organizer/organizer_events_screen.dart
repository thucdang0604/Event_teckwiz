import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class OrganizerEventsScreen extends StatefulWidget {
  const OrganizerEventsScreen({super.key});

  @override
  State<OrganizerEventsScreen> createState() => _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Events',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.organizerPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Create Event',
              icon: const Icon(Icons.add),
              onPressed: () => context.go('/create-event'),
            ),
          ],
        ),
        body: Consumer<EventProvider>(
          builder: (context, eventProvider, child) {
            if (eventProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = context.watch<AuthProvider>().currentUser;
            final myEvents = eventProvider.events
                .where((event) => event.organizerId == user?.id)
                .toList();

            if (myEvents.isEmpty) {
              return _buildEmptyState();
            }

            return Container(
              color: AppColors.surfaceVariant,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myEvents.length,
                itemBuilder: (context, index) {
                  final event = myEvents[index];
                  return _buildEventCard(event);
                },
              ),
            );
          },
        ),
        bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.organizerPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.event_available,
                  size: 60,
                  color: AppColors.organizerPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Events Yet',
                style: AppDesign.heading2.copyWith(
                  color: const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first event to get started',
                style: AppDesign.bodyMedium.copyWith(
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/create-event'),
                icon: const Icon(Icons.add),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.organizerPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final now = DateTime.now();
    final isUpcoming = event.startDate.isAfter(now);
    final isOngoing =
        event.startDate.isBefore(now) && event.endDate.isAfter(now);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isOngoing) {
      statusColor = AppColors.success;
      statusText = 'Ongoing';
      statusIcon = Icons.play_circle;
    } else if (isUpcoming) {
      statusColor = AppColors.organizerPrimary;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule;
    } else {
      statusColor = AppColors.grey;
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppDesign.cardDecoration,
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
                      style: AppDesign.heading3.copyWith(
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: AppDesign.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: AppDesign.bodyMedium.copyWith(
                  color: const Color(0xFF6B7280),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(event.startDate),
                    style: AppDesign.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(event.startDate),
                    style: AppDesign.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              if (event.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: AppDesign.bodySmall.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
