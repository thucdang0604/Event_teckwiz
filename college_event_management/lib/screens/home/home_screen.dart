import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../models/registration_model.dart';
import '../../models/event_model.dart';
import '../../widgets/event_card.dart';
import '../../widgets/search_bar.dart' as custom;
import '../../widgets/category_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    // Không cần loadEvents nữa, sẽ sử dụng StreamBuilder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản Lý Sự Kiện'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.currentUser?.isAdmin == true) {
                return IconButton(
                  onPressed: () {
                    context.go('/admin-dashboard');
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                );
              }
              return IconButton(
                onPressed: () {
                  context.go('/profile');
                },
                icon: const Icon(Icons.person),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [_buildEventsTab(), _buildMyEventsTab()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Sự kiện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Sự kiện của tôi',
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Chỉ hiển thị nút tạo sự kiện cho organizer và admin
          if (authProvider.currentUser?.role == 'organizer' ||
              authProvider.currentUser?.role == 'admin') {
            return FloatingActionButton(
              onPressed: () {
                context.go('/create-event');
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: AppColors.white),
            );
          }
          return const SizedBox.shrink(); // Ẩn nút nếu không có quyền
        },
      ),
    );
  }

  Widget _buildEventsTab() {
    return Consumer2<AuthProvider, EventProvider>(
      builder: (context, authProvider, eventProvider, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${authProvider.currentUser?.fullName ?? 'Người dùng'}!',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'Hệ thống quản lý sự kiện',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Khám phá và tham gia các sự kiện thú vị',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Search Bar
                    custom.SearchBar(
                      onSearch: (value) {
                        eventProvider.searchEvents(value);
                      },
                      hintText: 'Tìm kiếm sự kiện...',
                    ),

                    const SizedBox(height: 24),

                    // Categories
                    CategoryFilter(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        eventProvider.filterEventsByCategory(category);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Events List
                    const Text(
                      'Sự kiện sắp diễn ra',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Events List - Sử dụng StreamBuilder
                    StreamBuilder<List<EventModel>>(
                      stream: authProvider.currentUser?.isAdmin == true
                          ? EventService().getAllEventsStream()
                          : authProvider.currentUser?.isOrganizer == true
                          ? EventService().getOrganizerEventsStream(
                              authProvider.currentUser!.id,
                            )
                          : EventService().getEventsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Lỗi tải sự kiện: ${snapshot.error}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        final events = snapshot.data ?? [];

                        if (events.isEmpty) {
                          return const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_note_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có sự kiện nào',
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
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: EventCard(
                                event: event,
                                onTap: () {
                                  context.go('/event-detail/${event.id}');
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyEventsTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sự kiện của tôi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Organizer: sự kiện của mình; Sinh viên: sự kiện đã đăng ký
                    StreamBuilder(
                      stream: authProvider.currentUser?.isOrganizer == true
                          ? EventService().getOrganizerEventsStream(
                              authProvider.currentUser!.id,
                            )
                          : RegistrationService().getUserRegistrationsStream(
                              authProvider.currentUser!.id,
                            ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Lỗi tải sự kiện: ${snapshot.error}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        if (authProvider.currentUser?.isOrganizer == true) {
                          final myEvents =
                              (snapshot.data as List<EventModel>?) ?? [];
                          if (myEvents.isEmpty) {
                            return _emptyMyEventsMessage();
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: myEvents.length,
                            itemBuilder: (context, index) {
                              final event = myEvents[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: EventCard(
                                  event: event,
                                  onTap: () {
                                    context.go('/event-detail/${event.id}');
                                  },
                                ),
                              );
                            },
                          );
                        } else {
                          final registrations =
                              (snapshot.data as List?)
                                  ?.cast<RegistrationModel>() ??
                              [];
                          if (registrations.isEmpty) {
                            return _emptyMyEventsMessage();
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: registrations.length,
                            itemBuilder: (context, index) {
                              final reg = registrations[index];
                              return FutureBuilder<EventModel?>(
                                future: EventService().getEventById(
                                  reg.eventId,
                                ),
                                builder: (context, snap) {
                                  if (!snap.hasData)
                                    return const SizedBox.shrink();
                                  final event = snap.data!;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: EventCard(
                                      event: event,
                                      onTap: () {
                                        context.go('/event-detail/${event.id}');
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyMyEventsMessage() {
    return const Center(
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có sự kiện nào',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
