import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/location_model.dart';
import '../models/event_statistics_model.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  List<EventModel> get pendingEvents => _pendingEvents;
  List<EventModel> get allEvents => _allEvents;
  List<LocationModel> get locations => _locations;
  List<EventStatisticsModel> get eventStatistics => _eventStatistics;
  List<EventModel> get locationEvents => _locationEvents;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
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
    _setLoading(true);
    _clearError();

    try {
      await _adminService.addLocation(location);
      await loadLocations();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
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
    _setLoading(true);
    _clearError();

    try {
      _locationEvents = await _adminService.getEventsByLocation(locationName);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
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

  Future<void> deleteEvent(String eventId) async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.deleteEvent(eventId);
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

  void clearError() {
    _clearError();
  }
}
