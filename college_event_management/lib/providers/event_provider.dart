import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();

  List<EventModel> _events = [];
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _myEvents = [];
  List<EventModel> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = '';
  String _searchQuery = '';

  List<EventModel> get events => _events;
  List<EventModel> get upcomingEvents => _upcomingEvents;
  List<EventModel> get myEvents => _myEvents;
  List<EventModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Lấy danh sách sự kiện
  Future<void> loadEvents({String? category, String? status}) async {
    // Sử dụng Future.microtask để tránh setState during build
    Future.microtask(() async {
      _setLoading(true);
      _clearError();

      try {
        _events = await _eventService.getEvents(
          category: category,
          status: status,
        );
        _selectedCategory = category ?? '';
        _setLoading(false);
        notifyListeners();
      } catch (e) {
        _setError(e.toString());
        _setLoading(false);
      }
    });
  }

  // Lấy tất cả sự kiện cho admin (bao gồm pending)
  Future<void> loadAllEventsForAdmin({String? category, String? status}) async {
    Future.microtask(() async {
      _setLoading(true);
      _clearError();

      try {
        _events = await _eventService.getAllEventsForAdmin(
          category: category,
          status: status,
        );
        _selectedCategory = category ?? '';
        _setLoading(false);
        notifyListeners();
      } catch (e) {
        _setError(e.toString());
        _setLoading(false);
      }
    });
  }

  // Lấy sự kiện sắp diễn ra
  Future<void> loadUpcomingEvents() async {
    _setLoading(true);
    _clearError();

    try {
      _upcomingEvents = await _eventService.getUpcomingEvents();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Lấy sự kiện của tôi (nếu là organizer)
  Future<void> loadMyEvents(String organizerId) async {
    _setLoading(true);
    _clearError();

    try {
      _myEvents = await _eventService.getEventsByOrganizer(organizerId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Tìm kiếm sự kiện
  Future<void> searchEvents(String query) async {
    _setLoading(true);
    _clearError();
    _searchQuery = query;

    try {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = await _eventService.searchEvents(query);
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Lấy sự kiện theo ID
  Future<EventModel?> getEventById(String eventId) async {
    _setLoading(true);
    _clearError();

    try {
      EventModel? event = await _eventService.getEventById(eventId);
      _setLoading(false);
      return event;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Tạo sự kiện mới
  Future<bool> createEvent(EventModel event) async {
    _setLoading(true);
    _clearError();

    try {
      String eventId = await _eventService.createEvent(event);
      if (eventId.isNotEmpty) {
        // Thêm vào danh sách sự kiện của tôi
        _myEvents.insert(0, event.copyWith(id: eventId));
        _setLoading(false);
        notifyListeners();
        return true;
      }
      _setError('Tạo sự kiện thất bại');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Cập nhật sự kiện
  Future<bool> updateEvent(EventModel event) async {
    _setLoading(true);
    _clearError();

    try {
      await _eventService.updateEvent(event);

      // Cập nhật trong danh sách sự kiện của tôi
      int index = _myEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _myEvents[index] = event;
      }

      // Cập nhật trong danh sách sự kiện chung
      int generalIndex = _events.indexWhere((e) => e.id == event.id);
      if (generalIndex != -1) {
        _events[generalIndex] = event;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Xóa sự kiện
  Future<bool> deleteEvent(String eventId) async {
    _setLoading(true);
    _clearError();

    try {
      await _eventService.deleteEvent(eventId);

      // Xóa khỏi danh sách sự kiện của tôi
      _myEvents.removeWhere((event) => event.id == eventId);

      // Xóa khỏi danh sách sự kiện chung
      _events.removeWhere((event) => event.id == eventId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Lọc sự kiện theo danh mục
  void filterByCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Lọc sự kiện theo danh mục (tên method mới)
  void filterEventsByCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Xóa bộ lọc
  void clearFilter() {
    _selectedCategory = '';
    notifyListeners();
  }

  // Xóa kết quả tìm kiếm
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  // Lấy sự kiện đã lọc
  List<EventModel> get filteredEvents {
    if (_searchQuery.isNotEmpty) {
      return _searchResults;
    }

    if (_selectedCategory.isEmpty) {
      return _events;
    }

    return _events
        .where((event) => event.category == _selectedCategory)
        .toList();
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
