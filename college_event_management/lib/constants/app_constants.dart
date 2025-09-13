class AppConstants {
  // App Info
  static const String appName = 'Quản Lý Sự Kiện';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String registrationsCollection = 'registrations';
  static const String supportRegistrationsCollection = 'support_registrations';
  static const String notificationsCollection = 'notifications';

  // User Roles
  static const String adminRole = 'admin';
  static const String organizerRole = 'organizer';
  static const String studentRole = 'student';

  // User Approval Status
  static const String userPending = 'pending';
  static const String userApproved = 'approved';
  static const String userRejected = 'rejected';

  // Event Status
  static const String eventDraft = 'draft';
  static const String eventPublished = 'published';
  static const String eventCancelled = 'cancelled';
  static const String eventCompleted = 'completed';

  // Registration Status
  static const String registrationPending = 'pending';
  static const String registrationApproved = 'approved';
  static const String registrationRejected = 'rejected';
  static const String registrationCancelled = 'cancelled';

  // Event Categories
  static const List<String> eventCategories = [
    'Học thuật',
    'Thể thao',
    'Văn hóa - Nghệ thuật',
    'Tình nguyện',
    'Kỹ năng mềm',
    'Hội thảo',
    'Triển lãm',
    'Khác',
  ];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 4.0;

  // Image Constants
  static const String defaultEventImage = 'assets/images/default_event.png';
  static const String defaultAvatarImage = 'assets/images/default_avatar.png';

  // Date Format
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
}
