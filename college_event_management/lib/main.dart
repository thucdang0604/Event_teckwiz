import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/events/create_event_screen.dart';
import 'screens/events/event_registrations_screen.dart';
import 'screens/qr/qr_scanner_screen.dart';
import 'screens/chat/event_chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/student/student_dashboard_screen.dart';
import 'constants/app_colors.dart';
import 'services/notification_service.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/user_detail_screen.dart';
import 'screens/admin/event_approval_screen.dart';
import 'screens/admin/location_management_screen.dart';
import 'screens/admin/location_detail_screen.dart';
import 'screens/admin/event_statistics_screen.dart';
import 'screens/admin/location_calendar_screen.dart';
import 'screens/admin/student_management_screen.dart';
import 'screens/coorganizer/coorganizer_invitations_screen.dart';
import 'screens/organizer/organizer_dashboard_screen.dart';
import 'screens/notifications/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('⚠️ Could not load .env file: ${e.toString()}');
    print('📝 Using console logging for email verification');
  }

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final notificationService = NotificationService();
  await notificationService.initialize();
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
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Quản Lý Sự Kiện',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: AppColors.background,
              textTheme: GoogleFonts.interTextTheme(),
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
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
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
        // This would need to be passed from the previous screen
        return const SizedBox(); // Placeholder
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
        final eventTitle = state.uri.queryParameters['title'] ?? 'Sự kiện';
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
      builder: (context, state) => const UserManagementScreen(),
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
      path: '/admin/students',
      builder: (context, state) => const StudentManagementScreen(),
    ),
    GoRoute(
      path: '/admin/statistics',
      builder: (context, state) => const EventStatisticsScreen(),
    ),
    GoRoute(
      path: '/admin/location-calendar',
      builder: (context, state) => const LocationCalendarScreen(),
    ),
    GoRoute(
      path: '/coorganizer-invitations',
      builder: (context, state) => const CoOrganizerInvitationsScreen(),
    ),
    GoRoute(
      path: '/organizer-dashboard',
      builder: (context, state) => const OrganizerDashboardScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);
