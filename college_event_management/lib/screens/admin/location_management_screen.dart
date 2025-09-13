import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/location_model.dart';
import '../../constants/app_colors.dart';
import '../../utils/navigation_helper.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin-dashboard'),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddLocationDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/admin-dashboard');
              break;
            case 1:
              context.go('/admin/users');
              break;
            case 2:
              context.go('/admin/locations');
              break;
            case 3:
              context.go('/admin/approvals');
              break;
            case 4:
              context.go('/admin/statistics');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Locations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Statistics',
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.locations.isEmpty) {
            return const Center(
              child: Text('No locations found', style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            itemCount: adminProvider.locations.length,
            itemBuilder: (context, index) {
              final location = adminProvider.locations[index];
              return _buildLocationCard(location, adminProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildLocationCard(
    LocationModel location,
    AdminProvider adminProvider,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.go('/admin/location-detail/${location.id}'),
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
                      location.name,
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
                      color: location.isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      location.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                location.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(location.address)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Capacity: ${location.capacity} people'),
                  const SizedBox(width: 16),
                  const Icon(Icons.star, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${location.facilities.length} facilities'),
                ],
              ),
              if (location.facilities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: location.facilities.take(3).map((facility) {
                    return Chip(
                      label: Text(facility),
                      backgroundColor: Colors.blue.shade100,
                      labelStyle: const TextStyle(fontSize: 12),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showEditLocationDialog(location, adminProvider),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _toggleLocationStatus(location, adminProvider),
                      icon: Icon(
                        location.isActive ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(location.isActive ? 'Pause' : 'Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: location.isActive
                            ? Colors.orange
                            : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteLocation(location, adminProvider),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
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

  void _showAddLocationDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController capacityController = TextEditingController();
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
                        decoration: const InputDecoration(
                          labelText: 'Add Facility',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              facilities.add(value);
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          setState(() {
                            facilities.add(nameController.text);
                            nameController.clear();
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
              onPressed: () =>
                  safePop(context, fallbackRoute: '/admin-dashboard'),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
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
                  context.read<AdminProvider>().addLocation(location);
                  safePop(context, fallbackRoute: '/admin-dashboard');
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLocationDialog(
    LocationModel location,
    AdminProvider adminProvider,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: location.name,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: location.description,
    );
    final TextEditingController addressController = TextEditingController(
      text: location.address,
    );
    final TextEditingController capacityController = TextEditingController(
      text: location.capacity.toString(),
    );
    final List<String> facilities = List.from(location.facilities);

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
                        decoration: const InputDecoration(
                          labelText: 'Add Facility',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              facilities.add(value);
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          setState(() {
                            facilities.add(nameController.text);
                            nameController.clear();
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
              onPressed: () =>
                  safePop(context, fallbackRoute: '/admin-dashboard'),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    addressController.text.isNotEmpty &&
                    capacityController.text.isNotEmpty) {
                  final updatedLocation = location.copyWith(
                    name: nameController.text,
                    description: descriptionController.text,
                    address: addressController.text,
                    capacity: int.tryParse(capacityController.text) ?? 0,
                    facilities: facilities,
                    updatedAt: DateTime.now(),
                  );
                  adminProvider.updateLocation(updatedLocation);
                  safePop(context, fallbackRoute: '/admin-dashboard');
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLocationStatus(
    LocationModel location,
    AdminProvider adminProvider,
  ) {
    final updatedLocation = location.copyWith(
      isActive: !location.isActive,
      updatedAt: DateTime.now(),
    );
    adminProvider.updateLocation(updatedLocation);
  }

  void _deleteLocation(LocationModel location, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete location "${location.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                safePop(context, fallbackRoute: '/admin-dashboard'),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              adminProvider.deleteLocation(location.id);
              safePop(context, fallbackRoute: '/admin-dashboard');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
