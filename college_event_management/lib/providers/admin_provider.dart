import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/location_model.dart';
import '../models/event_statistics_model.dart';
import '../models/admin_statistics_model.dart';
import '../services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<UserModel> _users = [];
  List<EventModel> _pendingEvents = [];
  List<EventModel> _allEvents = [];
  List<LocationModel> _locations = [];
  List<EventStatisticsModel> _eventStatistics = [];
  List<EventModel> _locationEvents = [];
  Map<String, dynamic> _dashboardStats = {};
  AdminStatisticsModel _statistics = AdminStatisticsModel.empty();
  bool _isLoading = false;
  bool _isLocationEventsLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  List<EventModel> get pendingEvents => _pendingEvents;
  List<EventModel> get allEvents => _allEvents;
  List<LocationModel> get locations => _locations;
  List<EventStatisticsModel> get eventStatistics => _eventStatistics;
  List<EventModel> get locationEvents => _locationEvents;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  AdminStatisticsModel get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get isLocationEventsLoading => _isLocationEventsLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUsers() async {
    _setLoading(true);
    _clearError();

    try {
      _users = await _adminService.getAllUsers();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadPendingEvents() async {
    _setLoading(true);
    _clearError();

    try {
      _pendingEvents = await _adminService.getPendingEvents();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadAllEvents() async {
    _setLoading(true);
    _clearError();

    try {
      _allEvents = await _adminService.getAllEvents();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadLocations() async {
    _setLoading(true);
    _clearError();

    try {
      _locations = await _adminService.getAllLocations();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadEventStatistics() async {
    _setLoading(true);
    _clearError();

    try {
      _eventStatistics = await _adminService.getEventStatistics();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadDashboardStats() async {
    _setLoading(true);
    _clearError();

    try {
      _dashboardStats = await _adminService.getDashboardStats();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.updateUserStatus(userId, isActive);
      await loadUsers();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.updateUserRole(userId, role);
      await loadUsers();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> approveEvent(String eventId) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.approveEvent(eventId);
      await loadAllEvents();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> rejectEvent(String eventId, String reason) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.rejectEvent(eventId, reason);
      await loadAllEvents();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> addLocation(LocationModel location) async {
    _clearError();

    try {
      await _adminService.addLocation(location);
      await loadLocations();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> updateLocation(LocationModel location) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.updateLocation(location);
      await loadLocations();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> deleteLocation(String locationId) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.deleteLocation(locationId);
      await loadLocations();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> updateEventStatistics(
    String eventId,
    int actualAttendees,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.updateEventStatistics(eventId, actualAttendees);
      await loadEventStatistics();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> approveUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.approveUser(userId);
      await loadUsers();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> rejectUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.rejectUser(userId);
      await loadUsers();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> blockUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.blockUser(userId);
      await loadUsers();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> unblockUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.unblockUser(userId);
      await loadUsers();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadEventsByLocation(String locationName) async {
    _isLocationEventsLoading = true;
    _clearError();
    notifyListeners();

    try {
      _locationEvents = await _adminService.getEventsByLocation(locationName);
      _isLocationEventsLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _isLocationEventsLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelEvent(String eventId) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.cancelEvent(eventId);
      await loadAllEvents();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> updateEventStatus(String eventId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.updateEventStatus(eventId, status);
      await loadAllEvents();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadStatistics() async {
    _setLoading(true);
    _clearError();

    try {
      // Calculate statistics from existing data
      print('📊 Loading events and users for statistics...');
      final allEvents = await _adminService.getAllEvents();
      final allUsers = await _adminService.getAllUsers();
      print(
        '📊 Loaded ${allEvents.length} events and ${allUsers.length} users',
      );

      // Update the stored data for future use
      _allEvents = allEvents;
      _users = allUsers;

      final totalEvents = allEvents.length;
      final activeUsers = allUsers.where((user) => !user.isBlocked).length;
      final approvedEvents = allEvents
          .where((event) => event.status == 'published')
          .length;
      final pendingEvents = allEvents
          .where((event) => event.status == 'pending')
          .length;
      final rejectedEvents = allEvents
          .where((event) => event.status == 'rejected')
          .length;

      // Calculate total registrations
      final totalRegistrations = allEvents.fold<int>(
        0,
        (sum, event) => sum + (event.currentParticipants),
      );

      // Calculate average events per month (simplified)
      final now = DateTime.now();
      final monthsSinceStart =
          now.month + (now.year - 2024) * 12; // Assuming started in 2024
      final averageEventsPerMonth = monthsSinceStart > 0
          ? totalEvents / monthsSinceStart
          : 0.0;

      // Find top category (simplified - just get most common)
      final categoryCount = <String, int>{};
      for (final event in allEvents) {
        final category = event.category;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
      final topCategory = categoryCount.isNotEmpty
          ? categoryCount.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
          : 'N/A';

      // Find most active organizer
      final organizerCount = <String, int>{};
      for (final event in allEvents) {
        final organizer = event.organizerName;
        organizerCount[organizer] = (organizerCount[organizer] ?? 0) + 1;
      }
      final mostActiveOrganizer = organizerCount.isNotEmpty
          ? organizerCount.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
          : 'N/A';

      // Generate recent activities (simplified)
      final recentActivities = <String>[];
      final recentEvents = allEvents.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (final event in recentEvents.take(5)) {
        recentActivities.add('${event.title} was ${event.status}');
      }

      _statistics = AdminStatisticsModel(
        totalEvents: totalEvents,
        activeUsers: activeUsers,
        approvedEvents: approvedEvents,
        pendingEvents: pendingEvents,
        rejectedEvents: rejectedEvents,
        totalRegistrations: totalRegistrations,
        averageEventsPerMonth: averageEventsPerMonth,
        topCategory: topCategory,
        mostActiveOrganizer: mostActiveOrganizer,
        recentActivities: recentActivities,
      );

      print('📊 Statistics loaded successfully:');
      print('   - Total Events: $totalEvents');
      print('   - Active Users: $activeUsers');
      print('   - Approved Events: $approvedEvents');
      print('   - Pending Events: $pendingEvents');
      print('   - Rejected Events: $rejectedEvents');

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
  }
}
