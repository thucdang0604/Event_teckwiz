class AdminStatisticsModel {
  final int totalEvents;
  final int activeUsers;
  final int approvedEvents;
  final int pendingEvents;
  final int rejectedEvents;
  final int totalRegistrations;
  final double averageEventsPerMonth;
  final String topCategory;
  final String mostActiveOrganizer;
  final List<String> recentActivities;

  AdminStatisticsModel({
    required this.totalEvents,
    required this.activeUsers,
    required this.approvedEvents,
    required this.pendingEvents,
    required this.rejectedEvents,
    required this.totalRegistrations,
    required this.averageEventsPerMonth,
    required this.topCategory,
    required this.mostActiveOrganizer,
    required this.recentActivities,
  });

  factory AdminStatisticsModel.empty() {
    return AdminStatisticsModel(
      totalEvents: 0,
      activeUsers: 0,
      approvedEvents: 0,
      pendingEvents: 0,
      rejectedEvents: 0,
      totalRegistrations: 0,
      averageEventsPerMonth: 0.0,
      topCategory: 'N/A',
      mostActiveOrganizer: 'N/A',
      recentActivities: [],
    );
  }

  AdminStatisticsModel copyWith({
    int? totalEvents,
    int? activeUsers,
    int? approvedEvents,
    int? pendingEvents,
    int? rejectedEvents,
    int? totalRegistrations,
    double? averageEventsPerMonth,
    String? topCategory,
    String? mostActiveOrganizer,
    List<String>? recentActivities,
  }) {
    return AdminStatisticsModel(
      totalEvents: totalEvents ?? this.totalEvents,
      activeUsers: activeUsers ?? this.activeUsers,
      approvedEvents: approvedEvents ?? this.approvedEvents,
      pendingEvents: pendingEvents ?? this.pendingEvents,
      rejectedEvents: rejectedEvents ?? this.rejectedEvents,
      totalRegistrations: totalRegistrations ?? this.totalRegistrations,
      averageEventsPerMonth:
          averageEventsPerMonth ?? this.averageEventsPerMonth,
      topCategory: topCategory ?? this.topCategory,
      mostActiveOrganizer: mostActiveOrganizer ?? this.mostActiveOrganizer,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }
}
