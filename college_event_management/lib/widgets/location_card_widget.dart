import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../models/event_model.dart';
import '../providers/admin_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_design.dart';

class LocationCardWidget extends StatelessWidget {
  final LocationModel location;
  final AdminProvider adminProvider;
  final BoxConstraints constraints;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onSelectionChanged;

  const LocationCardWidget({
    super.key,
    required this.location,
    required this.adminProvider,
    required this.constraints,
    this.isSelected = false,
    this.onTap,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = constraints.maxWidth > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        border: Border.all(
          color: isSelected ? AppColors.adminPrimary : AppColors.cardBorder,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.adminPrimary.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with enhanced design
              Row(
                children: [
                  if (onSelectionChanged != null)
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: AppDesign.spacing12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.adminPrimary
                              : AppColors.cardBorder,
                          width: 2,
                        ),
                        color: isSelected
                            ? AppColors.adminPrimary
                            : Colors.white,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),

                  // Location icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.adminPrimary.withOpacity(0.2),
                          AppColors.adminSecondary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppDesign.radius12),
                      border: Border.all(
                        color: AppColors.adminPrimary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.adminPrimary,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: AppDesign.spacing12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: AppDesign.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDesign.spacing4),
                        Text(
                          location.address,
                          style: AppDesign.bodySmall.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppDesign.spacing12),

                  // Capacity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesign.spacing8,
                      vertical: AppDesign.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.adminPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDesign.radius8),
                      border: Border.all(
                        color: AppColors.adminPrimary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 12,
                          color: AppColors.adminPrimary,
                        ),
                        const SizedBox(width: AppDesign.spacing4),
                        Text(
                          '${location.capacity}',
                          style: AppDesign.bodySmall.copyWith(
                            color: AppColors.adminPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppDesign.spacing8),

                  if (!location.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesign.spacing8,
                        vertical: AppDesign.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppDesign.radius8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Inactive',
                        style: AppDesign.bodySmall.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),

                  const SizedBox(width: AppDesign.spacing4),

                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesign.radius12),
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          _showEditLocationDialog(context);
                          break;
                        case 'toggle':
                          await adminProvider.updateLocation(
                            location.copyWith(
                              isActive: !location.isActive,
                              updatedAt: DateTime.now(),
                            ),
                          );
                          break;
                        case 'delete':
                          await adminProvider.deleteLocation(location.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 18),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: ListTile(
                          leading: Icon(Icons.autorenew, size: 18),
                          title: Text('Toggle Active'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, size: 18),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppDesign.spacing12),

              // Location details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Facilities indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.adminSecondary.withOpacity(0.2),
                          AppColors.adminPrimary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppDesign.radius12),
                      border: Border.all(
                        color: AppColors.adminSecondary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.business,
                      color: AppColors.adminSecondary,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: AppDesign.spacing16),

                  // Location information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Text(
                          location.description,
                          style: AppDesign.bodySmall.copyWith(
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                          maxLines: isWideScreen ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: AppDesign.spacing8),

                        // Facilities
                        if (location.facilities.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppDesign.spacing8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(
                                AppDesign.radius8,
                              ),
                            ),
                            child: Wrap(
                              spacing: AppDesign.spacing8,
                              runSpacing: AppDesign.spacing4,
                              children: location.facilities.take(3).map((
                                facility,
                              ) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDesign.spacing6,
                                    vertical: AppDesign.spacing4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.adminPrimary.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppDesign.radius6,
                                    ),
                                  ),
                                  child: Text(
                                    facility,
                                    style: AppDesign.bodySmall.copyWith(
                                      color: AppColors.adminPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        const SizedBox(height: AppDesign.spacing12),

                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showLocationEventsDialog(context),
                            icon: const Icon(Icons.event, size: 16),
                            label: const Text('View Events'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.adminPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDesign.spacing16,
                                vertical: AppDesign.spacing10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDesign.radius8,
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationEventsDialog(BuildContext context) async {
    try {
      // Show loading dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );

      // Load events for this location
      await adminProvider.loadEventsByLocation(location.name);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show events dialog
      if (context.mounted) {
        _showEventsListDialog(context, adminProvider.locationEvents);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEventsListDialog(BuildContext context, List<EventModel> events) {
    // Take only first 10 events
    final displayEvents = events.take(10).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radius16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppDesign.spacing16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.adminPrimary, AppColors.adminSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDesign.radius16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 24),
                    const SizedBox(width: AppDesign.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: AppDesign.heading3.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${displayEvents.length} upcoming events',
                            style: AppDesign.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Events list
              Flexible(
                child: displayEvents.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDesign.spacing24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: AppDesign.spacing16),
                              Text(
                                'No upcoming events',
                                style: AppDesign.bodyLarge.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDesign.spacing16),
                        itemCount: displayEvents.length,
                        itemBuilder: (context, index) {
                          final event = displayEvents[index];
                          return _buildEventListItem(context, event, index);
                        },
                      ),
              ),

              // Footer with view all button if there are more than 10 events
              if (events.length > 10)
                Container(
                  padding: const EdgeInsets.all(AppDesign.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppDesign.radius16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Showing 10 of ${events.length} events',
                        style: AppDesign.bodySmall.copyWith(color: Colors.grey),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to full events list for this location
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'View All',
                          style: AppDesign.bodyMedium.copyWith(
                            color: AppColors.adminPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context) {
    final nameController = TextEditingController(text: location.name);
    final descriptionController = TextEditingController(
      text: location.description,
    );
    final addressController = TextEditingController(text: location.address);
    final capacityController = TextEditingController(
      text: location.capacity.toString(),
    );
    final facilities = List<String>.from(location.facilities);
    final facilityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: facilityController,
                        decoration: const InputDecoration(
                          labelText: 'Add Facility',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              facilities.add(value);
                            });
                            facilityController.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (facilityController.text.isNotEmpty) {
                          setState(() {
                            facilities.add(facilityController.text);
                            facilityController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (facilities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: facilities.map((f) {
                      return Chip(
                        label: Text(f),
                        onDeleted: () {
                          setState(() {
                            facilities.remove(f);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = location.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  address: addressController.text,
                  capacity: int.tryParse(capacityController.text) ?? 0,
                  facilities: facilities,
                  updatedAt: DateTime.now(),
                );
                await adminProvider.updateLocation(updated);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventListItem(
    BuildContext context,
    EventModel event,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
      padding: const EdgeInsets.all(AppDesign.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesign.radius12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Event number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.adminPrimary.withOpacity(0.2),
                  AppColors.adminSecondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDesign.radius8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppDesign.bodySmall.copyWith(
                  color: AppColors.adminPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppDesign.spacing12),

          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppDesign.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDesign.spacing4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: AppDesign.spacing4),
                    Text(
                      '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                      style: AppDesign.bodySmall.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(width: AppDesign.spacing12),
                    Icon(Icons.people, size: 12, color: Colors.grey),
                    const SizedBox(width: AppDesign.spacing4),
                    Text(
                      '${event.currentParticipants}/${event.maxParticipants}',
                      style: AppDesign.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // View event button
          IconButton(
            onPressed: () => _navigateToEventDetail(context, event.id),
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.adminPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEventDetail(BuildContext context, String eventId) {
    // Close the current dialog first
    Navigator.of(context).pop();
    // Then navigate to event detail
    // This requires GoRouter context, so we'll use a callback
    if (onTap != null) {
      // This is a workaround - ideally we'd pass a navigation callback
      // For now, we'll just close the dialog
    }
  }
}
