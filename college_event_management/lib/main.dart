import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/events/create_event_screen.dart';
import 'screens/events/event_registrations_screen.dart';
import 'screens/events/event_registration_screen.dart';
import 'screens/qr/qr_scanner_screen.dart';
import 'screens/chat/event_chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'constants/app_colors.dart';
import 'screens/student/student_dashboard_screen.dart';
import 'services/notification_service.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_locations_screen.dart';

import 'screens/admin/user_detail_screen.dart';
import 'screens/admin/event_approval_screen.dart';
import 'screens/admin/location_management_screen.dart';
import 'screens/admin/location_detail_screen.dart';
import 'screens/admin/event_statistics_screen.dart';
import 'screens/admin/admin_statistics_screen.dart';
import 'screens/admin/location_calendar_screen.dart';
import 'screens/admin/feedback_moderation_screen.dart';
import 'screens/organizer/organizer_dashboard_screen.dart';
import 'screens/notifications/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');
  } catch (e) {
    print('⚠️ Could not load .env file: $e');
  }

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    }
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    // App will continue but Firebase features won't work
  }

  // Initialize core services only
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<AuthProvider, NotificationProvider>(
        builder: (context, authProvider, notificationProvider, _) {
          // Defer setUser to next frame to avoid build-time notifyListeners
          final user = authProvider.currentUser;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notificationProvider.setUser(user?.id, user?.role);
          });
          return MaterialApp.router(
            title: 'Event Management',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: AppColors.background,
              // textTheme: GoogleFonts.interTextTheme(), // Disabled due to network issues
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              cardTheme: CardThemeData(
                color: AppColors.cardBackground,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const StudentDashboardScreen();
      },
    ),
    GoRoute(
      path: '/event-detail/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return EventDetailScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/create-event',
      builder: (context, state) => const CreateEventScreen(),
    ),
    GoRoute(
      path: '/event/:eventId/register',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return Consumer<EventProvider>(
          builder: (context, eventProvider, child) {
            final event = eventProvider.events.firstWhere(
              (e) => e.id == eventId,
              orElse: () => throw Exception('Event not found'),
            );
            return EventRegistrationScreen(event: event);
          },
        );
      },
    ),
    GoRoute(
      path: '/qr-scanner',
      builder: (context, state) => const QRScannerScreen(),
    ),
    GoRoute(
      path: '/event/:eventId/chat',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return EventChatScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/event/:eventId/registrations',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        final eventTitle = state.uri.queryParameters['title'] ?? 'Event';
        return EventRegistrationsScreen(
          eventId: eventId,
          eventTitle: eventTitle,
        );
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/student',
      builder: (context, state) => const StudentDashboardScreen(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: '/admin/locations',
      builder: (context, state) => const AdminLocationsScreen(),
    ),
    GoRoute(
      path: '/admin/users/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final user = adminProvider.users.firstWhere(
              (u) => u.id == userId,
              orElse: () => throw Exception('User not found'),
            );
            return UserDetailScreen(user: user);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/approvals',
      builder: (context, state) => const EventApprovalScreen(),
    ),
    GoRoute(
      path: '/admin/locations',
      builder: (context, state) => const LocationManagementScreen(),
    ),
    GoRoute(
      path: '/admin/location-detail/:locationId',
      builder: (context, state) {
        final locationId = state.pathParameters['locationId']!;
        return Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final location = adminProvider.locations.firstWhere(
              (l) => l.id == locationId,
              orElse: () => throw Exception('Location not found'),
            );
            return LocationDetailScreen(location: location);
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/statistics',
      builder: (context, state) => const AdminStatisticsScreen(),
    ),
    GoRoute(
      path: '/admin/event-statistics',
      builder: (context, state) => const EventStatisticsScreen(),
    ),
    GoRoute(
      path: '/admin/feedback',
      builder: (context, state) => const FeedbackModerationScreen(),
    ),
    GoRoute(
      path: '/admin/location-calendar',
      builder: (context, state) => const LocationCalendarScreen(),
    ),
    GoRoute(
      path: '/coorganizer-invitations',
      builder: (context, state) => const OrganizerDashboardScreen(),
    ),
    GoRoute(
      path: '/organizer-dashboard',
      builder: (context, state) => const OrganizerDashboardScreen(),
    ),
    GoRoute(
      path: '/organizer/events',
      builder: (context, state) =>
          const OrganizerDashboardScreen(), // Temporary - will create separate screen later
    ),
    GoRoute(
      path: '/organizer/coorganizers',
      builder: (context, state) =>
          const OrganizerDashboardScreen(), // Temporary - will create separate screen later
    ),
    GoRoute(
      path: '/organizer/analytics',
      builder: (context, state) =>
          const OrganizerDashboardScreen(), // Temporary - will create separate screen later
    ),
    GoRoute(
      path: '/organizer/profile',
      builder: (context, state) =>
          const OrganizerDashboardScreen(), // Temporary - will create separate screen later
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    // Admin notifications use the same NotificationsScreen; bottom bar appears for admin
    GoRoute(
      path: '/admin/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);
