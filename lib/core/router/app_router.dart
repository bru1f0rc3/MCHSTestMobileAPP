import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mchs_mobile_app/features/auth/presentation/screens/register_screen.dart';
import 'package:mchs_mobile_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:mchs_mobile_app/features/auth/presentation/screens/guest_conversion_screen.dart';
import 'package:mchs_mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mchs_mobile_app/features/home/presentation/screens/home_screen.dart';
import 'package:mchs_mobile_app/features/lectures/presentation/screens/lecture_detail_screen.dart';
import 'package:mchs_mobile_app/features/lectures/presentation/screens/lectures_screen.dart';
import 'package:mchs_mobile_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:mchs_mobile_app/features/profile/presentation/screens/user_statistics_screen.dart';
import 'package:mchs_mobile_app/features/testing/presentation/screens/test_detail_screen.dart';
import 'package:mchs_mobile_app/features/testing/presentation/screens/test_result_screen.dart';
import 'package:mchs_mobile_app/features/testing/presentation/screens/test_taking_screen.dart';
import 'package:mchs_mobile_app/features/testing/presentation/screens/tests_screen.dart';
import 'package:mchs_mobile_app/features/testing/presentation/screens/test_history_screen.dart';
import 'package:mchs_mobile_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mchs_mobile_app/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:mchs_mobile_app/features/admin/presentation/screens/admin_tests_screen.dart';
import 'package:mchs_mobile_app/features/admin/presentation/screens/admin_lectures_screen.dart';
import 'package:mchs_mobile_app/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:mchs_mobile_app/features/admin/presentation/screens/create_test_screen.dart';
import 'package:mchs_mobile_app/features/admin/presentation/screens/create_lecture_screen.dart';
import 'package:mchs_mobile_app/features/admin/presentation/screens/import_test_screen.dart';
import 'package:mchs_mobile_app/features/shell/main_shell.dart';

/// Route names
class Routes {
  Routes._();
  
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String guestConversion = 'guest-conversion';
  
  static const String home = 'home';
  static const String lectures = 'lectures';
  static const String lectureDetail = 'lecture-detail';
  static const String tests = 'tests';
  static const String testDetail = 'test-detail';
  static const String testTaking = 'test-taking';
  static const String testResult = 'test-result';
  static const String testHistory = 'test-history';
  static const String lectureTests = 'lecture-tests';
  static const String profile = 'profile';
  static const String userStatistics = 'user-statistics';
  
  // Admin routes
  static const String adminDashboard = 'admin-dashboard';
  static const String adminUsers = 'admin-users';
  static const String adminTests = 'admin-tests';
  static const String adminLectures = 'admin-lectures';
  static const String adminReports = 'admin-reports';
  static const String createTest = 'create-test';
  static const String createLecture = 'create-lecture';
  static const String importTest = 'import-test';
}

/// Navigator key (must be static to avoid key conflicts)
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shell navigator key
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Cached GoRouter instance
GoRouter? _cachedRouter;

/// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  // Return cached router if exists to prevent recreation
  if (_cachedRouter != null) {
    return _cachedRouter!;
  }
  
  _cachedRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Read auth state directly from container
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authStateProvider);
      
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register' ||
                          state.matchedLocation == '/splash';
      
      if (state.matchedLocation == '/splash') {
        return null;
      }
      
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      
      if (isLoggedIn && isAuthRoute && state.matchedLocation != '/splash') {
        return '/home';
      }
      
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/login',
        name: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Guest conversion
      GoRoute(
        path: '/guest-conversion',
        name: Routes.guestConversion,
        builder: (context, state) => const GuestConversionScreen(),
      ),
      
      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Home
          GoRoute(
            path: '/home',
            name: Routes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          
          // Lectures
          GoRoute(
            path: '/lectures',
            name: Routes.lectures,
            builder: (context, state) => const LecturesScreen(),
          ),
          
          // Tests
          GoRoute(
            path: '/tests',
            name: Routes.tests,
            builder: (context, state) {
              final lectureIdStr = state.uri.queryParameters['lectureId'];
              final lectureId = lectureIdStr != null ? int.tryParse(lectureIdStr) : null;
              return TestsScreen(lectureId: lectureId);
            },
          ),
          
          // Profile
          GoRoute(
            path: '/profile',
            name: Routes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          
          // Admin routes
          GoRoute(
            path: '/admin-dashboard',
            name: Routes.adminDashboard,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
        ],
      ),
      
      // Lecture Detail (outside shell)
      GoRoute(
        path: '/lecture-detail/:id',
        name: Routes.lectureDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return LectureDetailScreen(lectureId: id);
        },
      ),

      // Test Detail (outside shell)
      GoRoute(
        path: '/test-detail/:id',
        name: Routes.testDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TestDetailScreen(testId: id);
        },
      ),

      // Lecture Tests (outside shell) - tests filtered by lecture
      GoRoute(
        path: '/lecture-tests/:lectureId',
        name: Routes.lectureTests,
        builder: (context, state) {
          final lectureId = int.parse(state.pathParameters['lectureId']!);
          return TestsScreen(lectureId: lectureId);
        },
      ),

      // Test History (outside shell)
      GoRoute(
        path: '/test-history',
        name: Routes.testHistory,
        builder: (context, state) => const TestHistoryScreen(),
      ),

      // User Statistics (outside shell)
      GoRoute(
        path: '/user-statistics',
        name: Routes.userStatistics,
        builder: (context, state) => const UserStatisticsScreen(),
      ),

      // Admin Users (outside shell)
      GoRoute(
        path: '/admin-users',
        name: Routes.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),

      // Admin Tests (outside shell)
      GoRoute(
        path: '/admin-tests',
        name: Routes.adminTests,
        builder: (context, state) => const AdminTestsScreen(),
      ),

      // Admin Lectures (outside shell)
      GoRoute(
        path: '/admin-lectures',
        name: Routes.adminLectures,
        builder: (context, state) => const AdminLecturesScreen(),
      ),

      // Admin Reports (outside shell)
      GoRoute(
        path: '/admin/reports',
        name: Routes.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),

      // Create Test (outside shell)
      GoRoute(
        path: '/admin/create-test',
        name: Routes.createTest,
        builder: (context, state) => const CreateTestScreen(),
      ),

      // Create Lecture (outside shell)
      GoRoute(
        path: '/admin/create-lecture',
        name: Routes.createLecture,
        builder: (context, state) => const CreateLectureScreen(),
      ),

      // Import Test from PDF (outside shell)
      GoRoute(
        path: '/admin/import-test',
        name: Routes.importTest,
        builder: (context, state) => const ImportTestFromPdfScreen(),
      ),
      
      // Test taking (full screen, no bottom nav)
      GoRoute(
        path: '/test-taking/:testId',
        name: Routes.testTaking,
        builder: (context, state) {
          final testId = int.parse(state.pathParameters['testId']!);
          return TestTakingScreen(testId: testId);
        },
      ),
      
      // Test result (full screen)
      GoRoute(
        path: '/test-result/:testResultId',
        name: Routes.testResult,
        builder: (context, state) {
          final testResultId = int.parse(state.pathParameters['testResultId']!);
          return TestResultScreen(testResultId: testResultId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Страница не найдена',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),
  );
  
  return _cachedRouter!;
});
