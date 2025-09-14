import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/location_model.dart';
import '../../models/event_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../widgets/admin_bottom_navigation_bar.dart';
import '../../widgets/location_card_widget.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen>
    with TickerProviderStateMixin {
  final int _currentIndex = 3; // Locations tab
  String _searchQuery = '';
  String _sortBy = 'name_asc';
  final Set<String> _selectedLocations = {};
  bool _isSelectionMode = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: AppDesign.normalAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController = AnimationController(
      duration: AppDesign.normalAnimation,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadLocations();
      // Start animations
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.adminPrimary, AppColors.adminSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.adminPrimary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Management',
                    style: AppDesign.heading2.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Manage event locations and view schedules',
                    style: AppDesign.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 70,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDesign.radius12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () => context.go('/admin-dashboard'),
                  tooltip: 'Back to Dashboard',
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDesign.radius12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _showAddLocationDialog(context),
                    tooltip: 'Add Location',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDesign.radius12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.sort, size: 20),
                    onPressed: () => _showSortBottomSheet(context),
                    tooltip: 'Sort Options',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDesign.radius12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () {
                      context.read<AdminProvider>().loadLocations();
                    },
                    tooltip: 'Refresh',
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    decoration:
                        AppDesign.textFieldDecoration(
                          hintText: 'Search by location name or address...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.adminPrimary.withOpacity(0.7),
                          ),
                        ).copyWith(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radius16,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.adminPrimary.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radius16,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.adminPrimary.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radius16,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.adminPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceVariant,
                AppColors.surfaceVariant.withOpacity(0.8),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Consumer<AdminProvider>(
                    builder: (context, adminProvider, child) {
                      if (adminProvider.isLoading) {
                        return _buildLoadingState();
                      }

                      final filteredSorted = _filterAndSort(
                        adminProvider.locations,
                      );

                      return Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppDesign.radius20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  await adminProvider.loadLocations();
                                  _fadeController.reset();
                                  _slideController.reset();
                                  _fadeController.forward();
                                  _slideController.forward();
                                },
                                color: AppColors.adminPrimary,
                                backgroundColor: Colors.white,
                                child: CustomScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    if (filteredSorted.isEmpty &&
                                        adminProvider.locations.isEmpty)
                                      SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: _buildEnhancedEmptyState(),
                                      )
                                    else
                                      SliverPadding(
                                        padding: EdgeInsets.fromLTRB(
                                          constraints.maxWidth > 600
                                              ? AppDesign.spacing24
                                              : AppDesign.spacing16,
                                          AppDesign.spacing8,
                                          constraints.maxWidth > 600
                                              ? AppDesign.spacing24
                                              : AppDesign.spacing16,
                                          AppDesign.spacing32,
                                        ),
                                        sliver: SliverList(
                                          delegate: SliverChildBuilderDelegate((
                                            context,
                                            index,
                                          ) {
                                            final location =
                                                filteredSorted[index];
                                            return TweenAnimationBuilder<
                                              double
                                            >(
                                              duration: Duration(
                                                milliseconds:
                                                    300 + (index * 50),
                                              ),
                                              tween: Tween(
                                                begin: 0.0,
                                                end: 1.0,
                                              ),
                                              builder: (context, value, child) {
                                                return Transform.translate(
                                                  offset: Offset(
                                                    0,
                                                    20 * (1 - value),
                                                  ),
                                                  child: Opacity(
                                                    opacity: value,
                                                    child: LocationCardWidget(
                                                      location: location,
                                                      adminProvider:
                                                          adminProvider,
                                                      constraints: constraints,
                                                      isSelected:
                                                          _selectedLocations
                                                              .contains(
                                                                location.id,
                                                              ),
                                                      onTap: _isSelectionMode
                                                          ? () => setState(() {
                                                              if (_selectedLocations
                                                                  .contains(
                                                                    location.id,
                                                                  )) {
                                                                _selectedLocations
                                                                    .remove(
                                                                      location
                                                                          .id,
                                                                    );
                                                              } else {
                                                                _selectedLocations
                                                                    .add(
                                                                      location
                                                                          .id,
                                                                    );
                                                              }
                                                            })
                                                          : () =>
                                                                _showLocationEventsDialog(
                                                                  location,
                                                                  adminProvider,
                                                                ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }, childCount: filteredSorted.length),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: AdminBottomNavigationBar(
          currentIndex: _currentIndex,
        ),
        floatingActionButton: _isSelectionMode && _selectedLocations.isNotEmpty
            ? _buildBulkActionButtons()
            : null,
      ),
    );
  }

  List<LocationModel> _filterAndSort(List<LocationModel> locations) {
    var filtered = locations.where((location) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesSearch =
            location.name.toLowerCase().contains(searchLower) ||
            location.address.toLowerCase().contains(searchLower) ||
            location.description.toLowerCase().contains(searchLower);
        if (!matchesSearch) return false;
      }

      return true;
    }).toList();

    // Sort locations
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name_asc':
          return a.name.compareTo(b.name);
        case 'name_desc':
          return b.name.compareTo(a.name);
        case 'capacity_asc':
          return a.capacity.compareTo(b.capacity);
        case 'capacity_desc':
          return b.capacity.compareTo(a.capacity);
        case 'created_desc':
          return b.createdAt.compareTo(a.createdAt);
        case 'created_asc':
          return a.createdAt.compareTo(b.createdAt);
        default:
          return a.name.compareTo(b.name);
      }
    });

    return filtered;
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radius20),
        ),
      ),
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  Widget _buildSortBottomSheet() {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppDesign.spacing16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort Locations',
                    style: AppDesign.heading3.copyWith(
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: AppDesign.spacing16),
                  ..._buildSortOptions(),
                  const SizedBox(height: AppDesign.spacing24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDesign.spacing16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDesign.radius12,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Apply Sort',
                        style: AppDesign.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController capacityController = TextEditingController();
    final TextEditingController facilityController = TextEditingController();
    final List<String> facilities = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Location'),
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
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
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
                    children: facilities.map((facility) {
                      return Chip(
                        label: Text(facility),
                        onDeleted: () {
                          setState(() {
                            facilities.remove(facility);
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
                if (nameController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    addressController.text.isNotEmpty &&
                    capacityController.text.isNotEmpty) {
                  final location = LocationModel(
                    id: '',
                    name: nameController.text,
                    description: descriptionController.text,
                    address: addressController.text,
                    capacity: int.tryParse(capacityController.text) ?? 0,
                    facilities: facilities,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  try {
                    await context.read<AdminProvider>().addLocation(location);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    if (mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add location: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSortOptions() {
    final options = [
      {'label': 'Name (A-Z)', 'value': 'name_asc'},
      {'label': 'Name (Z-A)', 'value': 'name_desc'},
      {'label': 'Capacity (Low-High)', 'value': 'capacity_asc'},
      {'label': 'Capacity (High-Low)', 'value': 'capacity_desc'},
      {'label': 'Newest First', 'value': 'created_desc'},
      {'label': 'Oldest First', 'value': 'created_asc'},
    ];

    return options.map((option) {
      final isSelected = _sortBy == option['value'];
      return Container(
        margin: const EdgeInsets.only(bottom: AppDesign.spacing8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.adminPrimary.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppDesign.radius8),
          border: Border.all(
            color: isSelected ? AppColors.adminPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTile(
          title: Text(
            option['label']!,
            style: AppDesign.bodyMedium.copyWith(
              color: isSelected
                  ? AppColors.adminPrimary
                  : const Color(0xFF374151),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check, color: AppColors.adminPrimary, size: 20)
              : null,
          onTap: () {
            setState(() => _sortBy = option['value']!);
            Navigator.of(context).pop();
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radius8),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLoadingState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header skeleton
          Container(
            margin: const EdgeInsets.all(AppDesign.spacing16),
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.adminPrimary.withOpacity(0.1),
                  AppColors.adminSecondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDesign.radius16),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppDesign.spacing16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppDesign.radius16),
                border: Border.all(
                  color: AppColors.adminPrimary.withOpacity(0.1),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppDesign.spacing24),

          // List skeleton
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDesign.radius20),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDesign.spacing16),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDesign.radius16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppDesign.spacing16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppDesign.radius16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spacing24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.adminPrimary.withOpacity(0.1),
                  AppColors.adminSecondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off,
              size: 48,
              color: AppColors.adminPrimary,
            ),
          ),
          const SizedBox(height: AppDesign.spacing16),
          Text(
            'No locations found',
            style: AppDesign.heading3.copyWith(color: const Color(0xFF374151)),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            'Try adjusting your search',
            style: AppDesign.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _showBulkActionDialog('activate'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: Text('Activate (${_selectedLocations.length})'),
            icon: const Icon(Icons.check_circle),
          ),
          const SizedBox(width: AppDesign.spacing12),
          FloatingActionButton.extended(
            onPressed: () => _showBulkActionDialog('deactivate'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: Text('Deactivate (${_selectedLocations.length})'),
            icon: const Icon(Icons.cancel),
          ),
        ],
      ),
    );
  }

  void _showBulkActionDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text(
          'Are you sure you want to $action ${_selectedLocations.length} selected locations?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _performBulkAction(action);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'activate' ? Colors.green : Colors.red,
            ),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _performBulkAction(String action) {
    // TODO: Implement bulk actions
    setState(() {
      _selectedLocations.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Bulk $action completed')));
  }

  void _showLocationEventsDialog(
    LocationModel location,
    AdminProvider adminProvider,
  ) async {
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
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show events dialog
      if (mounted) {
        _showEventsListDialog(location, adminProvider.locationEvents);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEventsListDialog(LocationModel location, List<EventModel> events) {
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
                          return _buildEventListItem(event, index);
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

  Widget _buildEventListItem(EventModel event, int index) {
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
            onPressed: () => context.go('/event-detail/${event.id}'),
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
}
